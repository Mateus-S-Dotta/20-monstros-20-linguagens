; ==========================================
; stack.asm - Pilha da mini-VM (push/pop)
; ==========================================

; GUIA DE ESTUDO: contrato e endereçamento da pilha
; global exporta símbolos para o linker conectá-los aos outros arquivos.
; stack_top é a QUANTIDADE de itens válidos, não o endereço da última célula.
; Se vale 2, os índices válidos são 0 e 1; o próximo push escreve no índice 2.
; vm_stack ocupa 32768 bytes; stack_top ocupa mais 8 bytes na .bss.
; equ define uma constante sem reservar memória; resq reserva células de 8 bytes.
; Essas diretivas são processadas pelo NASM, não executadas como malloc pela CPU.
;
; vm_stack sem colchetes representa seu endereço. [vm_stack + deslocamento]
; acessa o conteúdo nesse endereço. O deslocamento é em bytes, não em itens.
; RAX tem 64 bits, portanto mov com RAX lê/escreve uma célula de 8 bytes.
; shl por 3 multiplica o índice por 8 e também altera flags, não usadas depois.
; cmp atualiza flags sem guardar uma subtração; jge/jle comparam COM sinal.
; A contagem normal, de 0 a 4096, cabe nessa interpretação.
;
; A pilha vm_stack é independente da pilha nativa apontada por RSP.
; call/ret e push/pop x86 usam a pilha nativa; vm_push/vm_pop usam este array.
; vm_push recebe RAX e o mantém; vm_pop devolve o valor em RAX.
; Ambos alteram RBX, RCX e flags: quem chama deve preservar seus temporários.
; Este acordo interno não preserva RBX como exigiria a ABI System V de funções C.
; RIP acompanha as instruções da CPU, não é um ponteiro exclusivo da .text.
; Nos erros, RDI recebe o status; RAX=60 seleciona exit no Linux x86-64.
; syscall entrega o controle ao kernel; exit encerra o processo e não retorna.
; O salto para um erro não cria retorno, mas isso não importa porque ele encerra.
global vm_push ; exporta vm_push para os outros módulos e para o linker
global vm_pop ; exporta vm_pop para os outros módulos e para o linker
global vm_stack ; exporta vm_stack para os outros módulos e para o linker
global stack_top ; exporta stack_top para os outros módulos e para o linker

section .bss ; tudo em .bss começa zerado, o SO garante isso para a gente
    ; detalhe muito legal: aqui, usamos vm_stack como um array, então qual a diferença para stack_top?
    ; nenhuma, a unica diferença é tamanho. não existe tipos 'array e variavel', tudo é bits um do lado do outro

    STACK_CAPACITY equ 4096          ; número de células (valores de 64 bits)
    vm_stack:    resq STACK_CAPACITY ; a pilha em si: 4096 * 8 bytes
    stack_top:   resq 1              ; índice do topo (quantos elementos tem na pilha)
    ; resq N sempre significa "reserve N slots de 8 bytes"

    ; resq é como se fosse uma 'reserva da bss', quase o que o malloc é para a heap
    ; vai reservar a qunatidade * 8
    ; lembrando: o bss é preparada antes de executar o arquivo. não acontece em tempo de execução como na heap
section .text ; vale lembrar, o ponteiro do .text é RIP

; ------------------------------------------
; vm_push: empilha um valor de 64 bits
; entrada: RAX = valor a empilhar
; destrói: RBX, RCX
; ------------------------------------------
vm_push: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rbx, [stack_top]        ; coloca o valor de [stack_top] em rbx
    cmp rbx, STACK_CAPACITY     ; compara rbx com STACK_CAPACITY, e salva o resultado num registrador reservado (RFLAGS)
    jge stack_overflow          ; valida o resultado em RFLAGS, se for greater than or equal (expecifico jge), executa a função

    mov rcx, rbx                ; coloca o valor de rbx em rcx (indiretamente, o valor de [stack_top])
    shl rcx, 3                  ; shl move todos os bits para esquerda, no valor de 3 (nesse caso)
    ; mover 3 bits para a esquerda é o mesmo que multiplicar por 8 (que é o tamanho de cada elemento da pilha)
    ; ou seja, eu tenho o inicio do próximo elemento: se stack_top é 1, 1 * 8 é 8, que é exatamente onde começa o meu elemento [1]
    mov [vm_stack + rcx], rax   ; nesse 'próximo elemento', eu guardo rax, que é o registrador que eu escolhi para passar o valor

    inc rbx                     ; incrementa RBX (que é uma CÓPIA do índice) — [stack_top] na memória ainda não mudou
    mov [stack_top], rbx        ; atualiza na memória a quantidade de elementos válidos
    ret                         ; recupera o endereço salvo por call e volta ao chamador
    ; Comentário importante: aqui, eu corrompi RBX e RCX (como no comentário do topo)
    ; Para salvar esses valores, eu teria que ter dado PUSH / POP

; ------------------------------------------
; vm_pop: desempilha um valor de 64 bits
; saída: RAX = valor desempilhado
; destrói: RBX, RCX
; ------------------------------------------
vm_pop: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rbx, [stack_top]        ; coloca o valor de [stack_top] em rbx
    cmp rbx, 0                  ; compara rbx com 0, e salva o resultado num registrador reservado (RFLAGS)
    jle stack_underflow         ; valida o resultado em RFLAGS, se for foi menor ou igual? (expecifico jle), executa a função

    dec rbx                     ; reduz a cópia da contagem; agora é o índice do último item
    mov rcx, rbx                ; coloco o valor de rbx em rcx
    shl rcx, 3                  ; faço rcx * 8, para chegar exatamente no valor do elemento do topo
    mov rax, [vm_stack + rcx]   ; coloco esse valor do topo em rax, para retornar
    mov [stack_top], rbx        ; salva o novo valor de [stack_top]. só isso já é suficiente para retirar o elemento do topo da lista
    ; Basta dizer que a lista tem 1 elemento a menos, no próximo push vou sobrescrever o valor
    ret                         ; recupera o endereço salvo por call e volta ao chamador
    ; Aqui, o mesmo vale de PUSH / POP

; ------------------------------------------
; tratamento de erro
; ------------------------------------------
stack_overflow: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rdi, 1          ; coloca o valor de saída do exit
    call exit_with_code ; chama a função que dá o exit

stack_underflow: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rdi, 2          ; coloca o valor de saída do exit
    call exit_with_code ; chama a função que dá o exit

exit_with_code: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rax, 60         ; faz a syscall saber qual o comando a executar
    syscall             ; chama a syscall (rax 60 = exit, rdi = valor da saida)
