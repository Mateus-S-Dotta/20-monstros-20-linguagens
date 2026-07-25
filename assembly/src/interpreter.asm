; ==========================================
; interpreter.asm - Loop principal da mini-VM (fetch-decode-execute)
; ==========================================

global vm_run

extern vm_push
extern vm_remove_first
extern vm_add
extern vm_sub
extern vm_mul
extern vm_div
extern vm_print_stack

extern bytecode
extern bytecode_len

section .text

; ------------------------------------------
; vm_run: executa o bytecode do início ao fim
; sem parâmetros / não retorna (dá exit no HALT)
; ------------------------------------------
vm_run:
    push r12          ; r12 = instruction pointer (IP), offset dentro de bytecode
    push r13          ; r13 = endereço final do bytecode (limite)

    lea r12, [bytecode]
    lea r13, [bytecode]
    add r13, bytecode_len

.fetch:
    cmp r12, r13
    jge .end_of_program     ; segurança: chegou ao fim sem HALT explícito

    movzx rax, byte [r12]   ; lê o opcode atual
    inc r12                 ; avança IP (passou do opcode)

    cmp al, 0x01
    je .op_push
    cmp al, 0x02
    je .op_remove
    cmp al, 0x03
    je .op_add
    cmp al, 0x04
    je .op_sub
    cmp al, 0x05
    je .op_mul
    cmp al, 0x06
    je .op_div
    cmp al, 0xFF
    je .op_halt

    ; opcode desconhecido -> encerra com erro
    mov rdi, 99
    call exit_now

.op_push:
    movsx rax, byte [r12]   ; lê o operando de 1 byte, COM SINAL
    inc r12                 ; avança IP (passou o operando)
    call vm_push
    jmp .after_instruction

.op_remove:
    call vm_remove_first
    jmp .after_instruction

.op_add:
    call vm_add
    jmp .after_instruction

.op_sub:
    call vm_sub
    jmp .after_instruction

.op_mul:
    call vm_mul
    jmp .after_instruction

.op_div:
    call vm_div
    jmp .after_instruction

.after_instruction:
    call vm_print_stack     ; imprime a pilha após CADA instrução executada
    jmp .fetch

.op_halt:
    call vm_print_stack     ; imprime o estado final também
    xor rdi, rdi
    call exit_now

.end_of_program:
    xor rdi, rdi
    call exit_now

exit_now:
    mov rax, 60
    mov rsi, rdi
    mov rdi, rsi
    syscall