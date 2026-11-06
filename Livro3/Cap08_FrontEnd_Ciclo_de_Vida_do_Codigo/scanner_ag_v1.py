# scanner_ag_v1.py
"""
Semantic Triage Engine — behavioral enrichment layer over static AST analysis.

Executes deterministic Tree-sitter rule matches, then drives an LLM reasoning
loop to contextualize findings, generate and execute structural follow-up
probes, and emit a final SARIF-compatible classification.

Intended for integration into CI/CD gates and pre-merge security pipelines.
Output format defaults to SARIF 2.1.0; use --format=text for human review.

SETUP:
    pip install openai anthropic tree-sitter tree-sitter-python

    Local backend (Ollama) — no data leaves the machine, recommended for
    sensitive or potentially malicious code. Install: https://ollama.com

        4GB  RAM:  ollama pull qwen3.5:0.6b  (lightweight, fast)
        8GB  RAM:  ollama pull qwen3.5:4b    (balanced)
        16GB RAM:  ollama pull qwen3.5:9b    (recommended)
        32GB+ RAM: ollama pull qwen3-coder-next:30b  (expert agent)

    Cloud backend (Anthropic) — stronger reasoning on complex obfuscation,
    sends code to external infrastructure. Review your threat model before
    enabling in sensitive environments. Docs: https://console.anthropic.com

        export ANTHROPIC_API_KEY="sk-ant-..."   # add to ~/.bashrc or ~/.zshrc
        # script reads it automatically via anthropic.Anthropic()

Usage:
    python3 scanner_ag_v1.py <target.py> [--format=sarif|text] [--backend=ollama|anthropic] [--model=<model>] [--verbose]

Exit codes:
    0  clean
    1  findings with severity >= HIGH
    2  engine error
"""

import argparse
import json
import logging
import sys
import textwrap
import tokenize
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
from typing import Any, Protocol

import tree_sitter_python as tspython
from tree_sitter import Language, Parser, Query, QueryCursor

log = logging.getLogger("scanner_ag")

PY_LANGUAGE = Language(tspython.language())

SEVERITY_RANK = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1, "CLEAN": 0}

# ---------------------------------------------------------------------------
# Rule set — ATT&CK-mapped
# ---------------------------------------------------------------------------
RULE_SET: dict[str, str] = {
    "T1059.006/dynamic-invocation": """
        (call function: (identifier) @f (#match? @f "^(getattr|eval|exec|__import__)$"))
        (call function: (attribute attribute: (identifier) @d) (#match? @d "^(b64decode|unhexlify)$"))
    """,
    "T1546.016/module-import-side-effect": """
        (module (expression_statement (call) @c))
    """,
    "T1552.001/env-credential-access": """
        (attribute
            object: (identifier) @obj (#eq? @obj "os")
            attribute: (identifier) @attr (#eq? @attr "environ")
        ) @env_access
        ((identifier) @env_direct (#eq? @env_direct "environ"))
    """,
}

# ---------------------------------------------------------------------------
# Backend abstraction
# ---------------------------------------------------------------------------
class LLMBackend(Protocol):
    def complete(self, system: str, user: str) -> str: ...


class OllamaBackend:
    """
    Local inference via Ollama. No data leaves the machine.
    Preferred backend for analysis of sensitive or malicious code.
    """
    def __init__(self, model: str = "qwen3.5:0.6b", base_url: str = "http://localhost:11434", timeout: int = 300):
        try:
            from openai import OpenAI
            self._client = OpenAI(base_url=f"{base_url}/v1", api_key="ollama", timeout=timeout)
        except ImportError:
            _die("openai package required for Ollama backend: pip install openai")
        self.model = model

    def complete(self, system: str, user: str) -> str:
        resp = self._client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        )
        return resp.choices[0].message.content.strip()


class AnthropicBackend:
    """
    Anthropic API backend. Stronger reasoning on complex obfuscation chains.
    Requires ANTHROPIC_API_KEY. Sends code to external infrastructure.
    """
    def __init__(self, model: str = "claude-sonnet-4-6"):
        try:
            import anthropic
            self._client = anthropic.Anthropic()
        except ImportError:
            _die("anthropic package required: pip install anthropic")
        self.model = model

    def complete(self, system: str, user: str) -> str:
        import anthropic
        resp = self._client.messages.create(
            model=self.model,
            max_tokens=1024,
            system=system,
            messages=[{"role": "user", "content": user}],
        )
        return resp.content[0].text.strip()


def _die(msg: str) -> None:
    log.error(msg)
    sys.exit(2)


def _parse_json(raw: str) -> dict[str, Any]:
    # qwen3.x emits <think>...</think> before the JSON payload when
    # chain-of-thought is enabled — strip it before attempting to parse.
    import re
    raw = re.sub(r"<think>.*?</think>", "", raw, flags=re.DOTALL).strip()
    clean = raw.lstrip("```json").lstrip("```").rstrip("```").strip()
    # if multiple JSON objects slipped through, take only the first
    try:
        return json.loads(clean)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", clean, re.DOTALL)
        if match:
            return json.loads(match.group())
        raise


