extern vm_run

section .text ; vale lembrar, o ponteiro do .text é RIP
global _start
_start:
    ; Caso eu quisesse colocar parametros em VM_RUN
    ; eu iria colocar os valores dos parametros
    ; nos registradores especificos que a função usa
    ; parâmetro em Assembly é literalmente "coloque o valor num lugar combinado (registrador ou pilha) antes do call, e a função vai procurar lá"
    ; existem convensões mundo a fora, mas o nosso projeto é 100% interno, então tem a própria convensão

    call vm_run ; call muda o RIP para a função que eu passar