# Da montagem à execução da mini-VM

Este guia segue o `Makefile` e os seis arquivos de `src/`. Considere `make run` executado dentro da pasta `assembly`, no Linux ou no container do projeto. A primeira sequência pressupõe que ainda não existem os arquivos gerados.

## 1. Visão geral

```text
Você executa make run
        ↓
make lê o Makefile e verifica as dependências
        ↓
cria build/ se necessário
        ↓
NASM transforma cada .asm em um módulo objeto .o
        ↓
ld conecta os módulos e gera o executável vm
        ↓
make executa ./vm
        ↓
Linux prepara a memória do processo e inicia em _start
        ↓
_start chama vm_run
        ↓
vm_run interpreta o bytecode, executando e imprimindo cada passo
        ↓
HALT → impressão final → syscall exit → processo termina
        ↓
o controle volta ao ambiente que executou o programa
```

Montagem e linkedição acontecem antes da execução da VM. Elas são feitas pelos programas `nasm` e `ld`, chamados por `make`; não são etapas realizadas pelo próprio `vm`.

## 2. Como make decide o que fazer

No `Makefile`, `run` depende de `vm`, e `vm` depende dos objetos:

```text
run precisa de vm
        ↓
vm precisa de todos os build/*.o
        ↓
cada build/nome.o precisa de src/nome.asm
        ↓
build/ precisa existir antes de gravar os objetos
```

O comando `$(wildcard src/*.asm)` descobre os fontes, e `patsubst` calcula seus nomes de saída. `make` resolve essas dependências antes de executar a receita de `run`.

Com os arquivos atuais, em uma montagem limpa e sem paralelismo (`make run`, sem `-j`), a sequência de comandos é:

```text
mkdir -p build
        ↓
nasm -f elf64 -g -F dwarf src/bytecode.asm -o build/bytecode.o
        ↓
nasm -f elf64 -g -F dwarf src/interpreter.asm -o build/interpreter.o
        ↓
nasm -f elf64 -g -F dwarf src/main.asm -o build/main.o
        ↓
nasm -f elf64 -g -F dwarf src/ops.asm -o build/ops.o
        ↓
nasm -f elf64 -g -F dwarf src/print.asm -o build/print.o
        ↓
nasm -f elf64 -g -F dwarf src/stack.asm -o build/stack.o
        ↓
ld build/bytecode.o build/interpreter.o build/main.o \
   build/ops.o build/print.o build/stack.o -o vm
        ↓
./vm
```

Essa ordem dos objetos acompanha a lista de fontes ordenada pelo `wildcard`. Os módulos podem ser montados independentemente: `main.asm` não precisa esperar que NASM monte `interpreter.asm` para declarar `extern vm_run`. Com `make -j`, as montagens podem ocorrer em paralelo; o linker ainda espera todos os objetos necessários.

## 3. O que NASM faz em cada módulo

```text
arquivo .asm
    ↓
processa diretivas e expande macros
    ↓
transforma instruções x86 em bytes de código de máquina
    ↓
registra dados, espaço reservado, símbolos e referências a resolver
    ↓
arquivo .o (objeto relocável ELF de 64 bits)
```

`-f elf64` escolhe o formato do objeto; `-g -F dwarf` acrescenta informações de depuração; `-o` indica o arquivo de saída.

| Fonte | O que oferece ao programa |
|---|---|
| `main.asm` | `_start`, a entrada do executável |
| `interpreter.asm` | `vm_run`, o interpretador |
| `stack.asm` | `vm_push`, `vm_pop`, `vm_stack` e `stack_top` |
| `ops.asm` | Remoção da base e operações aritméticas |
| `print.asm` | Impressão da pilha e conversão de números em texto |
| `bytecode.asm` | Bytes do programa da VM e a constante `bytecode_len` |

NASM não executa `vm_push` nem as operações nessa etapa. Em `bytecode.asm`, `db` gera dados; em `stack.asm`, `resq` descreve espaço a reservar. A macro `CHECK_MIN_TWO` é expandida em instruções dentro das rotinas de `ops.asm`.

## 4. O que o linker conecta

```text
main.o: referência externa a vm_run
        ↓ resolve usando
interpreter.o: definição exportada de vm_run
        ↓ contém referências a
stack.o / ops.o / print.o / bytecode.o
        ↓
ld organiza o conteúdo em um executável e ajusta as referências
        ↓
vm, com endereço de entrada correspondente a _start
```

