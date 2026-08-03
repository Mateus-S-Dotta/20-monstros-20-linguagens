; ==========================================
; ops.asm - Operações da mini-VM (REMOVE, ADD, SUB, MUL, DIV)
; ==========================================

global vm_remove_first
global vm_add
global vm_sub
global vm_mul
global vm_div

extern vm_push
extern vm_pop
extern vm_stack
extern stack_top

section .text

; ------------------------------------------
; macro de guarda: pula pro rótulo %1 se stack_top < 2
; ("nenhuma ação > 1 se só tiver 1 elemento")
; destrói: RAX
; ------------------------------------------
%macro CHECK_MIN_TWO 1
    mov rax, [stack_top]
    cmp rax, 2
    jl %1
%endmacro

; ------------------------------------------
; vm_remove_first: remove o elemento do INÍCIO da pilha (índice 0)
; desloca todos os demais uma posição para baixo
; se stack_top < 2, não faz nada (no-op)
; destrói: RAX, RBX, RCX, RDX
; ------------------------------------------
vm_remove_first:
    CHECK_MIN_TWO .skip

    mov rbx, [stack_top]      ; rbx = quantidade atual de elementos
    xor rcx, rcx              ; rcx = índice de destino (escrita)

.shift_loop:
    mov rdx, rcx
    inc rdx                   ; rdx = índice de origem (leitura), sempre 1 à frente
    cmp rdx, rbx
    jge .shift_done

    mov rax, [vm_stack + rdx*8]
    mov [vm_stack + rcx*8], rax

    inc rcx
    jmp .shift_loop

.shift_done:
    dec rbx
    mov [stack_top], rbx

.skip:
    ret

; ------------------------------------------
; vm_add: pop b, pop a, push (a + b)
; se stack_top < 2, não faz nada (no-op)
; ------------------------------------------
vm_add:
    CHECK_MIN_TWO .skip
    call vm_pop
    push rax         ; guarda b na pilha NATIVA do x86 (não na vm_stack!)
    call vm_pop      ; rax = a
    pop rbx          ; recupera b
    add rax, rbx     ; rax = a + b
    call vm_push
.skip:
    ret

; ------------------------------------------
; vm_sub: pop b, pop a, push (a - b)
; se stack_top < 2, não faz nada (no-op)
; ------------------------------------------
vm_sub:
    CHECK_MIN_TWO .skip
    call vm_pop
    push rax
    call vm_pop      ; rax = a
    pop rbx          ; b
    sub rax, rbx     ; rax = a - b
    call vm_push
.skip:
    ret

; ------------------------------------------
; vm_mul: pop b, pop a, push (a * b)
; se stack_top < 2, não faz nada (no-op)
; ------------------------------------------
vm_mul:
    CHECK_MIN_TWO .skip
    call vm_pop
    push rax
    call vm_pop      ; rax = a
    pop rbx          ; b
    imul rax, rbx    ; rax = a * b (multiplicação com sinal)
    call vm_push
.skip:
    ret

; ------------------------------------------
; vm_div: pop b, pop a, push (a / b)
; se stack_top < 2, não faz nada (no-op)
; se b == 0, restaura a e b na pilha sem dividir (evita crash)
; ------------------------------------------
vm_div:
    CHECK_MIN_TWO .skip
    call vm_pop
    push rax          ; guarda b
    call vm_pop       ; rax = a
    pop rbx           ; rbx = b

    test rbx, rbx
    jz .div_zero

    cqo               ; sign-extend rax -> rdx:rax (necessário pro idiv)
    idiv rbx          ; rax = a / b (divisão com sinal)
    call vm_push
    jmp .skip

.div_zero:
    ; divisão por zero: desfaz o pop, devolve a e b como estavam
    push rbx          ; guarda b na pilha nativa (rax ainda é 'a')
    call vm_push      ; devolve 'a'
    pop rax           ; recupera b
    call vm_push      ; devolve 'b'

.skip:
    ret