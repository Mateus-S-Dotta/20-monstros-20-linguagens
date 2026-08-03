; ==========================================
; stack.asm - Pilha da mini-VM (push/pop)
; ==========================================

global vm_push
global vm_pop
global vm_stack
global stack_top

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
section .text

; ------------------------------------------
; vm_push: empilha um valor de 64 bits
; entrada: RAX = valor a empilhar
; destrói: RBX, RCX
; ------------------------------------------
vm_push:
    mov rbx, [stack_top]        ; coloca o valor de [stack_top] em rbx
    cmp rbx, STACK_CAPACITY     ; compara rbx com STACK_CAPACITY, e salva o resultado num registrador reservado (RFLAGS)
    jge stack_overflow          ; valida o resultado em RFLAGS, se for greater than or equal (expecifico jge), executa a função

    mov rcx, rbx                ; coloca o valor de rbx em rcx (indiretamente, o valor de [stack_top])
    shl rcx, 3                  ; shl move todos os bits para esquerda, no valor de 3 (nesse caso)
    ; mover 3 bits para a esquerda é o mesmo que multiplicar por 8 (que é o tamanho de cada elemento da pilha)
    ; ou seja, eu tenho o inicio do próximo elemento: se stack_top é 1, 1 * 8 é 8, que é exatamente onde começa o meu elemento [1]
    mov [vm_stack + rcx], rax   ; nesse 'próximo elemento', eu guardo rax, que é o registrador que eu escolhi para passar o valor

    inc rbx                     ; incrementa RBX (que é uma CÓPIA do índice) — [stack_top] na memória ainda não mudou
    mov [stack_top], rbx        ; vou salvar [stack-top]
    ret                         ; vou retornar
    ; Comentário importante: aqui, eu corrompi RBX e RCX (como no comentário do topo)
    ; Para salvar esses valores, eu teria que ter dado PUSH / POP

; ------------------------------------------
; vm_pop: desempilha um valor de 64 bits
; saída: RAX = valor desempilhado
; destrói: RBX, RCX
; ------------------------------------------
vm_pop:
    mov rbx, [stack_top]        ; coloca o valor de [stack_top] em rbx
    cmp rbx, 0                  ; compara rbx com 0, e salva o resultado num registrador reservado (RFLAGS)
    jle stack_underflow         ; valida o resultado em RFLAGS, se for foi menor ou igual? (expecifico jle), executa a função

    dec rbx                     ; tira um valor de rbx (indiretamente [stack_top])
    mov rcx, rbx                ; coloco o valor de rbx em rcx
    shl rcx, 3                  ; faço rcx * 8, para chegar exatamente no valor do elemento do topo
    mov rax, [vm_stack + rcx]   ; coloco esse valor do topo em rax, para retornar
    mov [stack_top], rbx        ; salva o novo valor de [stack_top]. só isso já é suficiente para retirar o elemento do topo da lista
    ; Basta dizer que a lista tem 1 elemento a menos, no próximo push vou sobrescrever o valor
    ret                         ; volto o ponteiro do .text
    ; Aqui, o mesmo vale de PUSH / POP

; ------------------------------------------
; tratamento de erro
; ------------------------------------------
stack_overflow:
    mov rdi, 1          ; coloca o valor de saída do exit
    call exit_with_code ; chama a função que dá o exit

stack_underflow:
    mov rdi, 2          ; coloca o valor de saída do exit
    call exit_with_code ; chama a função que dá o exit

exit_with_code:
    mov rax, 60         ; faz a syscall saber qual o comando a executar
    syscall             ; chama a syscall (rax 60 = exit, rdi = valor da saida)