; ==========================================
; stack.asm - Pilha da mini-VM (push/pop)
; ==========================================

global vm_push
global vm_pop
global vm_stack
global stack_top

section .bss
    STACK_CAPACITY equ 4096          ; número de células (valores de 64 bits)
    vm_stack:    resq STACK_CAPACITY ; a pilha em si: 4096 * 8 bytes
    stack_top:   resq 1              ; índice do topo (quantos elementos tem na pilha)

section .text

; ------------------------------------------
; vm_push: empilha um valor de 64 bits
; entrada: RAX = valor a empilhar
; destrói: RBX, RCX
; ------------------------------------------
vm_push:
    mov rbx, [stack_top]
    cmp rbx, STACK_CAPACITY
    jge stack_overflow

    mov rcx, rbx
    shl rcx, 3
    mov [vm_stack + rcx], rax

    inc rbx
    mov [stack_top], rbx
    ret

; ------------------------------------------
; vm_pop: desempilha um valor de 64 bits
; saída: RAX = valor desempilhado
; destrói: RBX, RCX
; ------------------------------------------
vm_pop:
    mov rbx, [stack_top]
    cmp rbx, 0
    jle stack_underflow

    dec rbx
    mov rcx, rbx
    shl rcx, 3
    mov rax, [vm_stack + rcx]
    mov [stack_top], rbx
    ret

; ------------------------------------------
; tratamento de erro
; ------------------------------------------
stack_overflow:
    mov rdi, 1
    call exit_with_code
    ret

stack_underflow:
    mov rdi, 2
    call exit_with_code
    ret

exit_with_code:
    mov rax, 60
    mov rsi, rdi
    mov rdi, rsi
    syscall