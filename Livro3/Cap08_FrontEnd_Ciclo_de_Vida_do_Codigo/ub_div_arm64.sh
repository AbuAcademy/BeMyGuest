#!/bin/bash

# Cores
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Reset

SRC="ub_div.c"
a=("aarch64-linux-gnu-gcc" "clang -target aarch64-linux-gnu")

for x in "${a[@]}"; do
    for y in 0 1 2 3; do
        if [[ "$x" == *"gcc"* ]]; then
            name="gcc"
            COLOR=$YELLOW
        else
            name="clang"
            COLOR=$BLUE
        fi
        
        # Cabeçalho colorido e separador
        echo -e "${COLOR}--------------------------------${NC}"
        echo -e "${COLOR}[$name -O$y]${NC}"
        
        OUT="ub_${name}_O${y}_arm64"
        
        # Compila (silencioso)
        eval "$x -O$y -static -o \"$OUT\" \"$SRC\"" 2>&-
        
        # Executa via QEMU se o binário existir
        if [ -f "$OUT" ]; then
            qemu-aarch64 ./"$OUT" 32
            rm "$OUT" # Limpa o binário após execução
        fi
        
        echo ""
    done
done
