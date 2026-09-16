# 🧟 20 Linguagens, 20 Monstros
 
> Um projeto para aprender linguagens de programação enfrentando de frente aquilo que costuma dar medo nelas.
 
**🚧 Projeto em desenvolvimento — status atualizado conforme o progresso.**
 
---
 
## A ideia
 
Este não é um projeto sobre "dominar" 20 linguagens. É sobre **perder o medo**.
 
Medo de paradigmas diferentes. Medo de sintaxe estranha. Medo de programar sem coletor de lixo, sem loops, sem variáveis nomeadas, sem exceções, sem `null`. Medo daquilo que parece "coisa de outro mundo" até você sentar e escrever 200 linhas e perceber que era só um jeito diferente de pensar.
 
Cada linguagem da lista tem um projeto pequeno (1 a 3 dias), desenhado especificamente para colocar o dedo na ferida: a característica que mais assusta ou confunde iniciantes naquela linguagem — o **monstro** — vira o objetivo central do projeto, não um obstáculo a evitar.
 
A lista também funciona como um passeio (não 100% cronológico, mas quase) pela evolução histórica das linguagens: da Assembly pura até as linguagens de sistemas modernas, passando pelos grandes paradigmas — imperativo, funcional, lógico, orientado a objetos, baseado em pilha, concorrente.
 
**Objetivo final:** sair do outro lado sem medo de nenhum paradigma de programação.
 
---
 
## Estrutura do repositório
 
Cada linguagem vive na sua própria pasta, autocontida:
 
```
/linguagem-xx-nome/
  ├── Dockerfile      # ambiente pronto para rodar o projeto, sem instalar nada na sua máquina
  ├── README.md       # explicação do projeto específico, como rodar, e notas de aprendizado
  └── src/             # código-fonte do projeto
```
 
Cada `Dockerfile` builda um ambiente isolado com a linguagem, suas dependências e o toolchain necessário. A ideia é: `docker build` + `docker run` e o projeto roda, sem precisar instalar Fortran, Ada ou Forth na sua máquina.
 
---
 
## A lista
 