# ---------------------------------------------------------------------------
# Phase 1 — deterministic rule match
# ---------------------------------------------------------------------------
def match_ruleset(source: bytes, enc: str) -> dict[str, list[dict[str, Any]]]:
    parser = Parser(PY_LANGUAGE)
    tree = parser.parse(source)
    hits: dict[str, list[dict[str, Any]]] = {}

    for rule_id, query_str in RULE_SET.items():
        query = Query(PY_LANGUAGE, query_str)
        cursor = QueryCursor(query)
        captures = cursor.captures(tree.root_node)

        matches: list[dict[str, Any]] = []
        for tag, nodes in captures.items():
            for node in nodes:
                snippet = (
                    source[node.start_byte : node.end_byte]
                    .decode(enc, "replace")
                    .strip()
                )
                matches.append({
                    "line": node.start_point.row + 1,
                    "col": node.start_point.column,
                    "capture": tag,
                    "snippet": snippet,
                })

        if matches:
            hits[rule_id] = sorted(
                list({json.dumps(m, sort_keys=True): m for m in matches}.values()),
                key=lambda m: m["line"],
            )

    return hits


# ---------------------------------------------------------------------------
# Phase 2 — behavioral enrichment
# ---------------------------------------------------------------------------
_ENRICH_SCHEMA = {
    "hypothesis": "string — behavioral pattern inferred from the combined hits",
    "attacker_goal": "string — what the code is trying to accomplish",
    "probe_query": "string — tree-sitter S-expression to structurally trace the suspected data flow; no predicates",
}

_ENRICH_SYSTEM = textwrap.dedent("""\
    You are a malware analyst reviewing static AST hits from a supply-chain \
    security scanner. Rule IDs follow ATT&CK notation.

    Given the hits below, produce a concise behavioral enrichment.
    Reply with valid JSON only — no markdown fences, no prose outside the object.
    Schema: {schema}
""").format(schema=json.dumps(_ENRICH_SCHEMA))


def enrich(backend: LLMBackend, hits: dict[str, list[dict]]) -> dict[str, Any]:
    raw = backend.complete(_ENRICH_SYSTEM, json.dumps(hits, ensure_ascii=False))
    return _parse_json(raw)


# ---------------------------------------------------------------------------
# Phase 3 — structural probe
# ---------------------------------------------------------------------------
def trace(source: bytes, enc: str, query_str: str) -> list[dict[str, Any]]:
    parser = Parser(PY_LANGUAGE)
    tree = parser.parse(source)

    try:
        query = Query(PY_LANGUAGE, query_str)
    except Exception as exc:
        log.warning("probe query rejected by tree-sitter: %s", exc)
        return [{"error": str(exc)}]

    cursor = QueryCursor(query)
    captures = cursor.captures(tree.root_node)

    results: list[dict[str, Any]] = []
    for tag, nodes in captures.items():
        for node in nodes:
            snippet = (
                source[node.start_byte : node.end_byte]
                .decode(enc, "replace")
                .strip()
            )
            results.append({
                "line": node.start_point.row + 1,
                "capture": tag,
                "snippet": snippet,
            })

    return sorted(
        list({json.dumps(r, sort_keys=True): r for r in results}.values()),
        key=lambda r: r.get("line", 0),
    )


# ---------------------------------------------------------------------------
# Phase 4 — classification
# ---------------------------------------------------------------------------
_CLASSIFY_SCHEMA = {
    "severity": "CRITICAL | HIGH | MEDIUM | LOW | CLEAN",
    "mitre_techniques": ["T1059.006", "..."],
    "classification": "string — one-line threat category",
    "attack_chain": "string — 2-3 sentence narrative of the full chain",
    "iocs": ["string — concrete indicator from the evidence"],
}

_CLASSIFY_SYSTEM = textwrap.dedent("""\
    You are a threat intelligence analyst issuing a final classification.
    You will receive: initial rule hits, behavioral enrichment, and structural \
    probe results. Synthesize all evidence into a classification.

    Reply with valid JSON only — no markdown fences, no prose outside the object.
    Schema: {schema}
""").format(schema=json.dumps(_CLASSIFY_SCHEMA))


def classify(
    backend: LLMBackend,
    hits: dict[str, list[dict]],
    enrichment: dict[str, Any],
    probe_hits: list[dict[str, Any]],
) -> dict[str, Any]:
    payload = {
        "rule_hits": hits,
        "enrichment": enrichment,
        "probe_evidence": probe_hits,
    }
    raw = backend.complete(_CLASSIFY_SYSTEM, json.dumps(payload, ensure_ascii=False))
    return _parse_json(raw)


