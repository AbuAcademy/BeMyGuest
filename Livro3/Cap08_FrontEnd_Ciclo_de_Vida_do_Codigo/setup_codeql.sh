#!/usr/bin/env bash
# ==============================================================================
# SCRIPT DE AUTOMAÇÃO: ARSENAL CODEQL - SEMANTIC SMUGGLING LAB
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Versão encontrada na instalação usada pelo autor; URL recuperada do histórico.
CODEQL_VERSION="${LIVRO3_CODEQL_VERSION:-2.25.0}"
PYTHON_ALL_VERSION="${LIVRO3_PYTHON_ALL_VERSION:-7.0.1}"
PYTHON_QUERIES_VERSION="${LIVRO3_PYTHON_QUERIES_VERSION:-1.7.9}"

# Configuração de Cores para o Output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}[*] Iniciando o provisionamento do ambiente CodeQL...${NC}"

# 1. Instalação de dependências do sistema
echo -e "${BLUE}[*] Validando e instalando dependências (requer sudo)...${NC}"
if [ "${LIVRO3_SKIP_APT:-0}" != 1 ]; then
    sudo apt-get update && sudo apt-get install -y wget unzip git
fi

# 2. Download e Extração do CodeQL CLI
CODEQL_DIR="${LIVRO3_CODEQL_DIR:-$HOME/codeql-home}"
if [ ! -x "$CODEQL_DIR/codeql/codeql" ]; then
    echo -e "${BLUE}[*] Baixando CodeQL CLI $CODEQL_VERSION...${NC}"
    mkdir -p "$CODEQL_DIR"
    CODEQL_ARCHIVE=$(mktemp --suffix=.zip)
    trap 'rm -f -- "$CODEQL_ARCHIVE"' EXIT
    wget -q --show-progress -O "$CODEQL_ARCHIVE" \
        "https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-linux64.zip"
    unzip -q -o "$CODEQL_ARCHIVE" -d "$CODEQL_DIR"
else
    echo -e "${YELLOW}[!] CodeQL já instalado. Preservando a instalação existente.${NC}"
fi

# 3. Configuração de Variáveis de Ambiente (Persistente no .bashrc e ativa em runtime)
export PATH="$CODEQL_DIR/codeql:$PATH"
# Permite uma cache isolada em validações e ambientes efêmeros.
codeql() {
    local cache_args=()
    if [ -n "${LIVRO3_CODEQL_CACHE:-}" ]; then
        cache_args=("--common-caches=$LIVRO3_CODEQL_CACHE")
    fi
    command "$CODEQL_DIR/codeql/codeql" "$@" "${cache_args[@]}"
}
if [ "${LIVRO3_CONFIGURE_SHELL:-1}" = 1 ] && ! grep -q "codeql-home" "$HOME/.bashrc"; then
    echo -e "${BLUE}[*] Exportando CodeQL para o seu PATH (~/.bashrc)...${NC}"
    printf 'export PATH=%q:"$PATH"\n' "$CODEQL_DIR/codeql" >> "$HOME/.bashrc"
fi

# Validação imediata do binário
echo -e "${GREEN}[+] Versão do CodeQL instalada:${NC}"
codeql version | sed -n '1p'

# 4. Download dos pacotes oficiais de Queries para análise em Python
echo -e "${BLUE}[*] Baixando e indexando os pacotes de queries oficiais para Python...${NC}"
if [ "${LIVRO3_PACKS_PRONTOS:-0}" != 1 ]; then
    codeql pack download "codeql/python-queries@$PYTHON_QUERIES_VERSION"
    codeql pack download "codeql/python-all@$PYTHON_ALL_VERSION"
fi
codeql resolve packs

# 5. Garantindo a estrutura do laboratório local
LAB_DIR="${LIVRO3_LAB_DIR:-$HOME/smuggling-lab}"
echo -e "${BLUE}[*] Configurando o workspace em $LAB_DIR...${NC}"
mkdir -p "$LAB_DIR/queries"

