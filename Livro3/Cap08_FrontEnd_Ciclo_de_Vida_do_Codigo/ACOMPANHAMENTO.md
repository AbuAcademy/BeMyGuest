# Acompanhamento — Cap. 08 (Front-End / Ciclo de Vida do Código)

Notas de reprodução deste capítulo, por página. Complementa o livro sem alterar seu texto. Índice geral: [`../ACOMPANHAMENTO_DO_LIVRO.md`](../ACOMPANHAMENTO_DO_LIVRO.md).

## P. 400 — publicação PyPI

`publish.yml` contém o job impresso. É um trecho: ele pressupõe que outro job produza e envie um artefato chamado `dist` no mesmo workflow, e que o projeto configure Trusted Publishing no PyPI.

Para um projeto Python empacotável, `exemplos-github/publish-completo.yml` acrescenta o disparo manual e o job de build/upload necessários. Copie-o para `.github/workflows/publish.yml` **no projeto Python que será publicado** e configure o Trusted Publisher com os dados desse projeto. A coleção de códigos do livro não é um pacote PyPI a publicar. O `setup.py` da p. 402 pertence ao exemplo separado de assinatura de um tarball e não implementa o empacotamento desse workflow.

Fontes de operação: [PyPA — GitHub Action](https://github.com/pypa/gh-action-pypi-publish), [GitHub — CodeQL CLI](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/scan-from-the-command-line/set-up-codeql-cli).

## Pp. 427–443 — diretórios do laboratório

Execute `setup_codeql.sh` para preparar `~/smuggling-lab`. A pasta inicial `targets/` contém `validator.py`, `firewall.py` e `config.py`. Quando chegar à etapa de evasões, copie `evasions.py` para `targets/`, como arquivo adicional dessa etapa. As queries estão disponíveis tanto nesta pasta quanto em `queries/` para respeitar os caminhos dos comandos.

`rules/sem-smugg.yml` segue os padrões impressos na p. 428. Campos de identificação, mensagem, linguagem e severidade completam as partes abreviadas com reticências no livro.

O `setup_codeql.sh` recupera a rota de download usada pelo autor, corrigindo o endereço truncado. Se uma instalação anterior deixou apenas a pasta vazia, a ausência do executável provoca novo download. Com ferramenta e packs já disponíveis, é possível preparar o laboratório sem reinstalar o sistema. A validação deste pacote não incluiu uma instalação remota completa em máquina virgem.

## Pp. 444–447 — homóglifos e pre-commit

O hook é um arquivo que o Git executa antes de um commit. O exemplo chama `homoglyph_audit.py` nos arquivos Python adicionados ao stage. É uma integração opcional do laboratório, não um requisito para executar os outros capítulos.

Na raiz de `~/smuggling-lab`, onde o setup coloca o scanner e `hooks/pre-commit`:

```bash
git init
mkdir -p .git/hooks
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Se já existir um hook próprio nesse laboratório, integre o exemplo ao hook existente em vez de sobrescrevê-lo. Não versione `.git/`. O exemplo da p. 446 usa nomes separados por whitespace; nos arquivos do laboratório os nomes não têm espaços. Ele verifica o conteúdo atual dos arquivos; não é uma implementação genérica para commits parcialmente staged.

O laboratório inclui amostras que devem disparar o detector. Um bloqueio ao tentar commitar essas amostras é um resultado didático esperado. Não instale o hook automaticamente na raiz da coleção inteira. O YAML da p. 447 está em `exemplos-github/homoglyph-audit.yml` e também pressupõe scanner e `targets/` na raiz do laboratório.

## Pp. 469–471 — memset

O mesmo `memset_wipe.c` está neste capítulo e no Cap09. Aqui, ele fica ao lado do auxiliar `memset_wipe.py`. As duas cópias são iguais neste pacote.
