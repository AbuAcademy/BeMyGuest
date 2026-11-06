#!/usr/bin/env bash
set -euo pipefail

SRC="relro_demo.c"

if [[ ! -f "$SRC" ]]; then
    echo -e "\e[1;31m[!] Erro: Arquivo '$SRC' não encontrado.\e[0m"
    exit 1
fi

if ! command -v clang &>/dev/null; then
    echo -e "\e[1;31m[!] Erro: Clang não encontrado no PATH.\e[0m"
    exit 1
fi

echo -e "\e[1;34m[*] Compilando variantes de $SRC...\e[0m\n"

# Compilação das três matrizes
clang -O1 -no-pie -Wl,-z,norelro "$SRC" -o no_relro
clang -O1 -fPIE -pie -Wl,-z,relro -Wl,-z,lazy "$SRC" -o partial_relro
clang -O1 -fPIE -pie -Wl,-z,relro,-z,now \
      -fstack-protector-strong -D_FORTIFY_SOURCE=2 \
      "$SRC" -o full_relro

# Impressão da Tabela Didática (53 colunas)
echo -e "\e[1;32m[*] Mapeamento de Permissões por Nível de RELRO:\e[0m\n"

printf "┌────────────┬────────────────────┬──────┬──────────┐\n"
printf "│ %-10s │ %-18s │ %-4s │ %-8s │\n" "Nível" "Flags do Linker" ".got" ".got.plt"
printf "├────────────┼────────────────────┼──────┼──────────┤\n"
printf "│ %-10s │ %-18s │ %-4s │ %-8s │\n" "No RELRO"   "-z,norelro"       "RW" "RW"
printf "│ %-10s │ %-18s │ %-4s │ %-8s │\n" "Partial"    "-z,relro -z,lazy" "RO" "RW"
printf "│ %-10s │ %-18s │ %-4s │ %-8s │\n" "Full RELRO" "-z,relro -z,now"  "RO" "RO"
printf "└────────────┴────────────────────┴──────┴──────────┘\n"