# Se o diretório targets estiver vazio ou não existir, criamos o laboratório padrão
if [ ! -d "$LAB_DIR/targets" ]; then
    mkdir -p "$LAB_DIR/targets"
    echo -e "${YELLOW}[!] Diretório targets não encontrado. Criando alvos padrão...${NC}"
    
    cat > "$LAB_DIR/targets/validator.py" << 'EOF'
ADMIN_ROLES = {"superuser", "admin", "root"}
def check_access(user_role: str, resource_level: int) -> bool:
    privileged = user_role in ADMIN_ROLES
    return privileged and resource_level >= 3
EOF

    cat > "$LAB_DIR/targets/firewall.py" << 'EOF'
BLOCKED_IPS   = {"10.0.0.1", "192.168.1.100"}
ALLOWED_PORTS = {80, 443, 8080}
def pkt_drop(src_ip: str, dst_port: int, routed_internal: bool) -> bool:
  return src_ip in BLOCKED_IPS or dst_port not in ALLOWED_PORTS and not routed_internal
EOF

    cat > "$LAB_DIR/targets/config.py" << 'EOF'
def db_connect(cfg: dict, acl: list = ["READ"]):
    if cfg.get("elevate"):
        acl.append("ADMIN")
    return establish_connection(cfg, acl)

def resolve_grants(role: str, extra_acl: list = []):
    policy = {"viewer": ["read"], "admin": ["read", "write", "delete"]}
    grants = policy.get(role, ["read"])
    grants.extend(extra_acl)
    return grants
EOF
fi

# Disponibiliza os nomes usados nos comandos das páginas 428 e 437-446.
mkdir -p "$LAB_DIR/rules" "$LAB_DIR/hooks"
for query in "$SCRIPT_DIR"/*.ql; do
    [ -f "$query" ] || continue
    dest="$LAB_DIR/queries/$(basename -- "$query")"
    [ -e "$dest" ] || cp -- "$query" "$dest"
done
for name in sem-smugg.yml sem-smugg_saida_p433.yml; do
    [ -e "$LAB_DIR/rules/$name" ] || cp -- "$SCRIPT_DIR/$name" "$LAB_DIR/rules/$name"
done
[ -e "$LAB_DIR/homoglyph_audit.py" ] || cp -- "$SCRIPT_DIR/homoglyph_audit.py" "$LAB_DIR/"
[ -e "$LAB_DIR/hooks/pre-commit" ] || cp -- "$SCRIPT_DIR/hooks/pre-commit" "$LAB_DIR/hooks/"

for name in validator.py firewall.py config.py; do
    [ -e "$LAB_DIR/targets/$name" ] || cp -- "$SCRIPT_DIR/$name" "$LAB_DIR/targets/$name"
done

cd "$LAB_DIR"

# 6. Compilação do Banco de Dados Relacional do Código-Alvo
echo -e "${BLUE}[*] Compilando o banco de dados CodeQL (smuggling-db)...${NC}"
if [ -d "smuggling-db" ]; then
    echo -e "${YELLOW}[!] Banco existente preservado. Para atualizá-lo, use codeql database create --overwrite.${NC}"
else
    codeql database create smuggling-db \
        --language=python \
        --source-root=./targets
fi

# 7. Inicialização do Manifesto de Queries Customizadas
echo -e "${BLUE}[*] Configurando o manifesto qlpack.yml para o laboratório...${NC}"
if [ ! -f queries/qlpack.yml ]; then
cat > queries/qlpack.yml << EOF
name: smuggling-lab/queries
version: 0.0.1
dependencies:
  codeql/python-all: "$PYTHON_ALL_VERSION"
EOF
fi

# Sincroniza e resolve as dependências do pacote local
echo -e "${BLUE}[*] Instalando dependências do pacote de queries customizadas...${NC}"
cd queries
if [ "${LIVRO3_PACKS_PRONTOS:-0}" != 1 ]; then
    codeql pack install
fi
cd ..

echo -e "${GREEN}[+] AMBIENTE PRONTO COM SUCESSO!${NC}"
echo -e "${YELLOW}[!] No seu terminal, acrescente $CODEQL_DIR/codeql ao PATH.${NC}"
echo -e "${BLUE}[*] Workspace localizado em: $LAB_DIR${NC}"
