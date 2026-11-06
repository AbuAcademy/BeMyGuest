#!/usr/bin/env bash
# install_llvm.sh — LLVM 21 full toolchain installer
# Testado em Ubuntu 25.04 (Plucky) x86_64
# Uso: sudo bash install_llvm.sh

set -euo pipefail

LLVM_VERSION=21

echo "[*] baixando script oficial apt.llvm.org..."
wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh
chmod +x /tmp/llvm.sh

echo "[*] instalando repositório e LLVM ${LLVM_VERSION}..."
sudo bash /tmp/llvm.sh ${LLVM_VERSION}

echo "[*] instalando componentes..."
sudo apt install -y \
    llvm-${LLVM_VERSION} \
    llvm-${LLVM_VERSION}-dev \
    llvm-${LLVM_VERSION}-tools \
    clang-${LLVM_VERSION} \
    clang-tools-${LLVM_VERSION} \
    clangd-${LLVM_VERSION} \
    clang-format-${LLVM_VERSION} \
    clang-tidy-${LLVM_VERSION} \
    lld-${LLVM_VERSION} \
    lldb-${LLVM_VERSION} \
    libc++-${LLVM_VERSION}-dev \
    libc++abi-${LLVM_VERSION}-dev \
    libclang-${LLVM_VERSION}-dev \
    libclang-cpp${LLVM_VERSION}-dev

echo "[*] configurando symlinks..."
TOOLS="clang clang++ llvm-dis llvm-as llvm-opt opt lldb lld"
for tool in clang clang++; do
    sudo update-alternatives --install \
        /usr/bin/${tool} ${tool} \
        /usr/bin/${tool}-${LLVM_VERSION} 100
done

for tool in llvm-dis llvm-as opt lldb lld; do
    BIN="/usr/bin/${tool}-${LLVM_VERSION}"
    if [ -f "$BIN" ]; then
        sudo update-alternatives --install \
            /usr/bin/${tool} ${tool} \
            "$BIN" 100
    fi
done

echo "[*] verificando instalação..."
echo ""
clang-${LLVM_VERSION} --version
echo ""
opt-${LLVM_VERSION} --version
echo ""
lldb-${LLVM_VERSION} --version

echo ""
echo "[+] LLVM ${LLVM_VERSION} instalado com sucesso."
echo "    Versões disponíveis:"
echo "      clang      -> clang-${LLVM_VERSION}"
echo "      opt        -> opt-${LLVM_VERSION}"
echo "      lldb       -> lldb-${LLVM_VERSION}"
echo "      lld        -> lld-${LLVM_VERSION}"
echo "      llvm-dis   -> llvm-dis-${LLVM_VERSION}"
