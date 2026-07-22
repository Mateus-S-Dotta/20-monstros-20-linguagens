Extensão VSCode: 13xforever.language-x86-64-assembly

docker compose build
docker compose run --rm asm-vm

Rodar:
nasm -f elf64 -g -F dwarf print.asm -o print.o
ld print.o -o print
./print