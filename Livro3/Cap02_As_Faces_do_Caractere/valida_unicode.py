#!/usr/bin/env python3
"""
Unicode Validator - Detecta caracteres Unicode invisíveis e de formatação
Uso:
  python3 valida_unicode.py "string" ...
  echo "texto" | python3 valida_unicode.py -
  python3 valida_unicode.py -e
"""

import sys
import unicodedata
import argparse

# Cores ANSI para terminal
class Colors:
    RED    = '\033[91m'
    GREEN  = '\033[92m'
    YELLOW = '\033[93m'
    BLUE   = '\033[94m'
    BOLD   = '\033[1m'
    RESET  = '\033[0m'

#  DICIONÁRIO - chave: código Unicode (hex) | valor: descrição (string)
EXPLICIT_CP = {
    0x00A0: "NO-BREAK SPACE",
    0x00AD: "SOFT HYPHEN",
    0x180E: "MONGOLIAN VOWEL SEPARATOR",
    0x200B: "ZERO WIDTH SPACE",
    0x200C: "ZERO WIDTH NON-JOINER",
    0x200D: "ZERO WIDTH JOINER",
    0x200E: "LEFT-TO-RIGHT MARK",
    0x200F: "RIGHT-TO-LEFT MARK",
    0x202A: "LEFT-TO-RIGHT EMBEDDING",
    0x202B: "RIGHT-TO-LEFT EMBEDDING",
    0x202C: "POP DIRECTIONAL FORMATTING",
    0x202D: "LEFT-TO-RIGHT OVERRIDE",
    0x202E: "RIGHT-TO-LEFT OVERRIDE",
    0x2060: "WORD JOINER",
    0x202F: "NARROW NO-BREAK SPACE",
    0xFEFF: "BYTE ORDER MARK",
    0x1F6AC: "CIGARETTE (Maconheiro Detected)",
}

# Cache para evitar múltiplas chamadas ao unicodedata.name()
unicodedata_cache = {}

def get_char_name(ch):
    """Retorna o nome de um caractere Unicode com cache."""
    cp = ord(ch)
    if cp not in unicodedata_cache:
        try:
            unicodedata_cache[cp] = unicodedata.name(ch)
        except ValueError:
            unicodedata_cache[cp] = "<unknown>"
    return unicodedata_cache[cp]

def bytes_hex(s, verbose=False):
    """Retorna representação hexadecimal dos bytes UTF-8."""
    hex_str = ' '.join(f'{b:02x}' for b in s.encode('utf-8'))
    if verbose:
        byte_list = s.encode('utf-8')
        verbose_bytes = []
        for b in byte_list:
            if 32 <= b < 127:
                verbose_bytes.append(
                    f'{b:02x}({Colors.GREEN}{chr(b)}{Colors.RESET})')
            else:
                verbose_bytes.append(
                    f'{b:02x}({Colors.RED}?{Colors.RESET})')
        hex_str += '\nVerbose bytes: ' + ' '.join(verbose_bytes)
    return hex_str

def escape_unicode(s):
    """Retorna escapes Unicode como \\u200B ou \\U0001F600."""
    return s.encode('unicode_escape').decode('ascii')

def scan_string(s, label="<input>"):
    """Escaneia a string procurando caracteres suspeitos."""
    hits = []

    # Pré-cálculo de offsets UTF-8 para performance
    utf8_lengths = [len(ch.encode('utf-8')) for ch in s]
    cumulative_offsets = [
        sum(utf8_lengths[:i]) for i in range(len(utf8_lengths) + 1)
    ]

    for idx, ch in enumerate(s):
        cp  = ord(ch)
        cat = unicodedata.category(ch)

        # Skip precoce - não processa caracteres normais
        if (cp not in EXPLICIT_CP
                and cat != 'Cf'
                and not (0xD800 <= cp <= 0xDFFF)):
            continue

        byte_offset = cumulative_offsets[idx]
        name        = get_char_name(ch)

        if cp in EXPLICIT_CP:
            description = EXPLICIT_CP[cp]
        elif 0xD800 <= cp <= 0xDFFF:
            description = "INVALID_SURROGATE"
            name        = "<surrogate>"
        else:
            description = name

        # Capturar contexto: 10 caracteres ao redor
        start = max(0, idx - 10)
        end   = min(len(s), idx + 11)
        ctx   = s[start:end].replace("\n", "[NL]")

        hits.append({
            'index':       idx,
            'cp':          cp,
            'U':           f"U+{cp:04X}",
            'name':        name,
            'description': description,
            'cat':         cat,
            'context':     ctx,
            'byte_offset': byte_offset,
        })

    return hits

