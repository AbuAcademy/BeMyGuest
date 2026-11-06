#!/usr/bin/env bash
# Execute após construir os plugins nas etapas do livro.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
clang-21 -fpass-plugin=./build/OpaquePredicates.so -O1 -S -emit-llvm -o target_obf.ll target_op.c
clang-21 -fpass-plugin=./build/OpaquePredicatesv2.so -O1 -S -emit-llvm -o target_obf_v2.ll target_op.c
clang-21 -S -emit-llvm str_target.c -o str_target.ll
clang-21 -O1 -fpass-plugin=./build/StringEncryptor.so -S -emit-llvm str_target.c -o protected.ll
clang-21 -O1 -S -emit-llvm -o flatten_clean.ll flatten_target.c
clang-21 -O1 -fpass-plugin=./build/CFFlattening.so -S -emit-llvm -o flatten_obfuscated.ll flatten_target.c
clang-21 -O1 -fpass-plugin=./build/BogusCF.so -S -emit-llvm -o obfuscated_bogus.ll flatten_target.c
for file in target_obf.ll target_obf_v2.ll str_target.ll protected.ll flatten_clean.ll flatten_obfuscated.ll obfuscated_bogus.ll; do
    opt-21 -passes=verify -disable-output "$file"
done
