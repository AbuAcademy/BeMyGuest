"""
Security Engine: AST-based Evasion Detector (v4.3 - Tree-Sitter 0.25.2)
Focado em identificar intenções de execução maliciosa ignorando ofuscação de nomes.
"""

import json
import logging
import sys
import tokenize
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
from typing import Dict, List, Final, Mapping, Any

import tree_sitter_python as tspython
from tree_sitter import Language, Parser, Tree, Query, QueryCursor

LOG_FORMAT: Final = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger("ASTAuditor")

PY_LANGUAGE: Final = Language(tspython.language())

# Políticas de segurança (Formatadas para margens de livros 17x24)
SECURITY_POLICIES: Final[Mapping[str, str]] = {
    "SUSPICIOUS_DYNAMIC_ACCESS": """
        (call function: (identifier) @builtin 
          (#match? @builtin "^(getattr|eval|exec|__import__)$"))
        (call function: (attribute attribute: (identifier) @decoder) 
          (#match? @decoder "^(b64decode|unhexlify)$"))
    """,
    "MODULE_LEVEL_SIDE_EFFECTS": """
        (module (expression_statement (call) @call))
    """,
    "DEFERRED_IMPORT": """
        (function_definition body: (block (import_statement) @imp))
    """
}

class ASTAuditor:
    def __init__(self, target_path: str) -> None:
        self.target_path: Final = Path(target_path)
        self.parser: Final = Parser(PY_LANGUAGE)

    def _get_tree_and_source(self) -> tuple[Tree, bytes]:
        try:
            source = self.target_path.read_bytes()
            return self.parser.parse(source), source
        except (FileNotFoundError, PermissionError) as e:
            logger.error("Erro de IO no arquivo %s: %s", self.target_path, e)
            raise

    def run_security_audit(self) -> Dict[str, List[str]]:
        tree, source = self._get_tree_and_source()
        encoding, _ = tokenize.detect_encoding(BytesIO(source).readline)
        
        violations = {}
        for rule_id, query_text in SECURITY_POLICIES.items():
            findings = self._execute_query(tree, source, query_text, encoding)
            if findings:
                violations[rule_id] = findings
        return violations

    def _execute_query(self, tree: Tree, source: bytes, query_str: str, encoding: str) -> List[str]:
        query = Query(PY_LANGUAGE, query_str)
        cursor = QueryCursor(query)
        captures_dict = cursor.captures(tree.root_node)
        
        results = []
        for tag_name, nodes in captures_dict.items():
            for node in nodes:
                line_num = node.start_point.row + 1
                code_snippet = source[node.start_byte:node.end_byte].decode(encoding, errors='replace')
                results.append(f"[@{tag_name}] L{line_num}: {code_snippet.strip()}")
        return results

def generate_report(target_path: Path, report_data: Dict[str, Any]) -> None:
    output_path = target_path.with_suffix(".security.json")
    payload = {
        "metadata": {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "target": str(target_path),
            "engine_version": "4.3.0-staff"
        },
        "findings": report_data
    }
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
    logger.info("Relatório gerado em: %s", output_path)

def main() -> None:
    if len(sys.argv) < 2:
        logger.error("Uso: python scanner_ts_v4.py <alvo.py>")
        sys.exit(1)

    auditor = ASTAuditor(sys.argv[1])
    findings = auditor.run_security_audit()
    
    if findings:
        logger.warning("VULNERABILIDADES DETECTADAS!")
        print(json.dumps(findings, indent=4, ensure_ascii=False))
        generate_report(auditor.target_path, findings)
        sys.exit(1)
        
    logger.info("Check Passed: %s", sys.argv[1])

if __name__ == "__main__":
    main()
