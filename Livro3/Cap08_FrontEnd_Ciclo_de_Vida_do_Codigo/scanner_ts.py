# scanner_ts.py — Detector de padrões maliciosos usando tree-sitter v0.25.2
import sys
import logging
from pathlib import Path
from typing import List, Dict, Tuple
from tree_sitter import Language, Parser, Query, QueryCursor, Node
import tree_sitter_python as tspython

# Configuração minimalista e profissional de logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger("SAST")

# Inicialização global da linguagem e do motor de parsing
PY_LANGUAGE = Language(tspython.language())
GLOBAL_PARSER = Parser(PY_LANGUAGE)

# --- POLÍTICAS DE AUDITORIA ESTRUTURAL (S-EXPRESSIONS) ---
SECURITY_POLICIES: Dict[str, str] = {
    "Rede dentro de função privada": """
    (function_definition
      name: (identifier) @fn_name (#match? @fn_name "^_")
      body: (block
        (expression_statement
          (call
            function: (attribute
              object: (identifier)
              attribute: (identifier) @method (#match? @method "^(create_connection|connect|sendall|recv)$"))))))
    """,
    
    "Import tardio (evasão)": """
    (function_definition
      body: (block
        (import_statement) @late_import))
    """,
    
    "Efeito colateral no import do módulo": """
    (module
      (expression_statement
        (call
          function: (identifier) @called_fn (#match? @called_fn "^_"))))
    """
}

def audit_source_node(node: Node, source: bytes, query_str: str) -> List[Tuple[int, str, str]]:
    """Executa uma query AST e retorna uma lista de tuplas (linha, texto, tag)."""
    query = Query(PY_LANGUAGE, query_str)
    cursor = QueryCursor(query)
    
    # v0.25.2 retorna um Dict[str, List[Node]]
    captures_dict = cursor.captures(node)
    findings = []
    
    for tag_name, nodes_list in captures_dict.items():
        for captured_node in nodes_list:
            line_number = captured_node.start_point.row + 1
            raw_text = source[captured_node.start_byte:captured_node.end_byte].decode(errors='replace')
            findings.append((line_number, raw_text, tag_name))
        
    return findings

def audit_target_file(filepath: str) -> None:
    """Carrega o arquivo alvo na memória e aplica a matriz de políticas SAST."""
    target_path = Path(filepath)
    if not target_path.is_file():
        logger.error(f"Arquivo não encontrado ou inválido: {filepath}")
        return

    source_bytes = target_path.read_bytes()
    tree = GLOBAL_PARSER.parse(source_bytes)
    root = tree.root_node

    for category, query_expression in SECURITY_POLICIES.items():
        matches = audit_source_node(root, source_bytes, query_expression)
        
        if matches:
            print(f"\n[ALERTA] {category}")
            seen = set()
            for line, text, _ in matches:
                display_text = text.replace('\n', ' ').strip()
                if (line, display_text) not in seen:
                    print(f"  linha {line}: {display_text!r}")
                    seen.add((line, display_text))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 scanner_ts.py <arquivo.py>")
        sys.exit(1)
        
    audit_target_file(sys.argv[1])
