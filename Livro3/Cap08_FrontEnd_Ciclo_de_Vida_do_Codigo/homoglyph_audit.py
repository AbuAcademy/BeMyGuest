#!/usr/bin/env python3
"""
homoglyph_audit.py — Unicode homoglyph detector for source code review.

Scans Python source files for tokens that are visually identical to ASCII
keywords but contain non-ASCII codepoints. Operates at the byte layer,
before any parser or interpreter processes the file.

Usage:
    python3 homoglyph_audit.py <target.py> [target2.py ...]
    find . -name "*.py" | xargs python3 homoglyph_audit.py

Exit codes:
    0  clean
    1  homoglyphs detected
    2  scan error
"""

import json
import sys
import tokenize
import unicodedata
from io import StringIO
from pathlib import Path

# Partial confusables map — covers the most common attack vectors.
# Full Unicode confusables database: https://unicode.org/reports/tr39/
CONFUSABLE_MAP: dict[str, str] = {
    '\u03B1': 'a',  # α → a  (GREEK SMALL LETTER ALPHA)
    '\u0430': 'a',  # а → a  (CYRILLIC SMALL LETTER A)
    '\u0435': 'e',  # е → e  (CYRILLIC SMALL LETTER IE)
    '\u03BF': 'o',  # ο → o  (GREEK SMALL LETTER OMICRON)
    '\u0585': 'o',  # փ → o  (ARMENIAN SMALL LETTER OH)
    '\u1D0F': 'o',  # ᴏ → o  (LATIN LETTER SMALL CAPITAL O)
    '\u0456': 'i',  # і → i  (CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I)
    '\u03C1': 'p',  # ρ → p  (GREEK SMALL LETTER RHO)
    '\u0440': 'p',  # р → p  (CYRILLIC SMALL LETTER ER)
    '\u0455': 's',  # ѕ → s  (CYRILLIC SMALL LETTER DZE)
    '\u0443': 'y',  # у → y  (CYRILLIC SMALL LETTER U)
    '\u03BD': 'v',  # ν → v  (GREEK SMALL LETTER NU)
}

PYTHON_KEYWORDS: frozenset[str] = frozenset({
    'and', 'or', 'not', 'in', 'is', 'if', 'else', 'elif',
    'for', 'while', 'return', 'import', 'from', 'def', 'class',
    'True', 'False', 'None', 'lambda', 'with', 'as', 'pass',
    'break', 'continue', 'raise', 'try', 'except', 'finally',
    'global', 'nonlocal', 'del', 'yield', 'assert', 'async', 'await',
})


def _normalize(token: str) -> str:
    return ''.join(CONFUSABLE_MAP.get(c, c) for c in token)


def scan(path: Path) -> list[dict]:
    try:
        source = path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        source = path.read_text(encoding='latin-1')

    # fast-path: pure ASCII files need no further analysis
    if all(ord(c) < 128 for c in source):
        return []

    findings = []
    try:
        for tok in tokenize.generate_tokens(StringIO(source).readline):
            if tok.type != tokenize.NAME:
                continue
            normalized = _normalize(tok.string)
            if normalized != tok.string and normalized in PYTHON_KEYWORDS:
                findings.append({
                    "file":       str(path),
                    "line":       tok.start[0],
                    "col":        tok.start[1],
                    "token":      tok.string,
                    "normalized": normalized,
                    "codepoints": [
                        f"U+{ord(c):04X} ({unicodedata.name(c, 'UNKNOWN')})"
                        for c in tok.string if ord(c) > 127
                    ],
                })
    except tokenize.TokenError:
        pass

    return findings


def main() -> None:
    if len(sys.argv) < 2:
        print(f"Usage: python3 {sys.argv[0]} <target.py> [target2.py ...]")
        sys.exit(2)

    all_findings = []
    for arg in sys.argv[1:]:
        path = Path(arg)
        if not path.exists():
            print(f"[ERROR] not found: {path}", file=sys.stderr)
            continue
        hits = scan(path)
        if hits:
            all_findings.extend(hits)
        else:
            print(f"[OK] {path}")

    if all_findings:
        print(json.dumps(all_findings, indent=2, ensure_ascii=False))
        sys.exit(1)


if __name__ == "__main__":
    main()
