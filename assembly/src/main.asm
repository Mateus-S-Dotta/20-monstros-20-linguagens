extern vm_push, vm_pop, vm_print_stack

section .text
global _start
_start:
    mov rax, 10
    call vm_push

    mov rax, -25
    call vm_push

    mov rax, 42
    call vm_push

    mov rax, 420
    call vm_push


    call vm_print_stack   ; deve imprimir: 10, -25, 42

    mov rax, 60
    xor rdi, rdi
    syscall