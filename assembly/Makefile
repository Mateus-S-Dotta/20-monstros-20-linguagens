# Ajuste BIN pro nome real do seu projeto
BIN := vm

SRC_DIR := src
BUILD_DIR := build

# Descobre automaticamente todos os .asm dentro de src/
SRCS := $(wildcard $(SRC_DIR)/*.asm)

# Mapeia src/foo.asm -> build/foo.o
OBJS := $(patsubst $(SRC_DIR)/%.asm, $(BUILD_DIR)/%.o, $(SRCS))

all: $(BIN)

# Regra genérica: compila qualquer build/X.o a partir de src/X.asm
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm | $(BUILD_DIR)
	nasm -f elf64 -g -F dwarf $< -o $@

# Garante que a pasta build/ existe antes de compilar
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Sem -lc / sem libc: link direto, entrada em _start
$(BIN): $(OBJS)
	ld $(OBJS) -o $(BIN)

run: $(BIN)
	./$(BIN)

debug: $(BIN)
	gdb ./$(BIN)

trace: $(BIN)
	strace ./$(BIN)

clean:
	rm -rf $(BUILD_DIR) $(BIN)

.PHONY: all run debug trace clean