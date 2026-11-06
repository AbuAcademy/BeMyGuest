#!/bin/bash

SRC="ub_div.c"

# Definição de cores
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color (Reset)

# Verifica se o arquivo fonte existe
if [ ! -f "$SRC" ]; then
    echo "Erro: $SRC não encontrado!"
    exit 1
fi

for x in gcc clang; do
    # Define a cor baseada no compilador
    if [ "$x" == "gcc" ]; then COLOR=$YELLOW; else COLOR=$BLUE; fi

    if ! command -v $x &> /dev/null; then
        echo -e "${COLOR}[ $x não encontrado, pulando... ]${NC}"
        continue
    fi

    for y in 0 1 2 3; do
        OUT="ub_${x}_O${y}"
        
        # Destaca o cabeçalho com a cor escolhida
        echo -e "${COLOR}=== $x -O$y ===${NC}"
        
        # Compila (escondendo warnings se quiser focar só no output)
        $x -O$y -o "$OUT" "$SRC" 2>/dev/null
        
        if [ -f "$OUT" ]; then
            # Executa e opcionalmente destaca a saída do programa também
            ./"$OUT" 32
            rm "$OUT" # Limpa para não poluir o diretório
        fi
        
        echo ""
    done
done
