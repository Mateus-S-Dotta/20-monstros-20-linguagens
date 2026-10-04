; ==========================================
; ops.asm - Operações da mini-VM (REMOVE, ADD, SUB, MUL, DIV)
; ==========================================

; GUIA DE ESTUDO: operações e duas pilhas diferentes
; global exporta estas rotinas; extern referencia símbolos de stack.asm.
; vm_stack é o array da calculadora; a pilha nativa, apontada por RSP, guarda
; retornos de call e temporários de push/pop x86. call vm_pop retira da VM;
; push rax guarda o registrador na pilha NATIVA. São operações independentes.
; Cada push temporário deve ter um pop antes do ret, para não perder o retorno.
;
; Exemplo: [10, 3] -> b=3, a=10. SUB produz 10-3; DIV produz 10/3.
; O primeiro vm_pop devolve b em RAX; salvamos b na pilha nativa porque
; o segundo vm_pop altera RAX, RBX e RCX. Depois recuperamos b em RBX.
; RAX recebe o resultado e é o argumento esperado por vm_push.
; vm_push também altera RBX/RCX, então valores nesses registradores não
; sobrevivem à chamada sem preservação explícita pelo chamador.
; Estas rotinas podem alterar RAX/RBX/RCX e flags; REMOVE/DIV também RDX.
; O acordo é interno e não preserva RBX conforme a ABI de funções C.
;
; CHECK_MIN_TWO é uma macro: NASM expande suas instruções durante a montagem.
; Não há call/ret da macro em execução; %1 é seu argumento, o destino do salto.
; Rótulos com ponto são locais: cada .skip pertence à rotina que o precede.
; A guarda protege tanto pilha vazia quanto pilha com apenas um elemento.
; ret recupera o endereço guardado por call; jmp apenas transfere o fluxo.
;
; ADD/SUB/MUL não verificam overflow: conservam os 64 bits do resultado.
; DIV trunca em direção a zero e descarta o resto. Divisor zero é tratado;
; INT64_MIN / -1 também provoca exceção na CPU e não é tratado neste código.
global vm_remove_first ; exporta vm_remove_first para os outros módulos e para o linker
global vm_add ; exporta vm_add para os outros módulos e para o linker
global vm_sub ; exporta vm_sub para os outros módulos e para o linker
global vm_mul ; exporta vm_mul para os outros módulos e para o linker
global vm_div ; exporta vm_div para os outros módulos e para o linker

extern vm_push ; declara vm_push, definido em outro módulo e resolvido pelo linker
extern vm_pop ; declara vm_pop, definido em outro módulo e resolvido pelo linker
extern vm_stack ; declara vm_stack, definido em outro módulo e resolvido pelo linker
extern stack_top ; declara stack_top, definido em outro módulo e resolvido pelo linker

section .text ; vale lembrar, o ponteiro do .text é RIP

; ------------------------------------------
; macro de guarda: pula pro rótulo %1 se stack_top < 2
; ("nenhuma ação > 1 se só tiver 1 elemento")
; destrói: RAX
; ------------------------------------------
%macro CHECK_MIN_TWO 1 ; define uma macro de um argumento, referenciado como %1
    mov rax, [stack_top] ; lê a quantidade, não o endereço de stack_top
    cmp rax, 2          ; atualiza flags sem modificar RAX
    jl %1               ; menos de dois itens: salta ao destino dado à macro
%endmacro ; encerra a definição da macro; não executa um retorno na CPU

; ------------------------------------------
; vm_remove_first: remove o elemento do INÍCIO da pilha (índice 0)
; desloca todos os demais uma posição para baixo
; se stack_top < 2, não faz nada (no-op)
; destrói: RAX, RBX, RCX, RDX
; ------------------------------------------
vm_remove_first: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    CHECK_MIN_TWO .skip ; expande a guarda: menos de dois itens faz saltar para .skip

    mov rbx, [stack_top]      ; rbx = quantidade atual de elementos
    xor rcx, rcx              ; rcx = índice de destino (escrita)

