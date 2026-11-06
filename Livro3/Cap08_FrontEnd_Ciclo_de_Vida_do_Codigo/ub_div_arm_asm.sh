#!/bin/bash

# Cores
YELLOW='\033[1;33m' # GCC
BLUE='\033[1;34m'   # Clang
GREEN='\033[0;32m'  # Assembly
CYAN='\033[0;36m'   # Info
NC='\033[0m'        # Reset

SRC="ub_div.c"
a=("aarch64-linux-gnu-gcc" "clang -target aarch64-linux-gnu")

# Cabeçalho único no início do script
echo -e "${CYAN}>>> Assembly Analysis (Target Function: vuln)${NC}\n"

for x in "${a[@]}"; do
    for y in 0 1 2 3; do
        if [[ "$x" == *"gcc"* ]]; then
            name="gcc"; COLOR=$YELLOW
        else
            name="clang"; COLOR=$BLUE
        fi
        
        echo -e "${COLOR}================================${NC}"
        echo -e "${COLOR}[$name -O$y]${NC}"
        
        # 1. Compilação e Execução Silenciosa
        OUT="ub_${name}_O${y}_arm"
        eval "$x -O$y -static -o \"$OUT\" \"$SRC\"" 2>&-
        
        if [ -f "$OUT" ]; then
            # Redireciona toda a saída para /dev/null
            qemu-aarch64 ./"$OUT" 32 > /dev/null 2>&1
            rm "$OUT"
        fi
        
        # 2. Análise: Apenas o Assembly em verde
        echo -e "${GREEN}"
        eval "$x -O$y -S \"$SRC\" -o -" 2>&- | grep -A 25 "vuln:"
        echo -e "${NC}"
    done
done
