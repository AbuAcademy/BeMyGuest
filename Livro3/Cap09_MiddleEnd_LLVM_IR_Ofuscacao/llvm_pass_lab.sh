#!/usr/bin/env bash
# llvm-pass-lab-setup.sh
# Setup do ambiente para os labs do Capítulo 2.3
# Testado em: Ubuntu 24.04 / 25.04 + LLVM 21.1.8

set -euo pipefail

# resolve o home do usuário real mesmo rodando com sudo
REAL_USER="${SUDO_USER:-$USER}"
LAB_DIR="/home/$REAL_USER/llvm-pass-lab"

mkdir -p "$LAB_DIR"

# instala LLVM 21 apenas se nao estiver presente
if command -v llvm-config-21 &>/dev/null; then
    echo "[*] LLVM 21 já instalado: $(llvm-config-21 --version) — pulando instalação."
else
    echo "[*] Instalando LLVM 21..."
    bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" -- 21

    llvm-config-21 --version || {
        echo "[!] llvm-config-21 não encontrado após instalação. Abortando."
        exit 1
    }
fi

echo "[*] Gerando CMakeLists.txt..."
cat > "$LAB_DIR/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(LLVMPassLab)

find_package(LLVM REQUIRED CONFIG
    PATHS /usr/lib/llvm-21/lib/cmake/llvm NO_DEFAULT_PATH)

include(AddLLVM)
include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# IRScout — reconnaissance pass
add_library(IRScout SHARED IRScout.cpp)
target_compile_options(IRScout PRIVATE -fno-rtti)
set_target_properties(IRScout PROPERTIES PREFIX "" SUFFIX ".so")

EOF

# corrige ownership para o usuário real
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"

echo ""
echo "[+] Ambiente pronto em $LAB_DIR"
echo ""
echo "    Próximos passos:"
echo "      1. Copie IRScout.cpp e SilentBeacon.cpp para $LAB_DIR/"
echo "      2. cmake -B build -DCMAKE_BUILD_TYPE=Release ."
echo "      3. cmake --build build"
echo "      4. ls build/*.so"