Por exemplo, `extern vm_run` declara uma referência em `main.asm`, e `global vm_run` torna a definição em `interpreter.asm` disponível ao linker. `ld` resolve a referência do `call vm_run` para que a chamada alcance a rotina correta.

O linker também resolve referências aos dados `vm_stack`, `stack_top` e `bytecode`. `bytecode_len` é uma constante exportada, não uma variável na memória.

Os seis arquivos são conectados em um único executável. A ordem em que foram montados ou passados ao linker não é a ordem de execução das funções: quem determina essa ordem é a entrada `_start` e o fluxo de chamadas e saltos.

## 5. O que Linux prepara ao executar ./vm

```text
ambiente executa ./vm
        ↓
Linux lê o executável ELF e prepara o processo
        ↓
disponibiliza código e dados nos endereços virtuais do processo
        ↓
disponibiliza a memória da .bss inicialmente zerada
        ↓
prepara a pilha nativa e o estado inicial de execução
        ↓
CPU começa na entrada _start, em main.asm
```

Assim, antes de qualquer `vm_push`, `stack_top` já vale zero. A memória de `vm_stack`, `print_buf` e `tmp_digits` também começa zerada. O bytecode inicializado está disponível como dado do programa.

`global`, `extern`, `section`, `equ`, `db` e `resq` são diretivas de montagem. A CPU não passa por elas como se fossem instruções. Um rótulo também não executa uma ação: ele nomeia uma posição usada por referências e pelo fluxo de execução.

## 6. Entrada e preparação do interpretador

```text
main.asm: _start
    ↓ call vm_run
interpreter.asm: vm_run
    ↓ push r12 → push r13 (guarda valores antigos na pilha nativa)
    ↓ lea r12, [bytecode] (endereço do primeiro byte)
    ↓ lea r13, [bytecode]
    ↓ add r13, bytecode_len (limite exclusivo; tamanho atual = 20 bytes)
    ↓
.fetch
```

RIP acompanha as instruções x86 executadas pela CPU. R12 acompanha os bytes da VM. Enquanto a CPU executa instruções em `interpreter.asm`, R12 pode estar apontando para um dado definido em `bytecode.asm`.

## 7. O ciclo de cada instrução da VM

```text
.fetch
    ↓ compara R12 com R13
    ├─ chegou ao limite → .end_of_program → exit_now → exit(0)
    └─ ainda há byte
           ↓ lê opcode em RAX com movzx
           ↓ incrementa R12
           ↓ compara AL com os opcodes, na ordem: 1, 2, 3, 4, 5, 6, 255
           ├─ reconhecido → salta para .op_ correspondente
           └─ desconhecido → exit_now → exit(99)
```

Para PUSH:

```text
.op_push
    ↓ lê o operando com sinal para RAX (movsx)
    ↓ incrementa R12 mais uma vez
    ↓ call vm_push, em stack.asm
           ↓ lê stack_top e verifica capacidade
           ↓ escreve RAX em vm_stack[stack_top]
           ↓ incrementa stack_top
           ↓ ret (volta ao interpretador)
    ↓ jmp .after_instruction
    ↓ call vm_print_stack, em print.asm
    ↓ ret (volta ao interpretador)
    ↓ jmp .fetch
```

PUSH consome dois bytes; os outros opcodes consomem um. O código atual verifica o limite antes do opcode, mas não faz uma segunda verificação antes do operando de PUSH.

## 8. Aritmética, remoção e impressão

Para ADD, SUB e MUL, o percurso dentro de `ops.asm` é:

```text
rotina da operação
    ↓ verifica stack_top >= 2
    ├─ não → ret, sem alterar a VM
    └─ sim
         ↓ call vm_pop → RAX recebe b (topo)
         ↓ push rax → guarda b na pilha nativa
         ↓ call vm_pop → RAX recebe a (penúltimo)
         ↓ pop rbx → recupera b
         ↓ calcula a + b, a - b ou a * b em RAX
         ↓ call vm_push → devolve o resultado à VM
         ↓ ret → volta ao interpretador
    ↓ .after_instruction → impressão → .fetch
```

DIV segue a mesma retirada dos operandos. Depois testa b: se for zero, devolve a e b nessa ordem; caso contrário, executa `cqo → idiv rbx → vm_push` e retorna.

