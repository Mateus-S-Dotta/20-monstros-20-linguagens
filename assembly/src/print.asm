; ==========================================
; print.asm - Impressão da pilha da mini-VM
; ==========================================

; GUIA DE ESTUDO: do inteiro na memória ao texto no terminal
; O inteiro 42 não é a string "42": precisamos gerar ASCII '4' e '2' (52 e 50).
; Esta rotina percorre da base ao topo, monta "n, n, n" e acrescenta LF,
; byte 10 (quebra de linha). Pilha vazia produz apenas a quebra de linha.
; write usa endereço e comprimento; não exige terminador zero como strings C.
; global exporta a rotina; extern conecta aos dados definidos em stack.asm.
;
; R12 = quantidade; R13 = índice; R14 = próximo endereço livre do buffer.
; Preservamos esses registradores na pilha nativa em ordem inversa na saída.
; R12/R13 são essenciais ao chamador: o interpretador guarda neles seu percurso.
; int_to_str recebe número em RAX e destino em RDI; retorna comprimento em RAX.
; Ela preserva RBX e altera RAX, RCX, RDX, RDI, R8, R9 e flags.
; vm_print_stack também altera RSI e R11; syscall modifica RCX e R11.
;
; resb reserva bytes na .bss, inicialmente zerada. Os buffers são compartilhados
; entre chamadas, usados pelo fluxo sequencial atual, sem conversões simultâneas.
; STACK_CAPACITY é local e não controla os limites das escritas neste arquivo.
; Limites atuais: 8192 bytes não comportam todos os possíveis 4096 inteiros longos.
; Não há guarda de espaço nem tratamento de erro ou escrita parcial de write.
;
; Rótulos com ponto são locais à rotina: os de conversão pertencem a int_to_str,
; enquanto os de impressão pertencem a vm_print_stack. jmp não salva retorno;
; call salva retorno na pilha nativa, e ret o recupera.
global vm_print_stack ; exporta vm_print_stack para os outros módulos e para o linker

extern vm_stack ; declara vm_stack, definido em outro módulo e resolvido pelo linker
extern stack_top ; declara stack_top, definido em outro módulo e resolvido pelo linker

section .bss ; seleciona a seção .bss durante a montagem, sem executar código
    STACK_CAPACITY equ 4096          ; precisa bater com o valor real de stack.asm
    print_buf:   resb 8192 ; reserva 8192 bytes para a linha completa que será impressa
    tmp_digits:  resb 32 ; reserva 32 bytes para os dígitos extraídos em ordem inversa

section .text ; vale lembrar, o ponteiro do .text é RIP

; ------------------------------------------
; vm_print_stack: imprime a pilha no formato "n, n, n\n"
; ------------------------------------------
vm_print_stack: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    push r12 ; salva o valor antigo de R12 na pilha nativa antes de modificá-lo
    push r13 ; salva o valor antigo de R13 na pilha nativa antes de modificá-lo
    push r14 ; salva o valor antigo de R14 antes de usá-lo como cursor do buffer

    mov r12, [stack_top] ; captura o número de células válidas
    xor r13, r13         ; zera o índice; começa na base, índice 0
    lea r14, [print_buf]  ; endereço inicial, sem ler seu conteúdo

    cmp r12, 0           ; cmp atualiza flags sem modificar a quantidade
    je .empty            ; ZF=1: não existem números para converter

.print_loop: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    cmp r13, r12         ; quantidade é limite exclusivo, não índice válido
    jge .done_loop       ; para ao consumir todas as células

    mov rcx, r13         ; copia o índice para calcular seu deslocamento
    shl rcx, 3           ; índice * 8 bytes por célula
    mov rax, [vm_stack + rcx] ; lê o inteiro de 64 bits a converter

    mov rdi, r14         ; passa o endereço livre como destino da conversão
    call int_to_str      ; escreve os caracteres; devolve tamanho em RAX
    add r14, rax         ; avança o cursor pelos bytes produzidos

    inc r13              ; próximo item
    cmp r13, r12 ; compara o próximo índice com a quantidade de elementos disponíveis
    jge .done_loop       ; evita vírgula e espaço depois do último número

    mov byte [r14], ','   ; byte fixa escrita de 8 bits; R14 só guarda endereço
    inc r14 ; avança o cursor um byte após o caractere escrito no buffer
    mov byte [r14], ' ' ; escreve um espaço ASCII depois da vírgula
    inc r14 ; avança o cursor um byte após o caractere escrito no buffer

    jmp .print_loop ; volta ao laço para converter o próximo elemento

.done_loop: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov byte [r14], 10    ; LF: quebra de linha, não os caracteres '1' e '0'
    inc r14 ; avança o cursor um byte após o caractere escrito no buffer
    jmp .write_out ; segue para enviar a linha montada à saída padrão

