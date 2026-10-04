; ==========================================
; bytecode.asm - Programa da mini-VM
; ==========================================

; GUIA DE ESTUDO: os dados que formam o programa da mini-VM
; global permite que o interpretador encontre estes símbolos através do linker.
; .data contém dados inicializados. db (define byte) emite um byte por valor:
; db 0x01, 10 gera dois bytes, opcode PUSH e operando 10. 0x é hexadecimal.
; Somente PUSH tem operando; cada outro comando ocupa um único byte.
; Os nomes PUSH/ADD nos comentários não fazem parte dos bytes gerados.
;
; O contexto define o significado: opcode é lido sem sinal, operando com sinal.
; -25 é codificado em complemento de dois como 0xE7; movsx no interpretador
; estende seu sinal para produzir -25 em 64 bits. PUSH aceita -128..127.
; Os resultados internos, porém, ocupam células de 64 bits, não apenas um byte.
; 0xFF é o opcode HALT, interpretado como 255; não empilha o número -1.
;
; Nos exemplos abaixo, a base fica à esquerda e o topo à direita.
; REMOVE retira a base; vm_pop retira o topo. Nas operações binárias, b é
; retirado primeiro (último item), depois a (penúltimo): calcula-se a operação b.
; Cada instrução imprime a pilha; HALT imprime novamente o estado final.
global bytecode ; exporta bytecode para os outros módulos e para o linker
global bytecode_len ; exporta bytecode_len para os outros módulos e para o linker

section .data ; seleciona a seção .data durante a montagem, sem executar código

bytecode: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    db 0x01, 10     ; PUSH 10  -> [10]
    db 0x01, -25    ; PUSH -25 -> [10, -25]
    db 0x01, 42     ; PUSH 42  -> [10, -25, 42]

    db 0x03         ; ADD      -> -25 + 42 = 17 -> [10, 17]

    db 0x02         ; REMOVE   -> remove o 10 (base) -> [17]

    db 0x03         ; ADD      -> só 1 elemento, no-op

    db 0x02         ; REMOVE   -> só 1 elemento, no-op

    db 0x01, 10     ; PUSH 10 -> [17, 10]

    db 0x04         ; SUB -> 17 - 10 = 7 -> [7]

    db 0x01, 2      ; PUSH 2 -> [7, 2]

    db 0x05         ; MUL -> 7 * 2 = 14 -> [14]

    db 0x01, 2      ; PUSH 2 -> [14, 2]

    db 0x06         ; DIV -> 14 / 2 = 7 -> [7]

    db 0xFF         ; HALT -> imprime [7] e encerra com status 0

; bytecode é o endereço inicial; $ é a posição atual durante a montagem.
; A diferença é o tamanho em bytes (20 neste programa). equ define uma
; constante: bytecode_len não é uma variável a ser acessada com colchetes.
bytecode_len equ $ - bytecode ; define o tamanho constante: posição atual menos endereço inicial
