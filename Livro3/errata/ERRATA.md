# Errata — Livro 3

Correções do texto impresso identificadas após a publicação. A numeração corresponde às páginas impressas da prova examinada. Para como reproduzir os laboratórios (ambiente, etapas de build, diferenças de plataforma), veja as notas de acompanhamento por capítulo, a partir de [`../ACOMPANHAMENTO_DO_LIVRO.md`](../ACOMPANHAMENTO_DO_LIVRO.md).

| Página | O que está / problema | O que considerar ao reproduzir |
|---|---|---|
| 428 e 433 | A regra impressa usa `$ARG = []` e `$X.extend($ARG)`/`$X.append($ARG)`, mas a saída ilustrada corresponde a outra variante. | A versão canônica do repositório segue a p. 428. No Semgrep 1.168.0, o alerta dessa regra incide em `resolve_grants`, não em `db_connect`. A variante para comparação com a p. 433 está em `sem-smugg_saida_p433.yml`. |
| 486–487 | O texto menciona `./null_deref_rt 1`, mas a compilação gera `null_deref`. | Usar `./null_deref 1` após o comando de compilação apresentado. O nome do fonte continua `null_deref_rt.c`. |
| 502 | `cd /llvm_pass_lab`. | No setup original: `cd "$HOME/llvm-pass-lab"`. No preparador adicional do repositório, usar o diretório escolhido ao executar `preparar_lab.sh`. |
| 549, 555 e 562 | A p. 549 gera `flatten_clean.ll`; as comparações executam `./flatten_clean` sem apresentar a compilação desse executável. | Antes da execução, acrescentar `clang-21 -O1 -o flatten_clean flatten_target.c`. |
| 639–640 | A compilação gera `vuln_gadget`, mas o trecho Python usa `process('./vuln')`. | Usar `process('./vuln_gadget')`. O `rop.py` distribuído já usa esse nome. |
| 698 | O comando usa `-T ls_sec.ld`, mas a listagem contém apenas a seção adicional e substitui o script padrão do linker GNU. | Para o GNU linker validado, usar `ls_sec_complemento.ld`, que acrescenta `INSERT AFTER .text;`: `gcc main_lto.c engine.c sec_hooks.c -Xlinker -T ls_sec_complemento.ld -o programa`. A transcrição original permanece disponível. |
| 715 | `chmod +x build_relro && ./build_relro`, enquanto o script é apresentado como `build_relro.sh`. | Usar `chmod +x build_relro.sh && ./build_relro.sh`. O pacote também fornece a cópia sem extensão para compatibilidade. |
| 755–756 | A listagem chama-se `watch_malloc.c`, mas o comando compila `monitor_malloc.c`. | Ambos os nomes designam o mesmo exemplo; o repositório fornece cópias idênticas. Para nome único, usar `monitor_malloc.c` também ao abrir a listagem. |
| 780, índice | `OpaquePredicatesV2.cpp`. | `OpaquePredicatesv2.cpp`, com `v` minúsculo, conforme o arquivo e a p. 533. |
