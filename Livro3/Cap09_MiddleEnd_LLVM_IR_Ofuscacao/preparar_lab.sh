#!/usr/bin/env bash
set -euo pipefail
src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dest="${1:-$HOME/llvm-pass-lab-livro3}"
mkdir -p -- "$dest"
# Não sobrescreve arquivos de um laboratório que já recebeu alterações do leitor.
for f in "$src"/*; do
    [ -f "$f" ] || continue
    case "$f" in *.cpp|*.c|*.sh|*.txt|*.ll|*/CMakeLists.txt)
        target="$dest/$(basename -- "$f")"
        if [ ! -e "$target" ]; then
            cp -- "$f" "$target"
        elif ! cmp -s -- "$f" "$target"; then
            printf 'Preservado arquivo diferente: %s (use uma pasta nova para validar esta edição)\n' "$target" >&2
        fi
    esac
done
printf 'Laboratório preparado em: %s\nEntre nesse diretório antes dos comandos cmake/pass_build.\n' "$dest"
