; GUIA DE ESTUDO: entrada do executável Linux
; O linker usa _start como entrada. Não há main de C nem libc inicializando
; este programa: a execução começa diretamente nas instruções abaixo.
; Fluxo: _start -> vm_run -> operação -> impressão -> próximo opcode.
; A CPU executa instruções x86; o bytecode da VM é dado interpretado por vm_run.
;
; extern declara um símbolo definido em outro arquivo; global exporta um
; símbolo deste arquivo. O linker conecta as referências depois da montagem.
; section seleciona onde o NASM coloca o código; não é uma instrução da CPU.
; call guarda o endereço da instrução seguinte na pilha nativa (RSP) e muda
; o fluxo para vm_run. ret recuperaria esse endereço para voltar ao chamador.
; vm_run termina o processo por syscall e não retorna, portanto não há ret aqui.
extern vm_run ; declara vm_run, definido em outro módulo e resolvido pelo linker

section .text ; vale lembrar, o ponteiro do .text é RIP
global _start ; exporta _start para os outros módulos e para o linker
_start: ; marca este endereço como destino de saltos/chamadas; o rótulo não ocupa bytes
    ; Caso eu quisesse colocar parametros em VM_RUN
    ; eu iria colocar os valores dos parametros
    ; nos registradores especificos que a função usa
    ; parâmetro em Assembly é literalmente "coloque o valor num lugar combinado (registrador ou pilha) antes do call, e a função vai procurar lá"
    ; existem convensões mundo a fora, mas o nosso projeto é 100% interno, então tem a própria convensão

    call vm_run ; call muda o RIP para a função que eu passar
