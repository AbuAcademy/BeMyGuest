"""
Security Engine: AST-based Evasion Detector (v3.0)
Tree-Sitter 0.25.x

Mini-SAST demonstrativo focado em:
- evasão via reflexão;
- exfiltração de dados;
- acesso a segredos em ambiente;
- execução automática durante import.
"""

import json
import logging
import sys
import tokenize

from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
from typing import Dict, List, Final, Mapping, Any, Tuple

import tree_sitter_python as tspython

from tree_sitter import (
    Language,
    Parser,
    Tree,
    Query,
    QueryCursor
)


LOG_FORMAT: Final = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

logging.basicConfig(
    level=logging.INFO,
    format=LOG_FORMAT
)

logger = logging.getLogger("ASTAuditor")


PY_LANGUAGE: Final = Language(
    tspython.language()
)


SECURITY_POLICIES: Final[Mapping[str, str]] = {

    "SUSPICIOUS_DYNAMIC_ACCESS": r"""
        (
            call
                function:
                    (identifier) @function
        )

        (
            call
                function:
                    (
                        attribute
                            attribute:
                                (identifier) @method
                    )
        )
    """,

    "MODULE_LEVEL_SIDE_EFFECTS": r"""
        (
            module
                (expression_statement
                    (call) @call)
        )
    """,

    "DEFERRED_IMPORT": r"""
        (
            function_definition
                body:
                    (block
                        (import_statement) @imp)
        )
    """,

    "SUPPLY_CHAIN_LEAK": r"""
        (
            attribute
                object:
                    (identifier) @object

                attribute:
                    (identifier) @attribute
        ) @env_access
    """
}


class ASTAuditor:

    def __init__(self, target_path: str) -> None:

        self.target_path: Final = Path(target_path)

        self.parser: Final = Parser(
            PY_LANGUAGE
        )


    def _get_tree_and_source(self) -> Tuple[Tree, bytes]:

        source = self.target_path.read_bytes()

        return (
            self.parser.parse(source),
            source
        )


    def run_security_audit(self) -> Dict[str, List[str]]:

        tree, source = self._get_tree_and_source()

        encoding, _ = tokenize.detect_encoding(
            BytesIO(source).readline
        )

        violations = {}

        for rule_id, query_text in SECURITY_POLICIES.items():

            findings = self._execute_query(
                tree,
                source,
                query_text,
                encoding,
                rule_id
            )

            if findings:
                violations[rule_id] = findings

        return violations


    def _execute_query(
        self,
        tree: Tree,
        source: bytes,
        query_str: str,
        encoding: str,
        rule_id: str
    ) -> List[str]:

        query = Query(
            PY_LANGUAGE,
            query_str
        )

        cursor = QueryCursor(query)

        captures = cursor.captures(
            tree.root_node
        )


        if rule_id == "SUSPICIOUS_DYNAMIC_ACCESS":

            return self._check_dynamic_access(
                captures,
                source,
                encoding
            )


        if rule_id == "SUPPLY_CHAIN_LEAK":

            return self._check_environment_access(
                captures,
                source,
                encoding
            )


        results = []

        for tag_name, nodes in captures.items():

            for node in nodes:

                line = node.start_point.row + 1

                snippet = source[
                    node.start_byte:node.end_byte
                ].decode(
                    encoding,
                    errors="replace"
                )

                results.append(
                    f"[@{tag_name}] L{line}: {snippet.strip()}"
                )

        return results

    def _check_dynamic_access(
        self,
        captures,
        source: bytes,
        encoding: str
    ) -> List[str]:

        dangerous_functions = {
            "__import__",
            "eval",
            "exec",
            "getattr"
        }

        dangerous_methods = {
            "sendall",
            "sendto",
            "connect",
            "create_connection",
            "Popen",
            "system",
            "spawn",
            "run"
        }

        findings = []

        for tag_name, nodes in captures.items():

            for node in nodes:

                name = source[
                    node.start_byte:node.end_byte
                ].decode(
                    encoding,
                    errors="replace"
                )

                if tag_name == "function":

                    if name not in dangerous_functions:
                        continue

                elif tag_name == "method":

                    if name not in dangerous_methods:
                        continue

                else:
                    continue

                line = node.start_point.row + 1

                findings.append(
                    f"L{line}: {name}"
                )

        return findings


    def _check_environment_access(
        self,
        captures,
        source: bytes,
        encoding: str
    ) -> List[str]:

        findings = []
        seen = set()

        for nodes in captures.values():

            for node in nodes:

                if node.type != "attribute":
                    continue

                obj = node.child_by_field_name(
                    "object"
                )

                attr = node.child_by_field_name(
                    "attribute"
                )

                if not obj or not attr:
                    continue

                object_name = source[
                    obj.start_byte:obj.end_byte
                ].decode(
                    encoding,
                    errors="replace"
                )

                attribute_name = source[
                    attr.start_byte:attr.end_byte
                ].decode(
                    encoding,
                    errors="replace"
                )

                if (
                    object_name == "os"
                    and attribute_name == "environ"
                ):

                    line = node.start_point.row + 1

                    snippet = source[
                        node.start_byte:node.end_byte
                    ].decode(
                        encoding,
                        errors="replace"
                    )

                    finding = f"L{line}: {snippet}"

                    if finding not in seen:
                        findings.append(
                            finding
                        )

                        seen.add(
                            finding
                        )

        return findings


def generate_report(
    target_path: Path,
    report_data: Dict[str, Any]
) -> None:

    output_path = target_path.with_suffix(
        ".security.json"
    )

    payload = {

        "metadata": {

            "timestamp": datetime.now(
                timezone.utc
            ).isoformat(),

            "target": str(
                target_path
            ),

            "engine_version": "3.0.0"
        },

        "findings": report_data
    }

    with output_path.open(
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            payload,
            file,
            indent=2,
            ensure_ascii=False
        )

    logger.info(
        "Relatório gerado em: %s",
        output_path
    )


def main() -> None:

    if len(sys.argv) < 2:

        logger.error(
            "Uso: python scanner_ts_v3.py <arquivo.py>"
        )

        sys.exit(1)

    auditor = ASTAuditor(
        sys.argv[1]
    )

    findings = auditor.run_security_audit()

    if findings:

        logger.warning(
            "VULNERABILIDADES DETECTADAS!"
        )

        print(
            json.dumps(
                findings,
                indent=4,
                ensure_ascii=False
            )
        )

        generate_report(
            auditor.target_path,
            findings
        )

        sys.exit(1)

    logger.info(
        "Check Passed: %s",
        sys.argv[1]
    )


if __name__ == "__main__":
    main()
