; ==========================================
; interpreter.asm - Loop principal da mini-VM (fetch-decode-execute)
; ==========================================

; GUIA DE ESTUDO: buscar, decodificar e executar
; global exporta vm_run; extern declara rotinas/dados definidos em outros módulos.
; O linker conecta esses símbolos depois que NASM monta cada arquivo.
; RIP indica a próxima instrução x86 da CPU. R12 é um ponteiro de software
; para o próximo byte da VM: contém um ENDEREÇO, não apenas um offset.
; R13 guarda o limite exclusivo, a posição imediatamente após o último byte.
; As rotinas chamadas preservam R12/R13 para manter o percurso do bytecode.
;
; lea calcula um endereço sem ler seu conteúdo; mov com [endereço] lê memória.
; movzx estende com zeros; movsx replica o bit de sinal para os bits superiores.
; AL é a parte de 8 bits de RAX, suficiente para comparar um opcode.
; cmp altera flags; je consulta igualdade (ZF=1); jmp salta sem salvar retorno.
; call salva o retorno na pilha nativa. Rótulos com ponto são locais ao último
; rótulo não local do NASM, por isso .op_push pertence ao contexto de vm_run.
;
; HALT e fim dos bytes usam status 0; opcode desconhecido usa status 99.
; A guarda de limite protege a busca do opcode, mas não a leitura do operando:
; um bytecode truncado terminando em 0x01 pode ler além do final no PUSH.
; Os pushes iniciais não são desfeitos, pois esta rotina encerra e não retorna.
global vm_run ; exporta vm_run para os outros módulos e para o linker

extern vm_push ; declara vm_push, definido em outro módulo e resolvido pelo linker
extern vm_remove_first ; declara vm_remove_first, definido em outro módulo e resolvido pelo linker
extern vm_add ; declara vm_add, definido em outro módulo e resolvido pelo linker
extern vm_sub ; declara vm_sub, definido em outro módulo e resolvido pelo linker
extern vm_mul ; declara vm_mul, definido em outro módulo e resolvido pelo linker
extern vm_div ; declara vm_div, definido em outro módulo e resolvido pelo linker
extern vm_print_stack ; declara vm_print_stack, definido em outro módulo e resolvido pelo linker

extern bytecode ; declara bytecode, definido em outro módulo e resolvido pelo linker
extern bytecode_len ; declara bytecode_len, definido em outro módulo e resolvido pelo linker

section .text ; vale lembrar, o ponteiro do .text é RIP

; ------------------------------------------
; vm_run: executa o bytecode do início ao fim
; sem parâmetros / não retorna (dá exit no HALT)
; ------------------------------------------
vm_run: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    push r12          ; salva o valor antigo; R12 será o endereço do próximo byte
    push r13          ; salva o valor antigo de R13; o limite será calculado abaixo

    ; o push copia o valor que estava no REGISTRADOR para a stack
    ; (antes do push, esse valor só existia no registrador r12/r13)
    ; como minha função sobescreve o r12 e r13,
    ; eu vou salvar esses valores antes de seguir
    ; e no final posso resgatar com pop

    lea r12, [bytecode]     ; ponteiro de bytecode em r12, inicio da pilha
    lea r13, [bytecode]     ; ponteiro de bytecode em r13, inicio da pilha
    add r13, bytecode_len   ; chega ao fim exclusivo = início + tamanho constante

    ; pop r13 (como é uma stack, é em ordem invertida last in, first out)
    ; pop r12 o valor que eu salvei na linha 'push r12' volta para r12
    ; assim, a minha função chamada tem a segurança que os valores se mantem,
    ; e que nenhum outro trecho de código sobescreveu o valor

    ; poderia ter um ret, para voltar o RIP para a função anterior
    ; ret

    ; o pop e o ret (e o proprio push) podem ser ignorados aqui
    ; pois essa função tem um exit

