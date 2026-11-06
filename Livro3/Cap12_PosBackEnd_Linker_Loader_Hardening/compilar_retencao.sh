#!/usr/bin/env bash
# Complemento de execução da página 698: acrescenta seções ao layout padrão.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
gcc main_lto.c engine.c sec_hooks.c -Xlinker -T ls_sec_complemento.ld -o programa
