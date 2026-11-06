#!/bin/bash
# pass_build.sh — Automação de Build do Castelo de Grayskull

# Garante que o usuário passou o passe de origem e o novo passe
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <passe_origem> <novo_passe>"
    echo "Exemplo: $0 IRScout SilentBeacon"
    exit 1
fi

ORIGEM=$1
DESTINO=$2

# Condição de Segurança: Só injeta se o alvo não existir na diretiva add_library
if ! grep -q "add_library(${DESTINO} " CMakeLists.txt; then
    echo "[+] Clonando e adaptando as diretivas de build: ${ORIGEM} -> ${DESTINO}"
    Clone=$(tac CMakeLists.txt | \
      sed -n "/set_target_properties(${ORIGEM} /,/# ${ORIGEM}/p" | tac)

    # Injeta uma quebra de linha e insere o bloco tratado
    echo "" >> CMakeLists.txt
    echo "${Clone}" | sed "s/${ORIGEM}/${DESTINO}/g" >> CMakeLists.txt
else
    echo "[*] Alvo ${DESTINO} já mapeado no CMakeLists.txt. Pulando injeção."
fi

echo "[+] Reconstruindo o ambiente do laboratório..."
rm -rf build/
# Removemos o /dev/null para você auditar qualquer erro de sintaxe do CMake
cmake -B build -DCMAKE_BUILD_TYPE=Release . >/dev/null

echo "[+] Disparando a compilação do artefato: ${DESTINO}..."
cmake --build build --target "${DESTINO}"