# ---------------------------------------------------------------------------
# SARIF 2.1.0 emitter
# ---------------------------------------------------------------------------
def emit_sarif(
    target: Path,
    hits: dict[str, list[dict]],
    classification: dict[str, Any],
) -> dict[str, Any]:
    sev = classification.get("severity", "CLEAN")
    level = "error" if SEVERITY_RANK.get(sev, 0) >= 3 else "warning"

    results = []
    for rule_id, matches in hits.items():
        for m in matches:
            results.append({
                "ruleId": rule_id,
                "level": level,
                "message": {"text": m["snippet"]},
                "locations": [{
                    "physicalLocation": {
                        "artifactLocation": {"uri": str(target)},
                        "region": {
                            "startLine": m["line"],
                            "startColumn": m.get("col", 0) + 1,
                        },
                    }
                }],
                "properties": {"capture": m["capture"]},
            })

    return {
        "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [{
            "tool": {
                "driver": {
                    "name": "scanner_ag_v1",
                    "version": "0.3.0",
                    "rules": [
                        {"id": rid, "name": rid.split("/")[-1]}
                        for rid in RULE_SET
                    ],
                }
            },
            "results": results,
            "properties": {
                "classification": classification,
                "analysisTimestamp": datetime.now(timezone.utc).isoformat(),
            },
        }],
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="scanner_ag_v1",
        description="Semantic triage: AST rule match + LLM behavioral enrichment.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""\
            backends:
              ollama      Local inference, no data leaves the machine (default)
                          4GB  RAM : ollama pull qwen3.5:0.6b  (fast)
                          8GB  RAM : ollama pull qwen3.5:4b
                          16GB RAM : ollama pull qwen3.5:9b   (default)
                          32GB RAM : ollama pull qwen3-coder-next:30b
              anthropic   Anthropic API, stronger reasoning on complex obfuscation
                          Requires: ANTHROPIC_API_KEY env var (paid)
                          NOTE: source code is sent to external infrastructure
        """),
    )
    p.add_argument("target", help="Python source file to analyze")
    p.add_argument(
        "--format",
        choices=["sarif", "text"],
        default="sarif",
        dest="fmt",
        help="Output format (default: sarif)",
    )
    p.add_argument(
        "--backend",
        choices=["ollama", "anthropic"],
        default="ollama",
        help="LLM backend (default: ollama)",
    )
    p.add_argument(
        "--model",
        default=None,
        help="Override default model for the selected backend",
    )
    p.add_argument("--verbose", action="store_true", help="Enable debug logging")
    return p


def main() -> None:
    args = build_parser().parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    target = Path(args.target)
    if not target.exists():
        log.error("target not found: %s", target)
        sys.exit(2)

    source = target.read_bytes()
    try:
        enc, _ = tokenize.detect_encoding(BytesIO(source).readline)
    except Exception:
        enc = "utf-8"

    # backend selection
    if args.backend == "anthropic":
        print(
            "WARNING: anthropic backend selected — source code will be sent to external infrastructure",
            file=sys.stderr,
        )
        backend: LLMBackend = AnthropicBackend(
            model=args.model or "claude-sonnet-4-6"
        )
    else:
        backend = OllamaBackend(model=args.model or "qwen3.5:0.6b")

    # Phase 1
    log.debug("running rule set against %s", target)
    hits = match_ruleset(source, enc)
    if not hits:
        out = emit_sarif(target, {}, {"severity": "CLEAN"}) if args.fmt == "sarif" else {"result": f"CLEAN {target}"}
        print(json.dumps(out, indent=2))
        sys.exit(0)

    # Phase 2
    log.debug("enriching %d rule hits", sum(len(v) for v in hits.values()))
    enrichment = enrich(backend, hits)

    # Phase 3
    log.debug("running structural probe: %s", enrichment.get("probe_query", ""))
    probe_hits = trace(source, enc, enrichment.get("probe_query", ""))

    # Phase 4
    log.debug("issuing final classification")
    result = classify(backend, hits, enrichment, probe_hits)

    # output
    if args.fmt == "sarif":
        print(json.dumps(emit_sarif(target, hits, result), indent=2, ensure_ascii=False))
    else:
        sev = result.get("severity", "UNKNOWN")
        print(f"\nseverity       : {sev}")
        print(f"classification : {result.get('classification', '')}")
        print(f"mitre          : {', '.join(result.get('mitre_techniques', []))}")
        print(f"\nattack chain:\n{textwrap.indent(result.get('attack_chain', ''), '  ')}")
        print(f"\niocs:")
        for ioc in result.get("iocs", []):
            print(f"  - {ioc}")
        print()

    sys.exit(1 if SEVERITY_RANK.get(result.get("severity", "CLEAN"), 0) >= 3 else 0)


if __name__ == "__main__":
    main()
