# Acompanhamento — Cap. 09 (Middle-End / LLVM IR / Ofuscação)

Notas de reprodução deste capítulo, por página. Complementa o livro sem alterar seu texto. Índice geral: [`../ACOMPANHAMENTO_DO_LIVRO.md`](../ACOMPANHAMENTO_DO_LIVRO.md).

## P. 514 — IRBuilder completo

`prim_irbuilder.txt` é um programa C++ completo que constrói o módulo, define o contexto, funções e valores usados e cria `Entry`, `TrueBB`, `FalseBB` e o bloco de saída. O fragmento original foi preservado em `referencia/prim_irbuilder_fragmento_original.txt`.

Os símbolos `__beacon` e `__exfil` são stubs locais sem efeitos neste complemento de construção de IR. O gerador não executa a função instrumentada. Assim é possível estudar chamadas, memória e desvios sem depender dos exemplos de execução de outros arquivos.

```bash
clang++-21 -x c++ prim_irbuilder.txt -o prim_irbuilder \
  $(llvm-config-21 --cxxflags --ldflags --system-libs --libs core)
./prim_irbuilder > prim_irbuilder.ll
opt-21 -passes=verify -disable-output prim_irbuilder.ll
```

O gerador também chama `verifyModule` antes de imprimir o IR.

## Pp. 517 e 530–533 — evolução do CMake e dos passes

`pass_build.sh` funciona com o CMake inicial da p. 507: não há um alvo SilentBeacon comentado enganando a busca textual. Não volte a inserir `#add_library(SilentBeacon ...)` como stub nesse CMake.

A versão `OpaquePredicatesv2.cpp` deriva do arquivo v5 do laboratório do autor: âncora `nop`, rótulos por função, início do pipeline e `mov $1, $0`. O comentário sobre a ordem dos operandos (AT&T: entrada → saída) acompanha a instrução. As referências de IR devem ser geradas de cada fonte, não copiadas entre versões.

## Pp. 559–562 — BogusCF e verificação do IR

O fonte original compilava o binário e produzia os quatro valores esperados, mas seu IR falhava em `opt-21 -passes=verify` com `Instruction does not dominate all uses`. Compilar para código nativo não substitui essa verificação.

O `BogusCF.cpp` deste pacote inclui uma correção identificada no código: remapear os usos internos do bloco clonado e fazer o caminho falso convergir no bloco real antes dos sucessores. A versão original está preservada em `referencia/BogusCF_p559_original.cpp`. O mecanismo de predicado e a âncora `nop` foram conservados. A alteração modifica detalhes do grafo; as figuras e contagens de instruções do livro não são prometidas como idênticas ao grafo corrigido.

O IR `obfuscated_bogus.ll` foi regenerado do fonte corrigido e passou no verificador. O binário continua produzindo `-1`, `0`, `1`, `2` para as quatro entradas do alvo do livro.

## Pp. 563 e 569–575 — alvos e referências

`target.c` na composição genérica de passes da p. 563 é um nome de alvo a escolher; não é um arquivo autoral adicional. Para usar o alvo já apresentado, substitua por `flatten_target.c`.

`vbo_v2.sh` usa `vbo_target.c`, como na p. 569. Os arquivos de entrada e saída efetivamente usados pelo script são `vbo_v2.bc` e `vbo_v2_pass.bc`. Não altere a constante 2027 do alvo.