REMOVE usa outro percurso:

```text
vm_remove_first
    ↓ verifica se há pelo menos dois itens
    ├─ não → ret
    └─ sim → copia célula 1 para 0 → célula 2 para 1 → continua até o fim
                  ↓ reduz stack_top
                  ↓ ret → impressão → .fetch
```

A impressão chamada depois de cada operação segue:

```text
vm_print_stack
    ↓ preserva R12, R13 e R14 na pilha nativa
    ↓ percorre vm_stack da base ao topo
    ↓ para cada número: call int_to_str
         ↓ separa o sinal
         ↓ extrai dígitos por divisões por 10
         ↓ copia dígitos em ordem inversa para o buffer final
         ↓ ret, com comprimento em RAX
    ↓ coloca vírgula e espaço entre números
    ↓ acrescenta quebra de linha
    ↓ syscall write (RAX=1, RDI=1, RSI=buffer, RDX=tamanho)
    ↓ restaura R14, R13 e R12
    ↓ ret → volta ao interpretador
```

Preservar R12 e R13 permite continuar lendo o bytecode depois da impressão. Mesmo uma operação sem efeito imprime a pilha.

## 9. Ordem exata do bytecode atual

Cada linha da tabela corresponde a uma instrução da VM. A coluna final mostra a linha enviada à saída padrão, seguida de quebra de linha.

| Passo | Instrução | Caminho principal | Saída |
|---:|---|---|---|
| 1 | PUSH 10 | `.op_push → vm_push → impressão` | `10` |
| 2 | PUSH -25 | `.op_push → vm_push → impressão` | `10, -25` |
| 3 | PUSH 42 | `.op_push → vm_push → impressão` | `10, -25, 42` |
| 4 | ADD | `.op_add → vm_add → dois vm_pop → vm_push → impressão` | `10, 17` |
| 5 | REMOVE | `.op_remove → vm_remove_first → impressão` | `17` |
| 6 | ADD | Guarda de `vm_add → ret → impressão` (um item) | `17` |
| 7 | REMOVE | Guarda de `vm_remove_first → ret → impressão` (um item) | `17` |
| 8 | PUSH 10 | `.op_push → vm_push → impressão` | `17, 10` |
| 9 | SUB | `.op_sub → vm_sub → dois vm_pop → vm_push → impressão` | `7` |
| 10 | PUSH 2 | `.op_push → vm_push → impressão` | `7, 2` |
| 11 | MUL | `.op_mul → vm_mul → dois vm_pop → vm_push → impressão` | `14` |
| 12 | PUSH 2 | `.op_push → vm_push → impressão` | `14, 2` |
| 13 | DIV | `.op_div → vm_div → dois vm_pop → idiv → vm_push → impressão` | `7` |
| 14 | HALT | `.op_halt → impressão final → exit_now` | `7` |

## 10. Encerramento

```text
.fetch reconhece 0xFF
    ↓ .op_halt
    ↓ call vm_print_stack → imprime 7 novamente → ret
    ↓ xor rdi, rdi → status 0
    ↓ call exit_now
    ↓ mov rax, 60 → syscall exit
    ↓ Linux encerra o processo
```

Não há retorno de `vm_run` para `_start`: `exit` encerra o processo inteiro. Outros caminhos explícitos de encerramento são fim dos bytes (0), opcode inválido (99), overflow da pilha (1) e underflow da pilha (2).

## 11. O que muda na próxima execução

```text
make run, sem alterações e com os arquivos atualizados
    → make verifica dependências → ./vm

make run, depois de alterar src/ops.asm
    → NASM refaz build/ops.o → ld refaz vm → ./vm

make
    → monta o que estiver desatualizado → conecta se necessário → não executa vm

./vm
    → executa o binário existente → não chama NASM nem ld
```

Essas decisões usam existência e datas de modificação das dependências. Uma alteração apenas nos comentários também pode provocar nova montagem, porque modifica a data do fonte. Executar o binário existente não incorpora automaticamente alterações dos `.asm`.

No fluxo Docker documentado pelo projeto, `docker compose build` prepara a imagem com as ferramentas e `docker compose run --rm asm-vm` abre o shell do container. O comando padrão é Bash: dentro dele, `make run` inicia a sequência descrita neste guia.
