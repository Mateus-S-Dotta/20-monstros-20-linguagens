# Ajuste SRC/BIN pro nome real do seu projeto
SRC := vm.asm
BIN := vm
OBJ := $(BIN).o
 
all: $(BIN)
 
$(OBJ): $(SRC)
	nasm -f elf64 -g -F dwarf $(SRC) -o $(OBJ)
 
# Sem -lc / sem libc: link direto, entrada em _start
$(BIN): $(OBJ)
	ld $(OBJ) -o $(BIN)
 
run: $(BIN)
	./$(BIN)
 
debug: $(BIN)
	gdb ./$(BIN)
 
trace: $(BIN)
	strace ./$(BIN)
 
clean:
	rm -f $(OBJ) $(BIN)
 
.PHONY: all run debug trace clean
 