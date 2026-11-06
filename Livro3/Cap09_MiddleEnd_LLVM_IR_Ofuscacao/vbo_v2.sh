#!/bin/bash
# vbo_v2.sh — Pipeline de Injecao e Validacao da Virtualizacao V2

# 1. Compila o alvo C para Bitcode (.bc) com otimizacao leve
clang-21 -O1 -emit-llvm -c vbo_target.c -o vbo_v2.bc

echo "[*] Verificando ausencia de optnone no original..."
if llvm-dis-21 vbo_v2.bc -o - | grep -q "optnone"; then
    echo "[!] Erro: optnone detectado no bitcode inicial!"
    exit 1
fi

echo "[*] Injetando Virtualização..."
opt-21 -load-pass-plugin=./build/VMProtectv2.so \
       -passes="virtualize,verify" vbo_v2.bc -o vbo_v2_pass.bc

echo "[*] Validando Ponto de Entrada (FIX #1)..."
if ! llvm-dis-21 vbo_v2_pass.bc -o - | \
     grep -A 1 "check_auth" | grep -q "vm_entry"; then
    echo "[!] Erro: vm_entry nao e o primeiro bloco!"
    exit 1
fi

echo "[*] Finalizando binario nativo..."
clang-21 vbo_v2_pass.bc -o vbo_v2_fixed
echo -e "\n[+] SUCESSO: Virtualizacao aplicada com exito."

echo "[*] Gerando Grafo de Fluxo de Controle (CFG)..."
opt-21 -passes="dot-cfg" vbo_v2_pass.bc -o /dev/null > /dev/null 2>&1

if [ -f .check_auth.dot ]; then
    mv .check_auth.dot check_auth_v2.dot
fi

dot -Tpng check_auth_v2.dot -o vbo_v2_graph.png
xdg-open vbo_v2_graph.png 2>&- &