.fetch: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    cmp r12, r13 ; compara o endereço do próximo opcode com o limite exclusivo do bytecode
    jge .end_of_program     ; segurança: chegou ao fim sem HALT explícito

    movzx rax, byte [r12]   ; lê opcode sem sinal: 0xFF vira 255, não -1
    inc r12                 ; avança IP (passou do opcode)

    ; usa a parte inferior de rax para pegar o valor
    ; poderia ser usado RAX diretamente, mas por padrão, mas é melhor pegar o tamanho ideal
    cmp al, 0x01 ; compara o opcode em AL com 0x01 (PUSH), atualizando as flags
    je .op_push ; se a comparação indicou igualdade (ZF=1), segue para a operação PUSH
    cmp al, 0x02 ; compara o opcode em AL com 0x02 (REMOVE), atualizando as flags
    je .op_remove ; se a comparação indicou igualdade (ZF=1), segue para a operação REMOVE
    cmp al, 0x03 ; compara o opcode em AL com 0x03 (ADD), atualizando as flags
    je .op_add ; se a comparação indicou igualdade (ZF=1), segue para a operação ADD
    cmp al, 0x04 ; compara o opcode em AL com 0x04 (SUB), atualizando as flags
    je .op_sub ; se a comparação indicou igualdade (ZF=1), segue para a operação SUB
    cmp al, 0x05 ; compara o opcode em AL com 0x05 (MUL), atualizando as flags
    je .op_mul ; se a comparação indicou igualdade (ZF=1), segue para a operação MUL
    cmp al, 0x06 ; compara o opcode em AL com 0x06 (DIV), atualizando as flags
    je .op_div ; se a comparação indicou igualdade (ZF=1), segue para a operação DIV
    cmp al, 0xFF ; compara o opcode em AL com 0xFF (HALT), atualizando as flags
    je .op_halt ; se a comparação indicou igualdade (ZF=1), segue para a operação HALT

    ; opcode desconhecido -> encerra com erro
    mov rdi, 99 ; seleciona status 99 para indicar opcode desconhecido
    call exit_now ; encerra o processo usando o status em RDI; não retorna

.op_push: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    movsx rax, byte [r12]   ; operando COM SINAL: 0xE7 vira -25 em RAX
    inc r12                 ; avança IP (passou o operando)
    call vm_push ; empilha o valor de RAX na VM; também modifica RBX e RCX
    jmp .after_instruction ; segue para a impressão comum após a operação

.op_remove: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_remove_first ; remove a base da pilha se houver pelo menos dois itens
    jmp .after_instruction ; segue para a impressão comum após a operação

.op_add: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_add ; substitui os dois itens do topo pela soma
    jmp .after_instruction ; segue para a impressão comum após a operação

.op_sub: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_sub ; substitui os dois itens por penúltimo menos último
    jmp .after_instruction ; segue para a impressão comum após a operação

.op_mul: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_mul ; substitui os dois itens pelo produto
    jmp .after_instruction ; segue para a impressão comum após a operação

.op_div: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_div ; divide penúltimo por último; divisor zero mantém a pilha
    jmp .after_instruction ; segue para a impressão comum após a operação

.after_instruction: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_print_stack     ; imprime a pilha após CADA instrução executada
    jmp .fetch ; volta à busca do próximo opcode no endereço atualizado de R12

.op_halt: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    call vm_print_stack     ; imprime o estado final também
    xor rdi, rdi ; zera RDI com XOR consigo mesmo; status de saída 0 (sucesso)
    call exit_now ; encerra o processo usando o status em RDI; não retorna

.end_of_program: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    xor rdi, rdi ; zera RDI com XOR consigo mesmo; status de saída 0 (sucesso)
    call exit_now ; encerra o processo usando o status em RDI; não retorna

exit_now: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rax, 60            ; número da syscall exit no Linux x86-64
    mov rsi, rdi           ; cópia do status; exit não exige esta passagem por RSI
    mov rdi, rsi           ; recoloca o mesmo status no primeiro argumento
    syscall                ; encerra o processo; não retorna nem precisa de ret
