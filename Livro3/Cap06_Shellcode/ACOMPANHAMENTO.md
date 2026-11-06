# Acompanhamento — Cap. 06 (Shellcode)

Notas de reprodução deste capítulo, por página. Complementa o livro sem alterar seu texto. Índice geral: [`../ACOMPANHAMENTO_DO_LIVRO.md`](../ACOMPANHAMENTO_DO_LIVRO.md).

## Pp. 200–203 — duas etapas de xelcold

`xelcold.c` representa a versão inicial com array global. `xelcold_fixed.c` representa a mudança do array para a pilha. A falha discutida na etapa inicial faz parte do experimento; não substitua os dois arquivos por uma única variante. Os bytes e comentários devem ser associados à etapa que descrevem.

## P. 235 — análise comentada

`tcp_reverse_com.bin` é texto UTF-8 com opcodes, instruções e comentários, apesar da extensão. Abra em um editor de texto. Ele não substitui o binário bruto `tcp_reverse.bin` gerado pelo comando da página.
