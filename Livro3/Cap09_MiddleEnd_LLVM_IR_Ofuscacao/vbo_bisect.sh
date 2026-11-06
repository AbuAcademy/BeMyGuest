#!/bin/bash
# vbo_bisect.sh — Auditoria de Passes do Otimizador no Alvo VBO

DESTINO="VMProtect"

echo "[*] Gerando IR (vbo.ll) com o plugin carregado..."
clang-21 -fpass-plugin=./build/${DESTINO}.so \
     -S -emit-llvm vbo_target.c -o vbo.ll

echo "[*] Executando compilação final com auditoria (BISECT)..."
# Capturamos o log do bisect (stderr) para filtrar
clang-21 -fpass-plugin=./build/${DESTINO}.so \
      -O1 -mllvm -opt-bisect-limit=-1 \
      -o vbo vbo_target.c 2> vbo_bisect.log

# Filtro da saída do BISECT (primeiros passes do otimizador)
head -n 1 vbo_bisect.log
echo "..."
grep -m 1 "SimplifyCFGPass on check_auth" vbo_bisect.log
