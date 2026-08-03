Em Assembly, existem 'tipos' de memoria /operando (quem sofre operações), sendo algumas delas (existe mais que essas 4, mas não importa agora):
r -> registrador, apenas os registradores oficiais
imm -> valor imediato, número ou variável fora dos []. é o valor, cravado dentro da própria instrução (sem acessar RAM)
m -> a posição calculada do endereço de memoria, [variavel] pode ser essa
r/m -> é como o nome diz, ou um r ou um m

Cada instrução aceita um ou mais tipos.

Detalhe super legal: todos os processos brigam pela memoria, principalmente registradores.
Porém, o Kernel decide qual processo roda agora. Algo como: sua vez de brincar. Coloca todos os brinquedos de volta no lugar, e o processo segue normalmente.

Lista de minemonicos:

cmp | Compara valores
mov | coloca no primeiro 'argumento' o valor do segundo
jge | >=
jle | <=
ret | Retorna da função atual, voltando o ponteiro do .text para quem chamou
call | chama uma função, e cria um "salvador", para que o ret faça voltar para esse salvador e a função continuar a partir da linha exata de onde chamou
syscall | faz chamada de sistema. Pega o registrador rax para saber a operação, e depende de cada operação, mas pega outros registradores para ter de argumentos
inc | incrementa 1
dec | decrementa 1
shl | move todos os bits a esquerda, no valor que receber como segundo 'parametro'
push | salva o valor do argumento em uma pilha (salva na stack mesmo)
pop | resgata os valores salvos por push (na ordem inversa, pois é uma pilha)