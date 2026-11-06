#!/usr/bin/env bash
# Etapa anterior à comparação das páginas 555 e 562.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
clang-21 -O1 -o flatten_clean flatten_target.c