def report(s, label="<input>", verbose=False):
    """Imprime relatório sobre a string."""
    print("=" * 60)
    print(f"Input String: {label}")
    print(f"Visual: [{s}]")
    print(f"Escapes: {escape_unicode(s)}")
    print(f"UTF-8 (bytes): {bytes_hex(s, verbose)}")

    hits = scan_string(s, label)

    if not hits:
        print(f"{Colors.GREEN}No suspicious/invisible characters found."
              f"{Colors.RESET}")
        print()
        return

    print(f"{Colors.RED}{Colors.BOLD}"
          f"Found {len(hits)} suspicious char(s):{Colors.RESET}")
    for h in hits:
        ctx_display = (
            ' '.join(f'{ord(c):04x}' for c in h['context'])
            if verbose else h['context']
        )
        print(
            f"{Colors.RED} - idx={h['index']:3d} "
            f"byte_offset={h['byte_offset']:3d} "
            f"{h['U']} {h['description']} "
            f"(cat={h['cat']}){Colors.RESET}"
        )
        print(f"    context: ...{ctx_display}...")
    print()

EXAMPLES = [
    ("No-Break Space (NBSP)",               "p\u00A0ass\u00A0word"),
    ("Soft Hyphen (SHY)",                   "p\u00ADass\u00ADword"),
    ("Mongolian Vowel Separator (MVS)",     "mongolian\u180Etext\u180E"),
    ("Zero Width Space (ZWSP)",             "p\u200Bass\u200Bword"),
    ("Zero Width Non-Joiner (ZWNJ)",        "p\u200Cass\u200Cword"),
    ("Zero Width Joiner (ZWJ)",             "p\u200Dass\u200Dword"),
    ("LRM + RLM",                           "\u200Eabc\u200Fdef"),
    ("LRE + PDF",                           "abc\u202Adef\u202Cghi"),
    ("RLE + PDF",                           "abc\u202Bdef\u202Cghi"),
    ("LRO + PDF",                           "abc\u202Ddef\u202Cghi"),
    ("RLO + PDF (Trojan Source)",           "abc\u202Edef\u202Cghi"),
    ("Narrow No-Break Space (NNBSP)",       "p\u202Fass\u202Fword"),
    ("Word Joiner (WJ)",                    "p\u2060ass\u2060word"),
    ("Byte Order Mark (BOM)",               "pass\uFEFFword\uFEFF"),
    ("BOM no Início",                       "\uFEFFThis is a normal string"),
    ("Múltiplas Zero Width",                "p\u200B,\u200C,\u200Dword"),
    ("RLO Direction Override",              "\u202Eleft-to-right text"),
    ("Marcadores Direcionais (Mixed)",      "Arabic \u200F بدون\u200E"),
    ("BOM com Controle Oculto",             "\uFEFF\u200B,\u202E,test"),
    ("Maconheiro Detected",                 "fumar\U0001F6ACé\U0001F6ACbom"),
]

def main():
    p = argparse.ArgumentParser(
        description="Unicode invisible/format character validator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  python3 valida_unicode.py "seu texto aqui"
  python3 valida_unicode.py -e              (rodar todos os exemplos)
  python3 valida_unicode.py -e -v           (exemplos com verbose)
  echo "texto" | python3 valida_unicode.py - (ler de stdin)
""",
    )
    p.add_argument('inputs',    nargs='*',       help='Strings to scan; use - for stdin')
    p.add_argument('-e', '--examples', action='store_true', help='Run built-in examples')
    p.add_argument('-v', '--verbose',  action='store_true', help='Verbose mode')
    args = p.parse_args()

    if args.examples:
        print(f"\nRodando {len(EXAMPLES)} exemplos...\n")
        for name, ex in EXAMPLES:
            report(ex, label=name, verbose=args.verbose)
        return

    if not args.inputs:
        p.print_help()
        return

    for it in args.inputs:
        if it == '-':
            try:
                txt = sys.stdin.buffer.read().decode('utf-8', errors='replace')
            except Exception as e:
                print(f"Error reading stdin: {e}")
                return
            report(txt, "<stdin>", verbose=args.verbose)
        else:
            report(it, label=it, verbose=args.verbose)

if __name__ == "__main__":
    main()