.shift_loop: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    mov rdx, rcx ; copia o índice de destino para preparar o índice de origem
    inc rdx                   ; rdx = índice de origem (leitura), sempre 1 à frente
    cmp rdx, rbx ; compara o índice de origem com a quantidade válida de itens
    jge .shift_done ; termina a cópia se o índice de origem atingiu o limite

    ; *8 converte índice em bytes. RAX intermedeia a cópia: mov comum não
    ; aceita dois operandos de memória. Copiamos da origem para o destino anterior.
    mov rax, [vm_stack + rdx*8] ; lê a célula de origem; índice vezes 8 é o deslocamento em bytes
    mov [vm_stack + rcx*8], rax ; escreve a célula na posição anterior em direção à base

    inc rcx ; avança o índice de destino para deslocar a próxima célula
    jmp .shift_loop ; repete o deslocamento da próxima célula

.shift_done: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    dec rbx                  ; uma célula deixa de pertencer à pilha válida
    mov [stack_top], rbx      ; não é necessário apagar o último valor antigo

.skip: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador

; ------------------------------------------
; vm_add: pop b, pop a, push (a + b)
; se stack_top < 2, não faz nada (no-op)
; ------------------------------------------
vm_add: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    CHECK_MIN_TWO .skip ; expande a guarda: menos de dois itens faz saltar para .skip
    call vm_pop ; retira b, o topo, e o devolve em RAX; também modifica RBX e RCX
    push rax         ; guarda b na pilha NATIVA do x86 (não na vm_stack!)
    call vm_pop      ; rax = a
    pop rbx          ; recupera b
    add rax, rbx     ; rax = a + b
    call vm_push ; empilha o valor de RAX na VM; também modifica RBX e RCX
.skip: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador

; ------------------------------------------
; vm_sub: pop b, pop a, push (a - b)
; se stack_top < 2, não faz nada (no-op)
; ------------------------------------------
vm_sub: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    CHECK_MIN_TWO .skip ; expande a guarda: menos de dois itens faz saltar para .skip
    call vm_pop ; retira b, o topo, e o devolve em RAX; também modifica RBX e RCX
    push rax ; guarda b na pilha nativa enquanto o segundo vm_pop busca a
    call vm_pop      ; rax = a
    pop rbx          ; b
    sub rax, rbx     ; rax = a - b
    call vm_push ; empilha o valor de RAX na VM; também modifica RBX e RCX
.skip: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador

; ------------------------------------------
; vm_mul: pop b, pop a, push (a * b)
; se stack_top < 2, não faz nada (no-op)
; ------------------------------------------
vm_mul: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    CHECK_MIN_TWO .skip ; expande a guarda: menos de dois itens faz saltar para .skip
    call vm_pop ; retira b, o topo, e o devolve em RAX; também modifica RBX e RCX
    push rax ; guarda b na pilha nativa enquanto o segundo vm_pop busca a
    call vm_pop      ; rax = a
    pop rbx          ; b
    imul rax, rbx    ; rax = a * b (multiplicação com sinal)
    call vm_push ; empilha o valor de RAX na VM; também modifica RBX e RCX
.skip: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador

; ------------------------------------------
; vm_div: pop b, pop a, push (a / b)
; se stack_top < 2, não faz nada (no-op)
; se b == 0, restaura a e b na pilha sem dividir (evita crash)
; ------------------------------------------
vm_div: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    CHECK_MIN_TWO .skip ; expande a guarda: menos de dois itens faz saltar para .skip
    call vm_pop ; retira b, o topo, e o devolve em RAX; também modifica RBX e RCX
    push rax          ; guarda b
    call vm_pop       ; rax = a
    pop rbx           ; rbx = b

    test rbx, rbx     ; AND apenas para flags: ZF=1 quando b é zero; RBX não muda
    jz .div_zero      ; evita executar idiv com divisor zero

    cqo               ; replica o sinal em RDX, formando RDX:RAX de 128 bits
    idiv rbx          ; quociente com sinal em RAX; resto em RDX é descartado
    call vm_push ; empilha o valor de RAX na VM; também modifica RBX e RCX
    jmp .skip ; pula o caminho de restauração e segue para o retorno da rotina

.div_zero: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ; divisão por zero: desfaz o pop, devolve a e b como estavam
    push rbx          ; guarda b na pilha nativa (rax ainda é 'a')
    call vm_push      ; devolve 'a'
    pop rax           ; recupera b
    call vm_push      ; devolve 'b'

.skip: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ret ; recupera da pilha nativa o endereço salvo por call e retoma o chamador
