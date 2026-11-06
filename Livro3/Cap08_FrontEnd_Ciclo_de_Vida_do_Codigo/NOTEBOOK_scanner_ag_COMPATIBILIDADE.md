# scanner_ag_v1_colab.ipynb — Nota de Compatibilidade

Este lab é **agentic** e depende de plataforma externa (Google Colab + Ollama + um
modelo LLM local + Tree-sitter). Como o livro já avisa, ele foi validado num momento
específico e **pode não rodar idêntico no futuro**, porque:
- a tag do modelo no Ollama (ex.: `qwen3.5:4b`) pode ser republicada/alterada;
- a imagem base do Colab (Python, CUDA, libs) muda sem aviso;
- o script de instalação do Ollama (`install.sh`) sempre puxa a versão mais recente.

Não é possível deixar 100% "à prova de mudanças". A meta é **reprodutibilidade máxima
+ transparência**: pinar o que der e registrar exatamente o que foi testado e quando.

## Versão canônica (a do livro)
- **`scanner_ag_v1_colab.ipynb`** → executa **`scanner_ag_v1.py`**. É a versão descrita
  no livro. **Use esta.**
- (Existe uma iteração posterior, `scanner_ag_v2.py` + notebook v3, que NÃO faz parte
  deste livro. Não está neste repositório de propósito.)

## Histórico de testes
| Versão | Quando testado | Ambiente | Resultado |
|---|---|---|---|
| v1 (este notebook) | **mar/2026** | Colab T4, Ollama (latest à época), modelo `qwen3.5:4b`, Tree-sitter 0.25.2 | ✅ Funcionou (resultados do livro) |
| v3 (scanner_ag_v2, fora do repo) | jul/2026 | Colab, Ollama/modelo atualizados | ⚠️ Quebrou / exigiu ajustes (drift de modelo/plataforma) |
| — | **ÚLTIMO TESTE: _preencher_** | _preencher_ | _preencher_ |

> Atualize a última linha toda vez que rodar. Assim o leitor sabe o quão recente é o "funciona".

## Como maximizar a chance de reproduzir (pins recomendados)
Se quiser blindar ao máximo, ajuste as células assim:

1. **Ollama (pinar versão):**
   ```
   !curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=<versão_testada> sh
   ```
2. **Modelo (registrar tag/digest exatos):** após `ollama pull`, rode `ollama show qwen3.5:4b`
   e anote o digest. Se o comportamento mudar, é sinal de que a tag foi republicada.
3. **Python (pinar libs):**
   ```
   !pip install -q "openai==<versão>" "tree-sitter==0.25.2" "tree-sitter-python==<versão>"
   ```
   (o livro cita Tree-sitter **0.25.2**). Capture o resto com `pip freeze > requirements-lock.txt`
   e commite junto.

## Fallback
Se o modelo local falhar/drift, o scanner aceita backend externo
(`--model` / Anthropic etc., ver `scanner_ag_v1.py -h`). Documentado no livro como alternativa.

## Sugestão de manutenção
- Rodar o notebook periodicamente (ex.: a cada 2–3 meses) e atualizar a tabela acima.
- Sempre commitar um `requirements-lock.txt` do último teste que funcionou.