| # | Linguagem | Projeto | O monstro | Status |
|---|-----------|---------|-----------|:------:|
| 1 | **Assembly** | Interpretador de uma mini-VM de pilha (bytecode próprio) rodando em NASM puro, com syscalls de I/O | Sem abstração nenhuma entre você e o processador | 🟡	Em andamento |
| 2 | **Fortran** | Solver de sistema linear (Gauss-Jordan) + leitura de matriz de arquivo + benchmark contra versão ingênua | Programação numérica, arrays, performance | 🔲 Não iniciado |
| 3 | **Lisp** | Interpretador de uma linguagem Lisp minúscula (meta-circular evaluator), com variáveis e funções | Código-como-dado, recursão, ambientes léxicos | 🔲 Não iniciado |
| 4 | **COBOL** | Sistema de folha de pagamento: ler funcionários de arquivo fixo, calcular impostos por faixa, gerar relatório formatado | Verbosidade + PICTURE + estruturas de dados fixas | 🔲 Não iniciado |
| 5 | **APL** | Conjunto de 5-6 problemas de manipulação de matrizes/estatística resolvidos só com operadores de array | Pensar 100% vetorizado, sem loop nenhum | 🔲 Não iniciado |
| 6 | **Forth** | Máquina de estados de um jogo de texto (tipo Zork simplificado) toda em stack, sem variáveis nomeadas | Modelagem de estado sem abstrações de alto nível | 🔲 Não iniciado |
| 7 | **C** | Mini-banco de dados chave-valor em disco: hash table própria, malloc/free, persistência em arquivo binário | Memória manual + serialização + debugging com gdb/valgrind | 🔲 Não iniciado |
| 8 | **Prolog** | Resolver de Sudoku genérico via backtracking + sistema de regras de parentesco com consultas complexas | Pensar 100% declarativo, backtracking automático | 🔲 Não iniciado |
| 9 | **Ada** | Sistema de controle de elevador com tasks concorrentes, tipos com range restrito, e tratamento de exceção formal | Concorrência segura + tipagem paranoica | 🔲 Não iniciado |
| 10 | **C++** | Motor de regras genérico com templates, RAII, smart pointers — zero `new`/`delete` cru, zero leak | Templates + gerenciamento de recurso automático | 🔲 Não iniciado |
| 11 | **Erlang** | Sistema de chat multi-sala com supervisores que reiniciam processos, tolerância a falha real (matar processo de propósito) | Actor model + "let it crash" na prática | 🔲 Não iniciado |
| 12 | **Perl** | Ferramenta de análise de log de servidor: parsing pesado com regex, geração de relatório, one-liners de verdade | Regex denso + idiomas "perlescos" | 🔲 Não iniciado |
| 13 | **Haskell** | Parser combinator do zero para uma linguagem de expressões, avaliado via `Maybe`/`Either` monad, com type classes próprias implementadas manualmente | Lazy evaluation + composição em vez de sequência + monads na prática | 🔲 Não iniciado |
| 14 | **Java** | API REST simples (sem framework, só `HttpServer`) com pool de threads, `synchronized`, fila compartilhada | Concorrência com locks, o jeito clássico e chato | 🔲 Não iniciado |
| 15 | **Scala** | Parser de uma linguagem de configuração própria usando `case class` + pattern matching exaustivo + `Option`/`Either` | Funcional + ADTs, tratamento de erro sem exceção | 🔲 Não iniciado |
| 16 | **Go** | Web crawler concorrente: N goroutines, channels, rate limiting, context pra cancelamento | CSP, concorrência sem locks | 🔲 Não iniciado |
| 17 | **Rust** | Parser de CSV → validador de schema, 100% sem `.unwrap()`, com testes cobrindo casos de erro | Borrow checker + erros como valores, de verdade | 🔲 Não iniciado |
| 18 | **OCaml** | Interpretador de calculadora com tipos: parser + type checker + avaliador, deixando o compilador achar bugs de tipo | Inferência de tipos forte, ADTs | 🔲 Não iniciado |
| 19 | **Zig** | Alocador de memória customizado (arena allocator) usado num programa que processa uma lista grande de dados | Controle total, zero malloc escondido | 🔲 Não iniciado |
| 20 | **Nim** | Macro que gera código de validação em tempo de compilação a partir de uma struct anotada | Metaprogramação com sintaxe amigável | 🔲 Não iniciado |
 
### Legenda de status
 
| Ícone | Significado |
|:---:|---|
| 🔲 | Não iniciado |
| 🟡 | Em andamento |
| ✅ | Concluído |
| 📝 | Concluído + README/anotações de aprendizado escritas |
 
---
 
## Como rodar um projeto
 
```bash
cd linguagem-XX-nome
docker build -t monstro-nome .
docker run --rm -it monstro-nome
```
 
Detalhes específicos (flags, volumes, portas expostas etc.) ficam no `README.md` de cada pasta.
 
---
 
## Por que esse formato
 
- **Um "monstro" por projeto**: cada projeto é desenhado ao redor da característica mais assustadora da linguagem, de propósito. Não dá pra "aprender Haskell" evitando monads, nem pra "aprender Rust" evitando o borrow checker. Melhor encarar de cara.
- **Docker em tudo**: elimina a fricção de "não consigo nem instalar o compilador" — o único monstro que interessa é o da linguagem, não o do ambiente.
- **Ordem quase cronológica**: dá pra sentir a evolução das ideias — de Assembly sem abstração nenhuma até Rust e Zig tentando resolver, décadas depois, os mesmos problemas de memória que C expôs lá atrás.
Sinta-se à vontade para acompanhar o progresso pelos status acima — o repositório é atualizado conforme cada monstro é enfrentado.
 

