; ==========================================
; bytecode.asm - Programa da mini-VM
; ==========================================

global bytecode
global bytecode_len

section .data

bytecode:
    db 0x01, 10     ; PUSH 10
    db 0x01, -25    ; PUSH -25
    db 0x01, 42     ; PUSH 42

    db 0x03         ; ADD      -> pop 42, pop -25, push 17

    db 0x02         ; REMOVE   -> remove o 10 (início)

    db 0x03         ; ADD      -> só 1 elemento, no-op

    db 0x02         ; REMOVE   -> só 1 elemento, no-op

    db 0xFF         ; HALT

bytecode_len equ $ - bytecode