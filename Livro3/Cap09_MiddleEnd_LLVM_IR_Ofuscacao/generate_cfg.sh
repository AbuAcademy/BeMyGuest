#!/bin/bash
TIPO=$1

if [ "$TIPO" != "clean" ] && [ "$TIPO" != "obfuscated" ]; then
  echo "Uso: $0 [clean|obfuscated]"
  exit 1
fi

echo "[*] Alvo selecionado: flatten_${TIPO}.ll"

echo "[1/4] Extraindo Grafo de Fluxo de Controle (CFG)..."
opt-21 -passes=dot-cfg -disable-output flatten_${TIPO}.ll

echo "[2/4] Renderizando imagem PNG via Graphviz..."
dot -Tpng .classify.dot -o flatten_${TIPO}.png
mv .classify.dot flatten_${TIPO}.dot

echo "[3/4] Simplificando metadados do arquivo DOT..."
sed -E 's/(shape|color|style|fillcolor|\
fontname)="?[^", ]+"?,?//g' flatten_${TIPO}.dot

echo "[4/4] Abrindo visualizador de imagens..."
xdg-open flatten_${TIPO}.png 2>&-

echo "[+] Concluido! Arquivos gerados para flatten_${TIPO}"