.empty: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov byte [r14], 10 ; escreve LF (quebra de linha), inclusive para uma pilha vazia
    inc r14 ; avança o cursor um byte após o caractere escrito no buffer

.write_out: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    lea rsi, [print_buf]  ; segundo argumento: endereço inicial dos bytes
    mov rdx, r14 ; copia o endereço final para calcular o comprimento da linha
    sub rdx, rsi         ; terceiro argumento: comprimento = fim - início
    mov rax, 1           ; número de write no Linux x86-64
    mov rdi, 1           ; primeiro argumento: descritor stdout (1)
    syscall              ; retorna bytes escritos/erro em RAX, não verificado aqui

    pop r14 ; restaura R14; desfaz o último push de preservação
    pop r13 ; restaura R13, usado pelo interpretador como limite do bytecode
    pop r12 ; restaura R12, usado pelo interpretador como ponteiro do bytecode
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador

; ------------------------------------------
; int_to_str: converte um inteiro com sinal (64 bits) para string decimal
; entrada: RAX = valor, RDI = ponteiro do buffer de destino
; saída:   RAX = quantidade de bytes escritos
; ------------------------------------------
int_to_str: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ; Dividir por 10 extrai primeiro unidades, depois dezenas: 123 -> 3, 2, 1.
    ; tmp_digits guarda essa ordem inversa, corrigida na cópia para o destino.
    push rbx             ; preserva RBX, que será usado como divisor
    push rdi             ; guarda o início do destino para a fase de cópia

    xor r8, r8           ; indicador de sinal negativo: inicialmente falso
    xor r9, r9           ; quantidade de dígitos temporários: inicialmente zero

    test rax, rax        ; atualiza flags sem mudar o valor; consulta seu sinal
    jns .positive        ; SF=0: não é negativo
    mov r8, 1            ; marca que precisaremos escrever '-'
    neg rax              ; magnitude a converter com divisão SEM sinal
    ; INT64_MIN é especial: neg mantém os bits de 2^63 e indica overflow.
    ; A flag não é usada, mas div interpreta esses bits como magnitude sem sinal,
    ; portanto a conversão ainda produz corretamente o texto desse valor.

.positive: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rbx, 10          ; base decimal; os restos estarão entre 0 e 9

    test rax, rax ; atualiza flags sem alterar RAX; ZF=1 indica valor zero
    jnz .convert_loop ; se o valor não é zero, começa a extração dos dígitos
    mov byte [tmp_digits], '0' ; zero também precisa de um dígito explícito
    mov r9, 1                 ; exatamente um caractere foi preparado
    jmp .build_string ; segue para montar o texto final com os dígitos preparados

.convert_loop: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    test rax, rax ; atualiza flags sem alterar RAX; ZF=1 indica valor zero
    jz .build_string ; quociente zero: encerra a extração dos dígitos
    xor rdx, rdx         ; zera a metade alta do dividendo RDX:RAX de 128 bits
    div rbx              ; quociente em RAX; resto (próximo dígito) em RDX
    add dl, '0'          ; DL são 8 bits baixos de RDX; soma código ASCII de zero
    mov [tmp_digits + r9], dl ; guarda um byte; unidades vêm primeiro
    inc r9               ; conta mais um dígito
    jmp .convert_loop ; repete a divisão com o quociente que ficou em RAX

.build_string: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    pop rdi              ; recupera endereço inicial do destino
    xor rcx, rcx         ; contador de bytes escritos, incluindo o sinal

    test r8, r8          ; consulta o indicador de negativo
    jz .skip_sign        ; zero: não precisa escrever sinal
    mov byte [rdi], '-' ; escreve o sinal menos no início do texto
    inc rdi ; avança o endereço de destino um byte após o caractere escrito
    inc rcx ; conta mais um byte escrito no texto final, incluindo o sinal

.skip_sign: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    dec r9               ; contagem vira índice do último dígito extraído
.copy_loop: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    cmp r9, -1           ; depois do índice 0, dec leva o índice a -1
    je .copy_done        ; todos os dígitos já foram copiados
    mov dl, [tmp_digits + r9] ; lê de trás para frente: corrige a ordem
    mov [rdi], dl        ; escreve um caractere no destino
    inc rdi ; avança o endereço de destino um byte após o caractere escrito
    inc rcx ; conta mais um byte escrito no texto final, incluindo o sinal
    dec r9 ; reduz o índice para acessar o próximo dígito na ordem inversa
    jmp .copy_loop ; repete a cópia até consumir todos os dígitos

.copy_done: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rax, rcx         ; devolve comprimento; não acrescenta terminador zero
    pop rbx              ; recupera o registrador do chamador
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador
