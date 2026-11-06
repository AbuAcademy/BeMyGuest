# Códigos/Scripts/Labs — Livro 3

**Be My Guest — Tratado de Engenharia Ofensiva e Defensiva Moderna (Livro 3)** · 1ª Edição, 2026 · Gustavo Abu

> ⚠️ **Aviso.** Exemplos educacionais de segurança ofensiva e defensiva. Execute apenas em **laboratório isolado** e em sistemas sob sua **autorização**. Alguns exemplos apresentam **falhas intencionais**, descritas no livro para o leitor ter novos pontos de vista diante de uma falha, um bug, ou de como burlar uma proteção — e de como detectar o invasor.

📄 Correções do texto impresso: [errata/ERRATA.md](errata/ERRATA.md)

Este pacote acompanha a edição publicada do Livro 3. Os diretórios `Cap02_…` a `Cap12_…` contêm os exemplos por capítulo.

O objetivo é reproduzir a sequência didática. Exemplos que demonstram erros de compilação, falhas de memória ou resultados de scanners continuam tendo esses comportamentos intencionais. **Uma falha prevista no texto não é um arquivo ausente nem uma dependência quebrada** — é proposital.

## Começo rápido

Não se assuste com o tamanho desta página: ela é um **guia de referência**. Você não precisa ler tudo de uma vez nem decorar nada — use só a parte do capítulo que estiver estudando. Na prática, são três passos:

1. **Baixe os códigos** (veja *Como baixar* no [README da raiz](../README.md)).
2. **Monte o laboratório uma vez:** uma VM com **Ubuntu 24.04 LTS** e a toolchain base (seção abaixo). Para os capítulos de Windows, uma VM do **Windows 11**.
3. **Abra o capítulo** que você está lendo no livro e siga os comandos daquela seção.

É isso. O restante da página detalha cada passo, caso precise.

## Montando o laboratório (Linux)

> **Versões de referência do livro:** **Ubuntu 24.04 LTS**, **LLVM/Clang 21** e, para os labs de Windows, **Windows 11** (destacadas nas páginas iniciais do Livro 3). Use essas mesmas versões para reproduzir os resultados sem surpresas.

A forma recomendada é partir de uma instalação **limpa do Ubuntu 24.04 LTS** numa VM isolada e deixar os scripts deste repositório instalarem a toolchain. Assim você não depende de baixar uma imagem pesada e sabe exatamente o que entra na sua máquina — afinal, somos hackers.

1. **Baixe o Ubuntu 24.04 LTS** (a mesma versão do livro) — https://releases.ubuntu.com/24.04/ — e instale numa VM isolada (VirtualBox, VMware ou QEMU).
2. **Baixe os códigos** dentro da VM (ver *Como baixar* no README da raiz do repositório).
3. **Instale a base da toolchain:**

   ```bash
   sudo apt update
   sudo apt install -y build-essential cmake git python3 python3-pip
   # LLVM/Clang 21 — script oficial do projeto LLVM:
   wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && sudo ./llvm.sh 21
   ```
4. **Prepare o laboratório do capítulo** que for estudar, com os scripts das seções abaixo (`setup_codeql.sh` para o Cap08, `preparar_lab.sh` para o Cap09). Eles instalam o que falta (Semgrep, CodeQL, passes LLVM) e **não** sobrescrevem um laboratório já alterado.

### Laboratório de Windows

Para os laboratórios de **Windows/MSVC/PowerShell/WinDbg**, use uma VM de avaliação do **Windows 11** fornecida pela própria Microsoft (gratuita, por tempo limitado):

- VM de desenvolvimento pronta: https://developer.microsoft.com/windows/downloads/virtual-machines/
- Ou uma ISO de avaliação do Windows 11 Enterprise: https://www.microsoft.com/evalcenter/evaluate-windows-11-enterprise

Dentro da VM isolada, instale o toolchain usado no livro via `winget` (PowerShell como administrador):

```powershell
winget install --id Microsoft.WinDbg -e
winget install --id LLVM.LLVM -e
winget install --id Kitware.CMake -e
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudio.2022.BuildTools -e
```

Os componentes específicos do MSVC (workloads do Visual Studio Build Tools) seguem o que o livro indica em cada capítulo. O ambiente **ARM64** também difere; siga o texto.

