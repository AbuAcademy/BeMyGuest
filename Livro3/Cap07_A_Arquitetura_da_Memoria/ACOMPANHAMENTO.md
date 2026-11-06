# Acompanhamento — Cap. 07 (A Arquitetura da Memória)

Notas de reprodução deste capítulo, por página. Complementa o livro sem alterar seu texto. Índice geral: [`../ACOMPANHAMENTO_DO_LIVRO.md`](../ACOMPANHAMENTO_DO_LIVRO.md).

## Pp. 327–333 — Windows

Use `mem_layout.c` com a toolchain Windows indicada no livro e o auxiliar `mem_layout.ps1`. A inclusão de `windows.h` e a chamada `setvbuf` no início de `main` são necessárias para as APIs usadas e para obter stdout durante a pausa. O `Sleep(-1)` mantém o processo aberto para a análise. O script Linux `mem_layout.sh` é um suplemento, não uma substituição do laboratório MSVC/PowerShell.
