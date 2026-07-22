; print5.asm — imprime "5" na tela usando syscalls diretas
section .data
    msg db "576", 10      ; "5" seguido de quebra de linha (10 = \n)
    len equ $ - msg      ; calcula o tamanho da string automaticamente

section .text
    global _start

_start:
    ; syscall write(fd, buf, count)
    mov rax, 1          ; número da syscall "write"
    mov rdi, 1          ; fd = 1 (stdout)
    mov rsi, msg        ; endereço do buffer
    mov rdx, len        ; tamanho em bytes
    syscall

    ; syscall exit(code)
    mov rax, 60         ; número da syscall "exit"
    mov rdi, 0          ; código de saída = 0
    syscall