Nada aqui é distribuído como binário pronto: executáveis, objetos, bibliotecas e perfis são gerados localmente.

## Cap08 — Semgrep e CodeQL

Na pasta `Cap08_FrontEnd_Ciclo_de_Vida_do_Codigo`:

```bash
bash setup_codeql.sh
export PATH="$HOME/codeql-home/codeql:$PATH"
cd "$HOME/smuggling-lab"
semgrep --config rules/sem-smugg.yml targets/
codeql query run --database=smuggling-db queries/mutable_default_dataflow.ql
```

O `setup_codeql.sh` já deixa tudo pronto: cria os três alvos iniciais das pp. 427–433, as regras e as queries, preservando arquivos e banco existentes. Para reiniciar em outro diretório: `LIVRO3_LAB_DIR="$HOME/smuggling-lab-novo" bash setup_codeql.sh`. Depois de alterar os alvos, atualize o banco:

```bash
codeql database create smuggling-db --language=python --source-root=./targets --overwrite
```

Você não precisa se preocupar com versões — o script resolve. Mas se quiser usar as versões mais recentes, fique à vontade: as de referência do livro foram **CodeQL CLI 2.25.0**, **`codeql/python-all` 7.0.1** e **`codeql/python-queries` 1.7.9**. As variáveis `LIVRO3_CODEQL_VERSION`, `LIVRO3_PYTHON_ALL_VERSION` e `LIVRO3_PYTHON_QUERIES_VERSION` permitem escolher outras conscientemente.

O setup é para Linux x86-64 com glibc e usa `apt-get`. Com os requisitos já instalados, `LIVRO3_SKIP_APT=1` pula essa etapa. Para não mexer no `.bashrc`, use `LIVRO3_CONFIGURE_SHELL=0` e exporte o PATH manualmente. Não é preciso rodar tudo com `sudo`.

## Cap09 — Laboratório LLVM

Use **LLVM 21.1.8** para comparar os resultados com o ambiente validado. `llvm-config-21`, `clang-21`, `clang++-21`, `opt-21`, CMake e um compilador C++ devem estar disponíveis. Na pasta `Cap09_MiddleEnd_LLVM_IR_Ofuscacao`:

```bash
bash preparar_lab.sh "$HOME/llvm-pass-lab-livro3"
cd "$HOME/llvm-pass-lab-livro3"
cmake -B build -DCMAKE_BUILD_TYPE=Release .
cmake --build build
./pass_build.sh IRScout SilentBeacon
```

O CMake inicial contém apenas IRScout, como na p. 507. O `pass_build.sh` acrescenta os passes seguintes conforme a progressão do livro. O `preparar_lab.sh` copia apenas arquivos ausentes e não substitui um laboratório já alterado — para uma reprodução limpa, escolha uma pasta nova. O script `llvm_pass_lab.sh` também continua disponível; ele escreve o CMake inicial, então não deve ser repetido sobre um laboratório cujo CMake já evoluiu.

## Material adicional

- `prim_irbuilder.txt`: complemento compilável da p. 514; o fragmento anterior está em `referencia/`.
- `Cap08/.../hooks/pre-commit`: hook opcional da p. 446, para instalar explicitamente no laboratório.
- `Cap08/.../publish.yml`: trecho PyPI da p. 400. Um workflow completo de apoio está em `exemplos-github/`, fora dos workflows ativos deste repositório.
- `.ll` e `.s`: fontes/referências textuais didáticos, não lixo de compilação.

## Licença

Código-fonte, scripts e laboratórios deste diretório estão sob **licença BSD de 2 cláusulas** (ver [LICENSE](../LICENSE) na raiz do repositório), conforme a página de créditos do livro. A licença cobre o código; **não** licencia o texto integral da obra (© 2026 Gustavo Abu, todos os direitos reservados).

## Relatar problemas

Ao abrir uma issue, inclua: **página** do livro, **sistema operacional**, **toolchain e versões** (ex.: LLVM, Clang, Semgrep, CodeQL), **comando exato** executado e a **saída de erro** completa. Isso ajuda a distinguir uma falha intencional do exemplo de um problema de reprodução.

---

Bora pra cima… TMJ!
