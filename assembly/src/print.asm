; ==========================================
; print.asm - Impressão da pilha da mini-VM
; ==========================================

global vm_print_stack

extern vm_stack
extern stack_top

section .bss
    STACK_CAPACITY equ 4096          ; precisa bater com o valor real de stack.asm
    print_buf:   resb 8192
    tmp_digits:  resb 32

section .text ; vale lembrar, o ponteiro do .text é RIP

; ------------------------------------------
; vm_print_stack: imprime a pilha no formato "n, n, n\n"
; ------------------------------------------
vm_print_stack:
    push r12
    push r13
    push r14

    mov r12, [stack_top]
    xor r13, r13
    lea r14, [print_buf]

    cmp r12, 0
    je .empty

.print_loop:
    cmp r13, r12
    jge .done_loop

    mov rcx, r13
    shl rcx, 3
    mov rax, [vm_stack + rcx]

    mov rdi, r14
    call int_to_str
    add r14, rax

    inc r13
    cmp r13, r12
    jge .done_loop

    mov byte [r14], ','
    inc r14
    mov byte [r14], ' '
    inc r14

    jmp .print_loop

.done_loop:
    mov byte [r14], 10
    inc r14
    jmp .write_out

.empty:
    mov byte [r14], 10
    inc r14

.write_out:
    lea rsi, [print_buf]
    mov rdx, r14
    sub rdx, rsi
    mov rax, 1
    mov rdi, 1
    syscall

    pop r14
    pop r13
    pop r12
    ret

; ------------------------------------------
; int_to_str: converte um inteiro com sinal (64 bits) para string decimal
; entrada: RAX = valor, RDI = ponteiro do buffer de destino
; saída:   RAX = quantidade de bytes escritos
; ------------------------------------------
int_to_str:
    push rbx
    push rdi

    xor r8, r8
    xor r9, r9

    test rax, rax
    jns .positive
    mov r8, 1
    neg rax

.positive:
    mov rbx, 10

    test rax, rax
    jnz .convert_loop
    mov byte [tmp_digits], '0'
    mov r9, 1
    jmp .build_string

.convert_loop:
    test rax, rax
    jz .build_string
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [tmp_digits + r9], dl
    inc r9
    jmp .convert_loop

.build_string:
    pop rdi
    xor rcx, rcx

    test r8, r8
    jz .skip_sign
    mov byte [rdi], '-'
    inc rdi
    inc rcx

.skip_sign:
    dec r9
.copy_loop:
    cmp r9, -1
    je .copy_done
    mov dl, [tmp_digits + r9]
    mov [rdi], dl
    inc rdi
    inc rcx
    dec r9
    jmp .copy_loop

.copy_done:
    mov rax, rcx
    pop rbx
    ret