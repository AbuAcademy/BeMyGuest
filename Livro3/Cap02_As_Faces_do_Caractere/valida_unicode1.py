#!/usr/bin/env python3
"""
Unicode Validator - Detecta caracteres Unicode invisíveis e de formatação
Uso:
  python3 valida_unicode1.py "string" ...
  echo "texto" | python3 valida_unicode1.py -
  python3 valida_unicode1.py --examples
  python3 valida_unicode1.py --deep "string"    (modo profundo - mais detecções)
"""

import sys
import unicodedata
import argparse

# Cores ANSI para terminal
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

# Lista explícita de codepoints "suspeitos" adicionais (spaces & historical)
# ⚠️ DICIONÁRIO - chave: código Unicode (hex) | valor: descrição (string)
EXPLICIT_CP = {
    0x00A0: "NO-BREAK SPACE",              # NBSP - espaço que não quebra em nova linha
    0x00AD: "SOFT HYPHEN",                 # SHY - hífen suave, invisível até quebra de linha
    0x180E: "MONGOLIAN VOWEL SEPARATOR",   # MVS - separador de vogais mongol (histórico)
    0x200B: "ZERO WIDTH SPACE",            # ZWSP - espaço invisível
    0x200C: "ZERO WIDTH NON-JOINER",       # ZWNJ - não conecta caracteres em scripts complexos
    0x200D: "ZERO WIDTH JOINER",           # ZWJ - conecta caracteres (usado em emojis)
    0x200E: "LEFT-TO-RIGHT MARK",          # LRM - marca direção de texto da esquerda
    0x200F: "RIGHT-TO-LEFT MARK",          # RLM - marca direção de texto da direita
    0x202A: "LEFT-TO-RIGHT EMBEDDING",     # LRE - embutir texto esquerda-direita
    0x202B: "RIGHT-TO-LEFT EMBEDDING",     # RLE - embutir texto direita-esquerda
    0x202C: "POP DIRECTIONAL FORMATTING",  # PDF - parar formatação de direção
    0x202D: "LEFT-TO-RIGHT OVERRIDE",      # LRO - sobrescrever com direção esquerda-direita
    0x202E: "RIGHT-TO-LEFT OVERRIDE",      # RLO - sobrescrever com direção direita-esquerda (Trojan Source)
    0x2060: "WORD JOINER",                 # WJ - impede quebra de palavras
    0x202F: "NARROW NO-BREAK SPACE",       # NNBSP - espaço estreito que não quebra
    0xFEFF: "BYTE ORDER MARK"              # BOM / ZERO WIDTH NO-BREAK SPACE
}

# Lista expandida para --deep (Best-Fit Mapping e outros)
EXPLICIT_CP_DEEP = {
    **EXPLICIT_CP,
    # Best-Fit Mapping (CVE-2024-4577 e relacionados)
    0xFFE5: "FULLWIDTH YEN SIGN",          # ￥ - pode ser convertido para \ em Best-Fit
    0xFF3C: "FULLWIDTH REVERSE SOLIDUS",   # ￼ - fullwidth backslash
    0xFF0F: "FULLWIDTH SOLIDUS",           # ／ - fullwidth forward slash
    0xFF0E: "FULLWIDTH FULL STOP",         # ． - fullwidth period
    # Caracteres de Isolamento
    0x2066: "LEFT-TO-RIGHT ISOLATE",       # LRI
    0x2067: "RIGHT-TO-LEFT ISOLATE",       # RLI
    0x2068: "FIRST STRONG ISOLATE",        # FSI
    0x2069: "POP DIRECTIONAL ISOLATE",     # PDI
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
                # Caractere printável - em verde
                verbose_bytes.append(f'{b:02x}({Colors.GREEN}{chr(b)}{Colors.RESET})')
            else:
                # Caractere não-printável - em vermelho com ?
                verbose_bytes.append(f'{b:02x}({Colors.RED}?{Colors.RESET})')
        hex_str += '\nVerbose bytes: ' + ' '.join(verbose_bytes)
    return hex_str

def escape_unicode_repr(s):
    """Retorna escapes Unicode como \\u200B ou \\U0001F600."""
    return s.encode('unicode_escape').decode('ascii')

def scan_string(s, label="<input>", deep=False):
    """Escaneia a string procurando caracteres suspeitos."""
    hits = []
    
    # Escolher lista de caracteres baseado no modo
    explicit_cp = EXPLICIT_CP_DEEP if deep else EXPLICIT_CP
    
    # Pré-cálculo de offsets UTF-8 para performance
    utf8_lengths = [len(ch.encode('utf-8')) for ch in s]
    cumulative_offsets = [sum(utf8_lengths[:i]) for i in range(len(utf8_lengths) + 1)]
    
    for idx, ch in enumerate(s):
        cp = ord(ch)
        cat = unicodedata.category(ch)
        
        # Skip precoce - não processa caracteres normais
        if cp not in explicit_cp and cat != 'Cf' and not (0xD800 <= cp <= 0xDFFF):
            continue
        
        byte_offset = cumulative_offsets[idx]
        name = get_char_name(ch)
        
        # Determinar descrição do caractere
        if cp in explicit_cp:
            description = explicit_cp[cp]
        elif 0xD800 <= cp <= 0xDFFF:
            description = "INVALID_SURROGATE"
            name = "<surrogate>"
        else:
            description = name
        
        # Capturar contexto: 10 caracteres ao redor
        start = max(0, idx - 10)
        end = min(len(s), idx + 11)
        ctx = s[start:end].replace("\n", "[NL]")
        
        hits.append({
            'index': idx,
            'cp': cp,
            'U': f"U+{cp:04X}",
            'name': name,
            'description': description,
            'cat': cat,
            'context': ctx,
            'byte_offset': byte_offset
        })
    
    return hits

def report(s, label="<input>", verbose=False, deep=False):
    """Imprime relatório sobre a string."""
    mode_indicator = " [MODO DEEP]" if deep else ""
    print("=" * 60)
    print(f"Input label: {label}{mode_indicator}")
    print(f"Visual: [{s}]")
    print(f"Escapes: {escape_unicode_repr(s)}")
    print(f"UTF-8 (bytes): {bytes_hex(s, verbose)}")
    
    hits = scan_string(s, label, deep)
    
    if not hits:
        print(f"{Colors.GREEN}✓ No suspicious/invisible characters found.{Colors.RESET}")
        print()
        return
    
    print(f"{Colors.RED}{Colors.BOLD}✗ Found {len(hits)} suspicious char(s):{Colors.RESET}")
    for h in hits:
        ctx_display = ' '.join(f'{ord(c):04x}' for c in h['context']) if verbose else h['context']
        print(f"{Colors.RED} - idx={h['index']:3d} byte_offset={h['byte_offset']:3d} {h['U']} {h['description']} (cat={h['cat']}){Colors.RESET}")
        print(f"    context: ...{ctx_display}...")
    print()

# EXEMPLOS EXPANDIDOS
EXAMPLES = [
    # Exemplos Originais - Caracteres de Espaço
    ("No-Break Space (NBSP)", "p\u00A0ass\u00A0word"),                                    # 0x00A0
    ("Soft Hyphen (SHY)", "p\u00ADass\u00ADword"),                                        # 0x00AD
    ("Mongolian Vowel Separator (MVS)", "mongolian\u180Etext\u180E"),                     # 0x180E
    ("Zero Width Space (ZWSP)", "p\u200Bass\u200Bword"),                                  # 0x200B
    ("Zero Width Non-Joiner (ZWNJ)", "p\u200Cass\u200Cword"),                            # 0x200C
    ("Zero Width Joiner (ZWJ)", "p\u200Dass\u200Dword"),                                  # 0x200D
    
    # Exemplos de Controle de Direção
    ("LRM + RLM (Left-Right Mark)", "\u200Eabc\u200Fdef"),                               # 0x200E + 0x200F
    ("LRE + PDF (Embedding)", "abc\u202Adef\u202Cghi"),                                  # 0x202A + 0x202C
    ("RLE + PDF (Right-Left Embedding)", "abc\u202Bdef\u202Cghi"),                       # 0x202B + 0x202C
    ("LRO + PDF (Left-Right Override)", "abc\u202Ddef\u202Cghi"),                        # 0x202D + 0x202C
    ("RLO + PDF (Right-Left Override - Trojan Source)", "abc\u202Edef\u202Cghi"),        # 0x202E + 0x202C
    
    # Exemplos de Espaços Especiais
    ("Narrow No-Break Space (NNBSP)", "p\u202Fass\u202Fword"),                           # 0x202F
    ("Word Joiner (WJ)", "p\u2060ass\u2060word"),                                         # 0x2060
    ("Byte Order Mark (BOM)", "pass\uFEFFword\uFEFF"),                                    # 0xFEFF
    
    # Exemplos Avançados - Combinações Perigosas
    ("BOM no Início", "\uFEFFThis is a normal string"),                                   # 0xFEFF no início
    ("Múltiplas Zero Width (ZWSP+ZWNJ+ZWJ)", "p\u200B,\u200C,\u200Dword"),               # Combinação invisível
    ("LRO Direction Override", "\u202Dright-to-left text"),                              # 0x202D
    ("RLO Direction Override", "\u202Eleft-to-right text"),                              # 0x202E (Trojan Source)
    ("Marcadores Direcionais (Mixed)", "Arabic \u200F بدون\u200E"),                       # Misturado com árabe
    ("BOM com Controle Oculto", "\uFEFF\u200B,\u202E,\u2067test"),                        # BOM + invisíveis
    ("Scripts Globais (Russo+Controle)", "Скрипт\u2066text\u2069"),                      # Ciríico com controle
    ("Sobreposição Invisível (4 Marcadores)", "\u200E,\u200F,\u202E,\u202D"),             # 4 marcadores invisíveis
    ("Cache Unicode (Caracteres Repetidos)", "cache\u200B,\u200C,\u200D,\u2060,"),        # Teste de cache
    ("Controle Bidi (Árabe+Controle)", "bidi\u202Aاختبار\u202C testing"),                # Árabe com controle bidi
    ("Hebraico com Controle", "איך\u200E\u200Eאפשר\u200F"),                               # Hebraico com marcas
    ("Pontuação com Controle", "testing\u202A-?\u202C"),                                  # Pontuação envolvida
    ("Latin com Controle Oculto", "latin\u200C,\u200D,\u2066script"),                     # Latino com zero-width
    ("Direcionalidade de Texto", "over\u202Dide\u202Etext"),                             # Múltiplos overrides
    ("Marcador de Cor (Isolate)", "text\u2067color\u2069ing"),                           # Isolate markers
    ("Separador de Segmento", "segment\uFFFDseparator"),                                 # Replacement character
    ("Zero Width Deprecated", "deprecated\u200B-control"),                               # ZWSP simples
    ("Mudança Direcional Complexa", "\u200Eabc\u200F,\u202E\u202Cdef"),                  # Combinação complexa
    ("BOM com Múltiplos Controles", "\uFEFF\u202A,\u202B,\u200C"),                        # BOM + controles
]

def main():
    p = argparse.ArgumentParser(
        description="Unicode invisible/format character validator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  python3 valida_unicode1.py "seu texto aqui"
  python3 valida_unicode1.py -e                    (rodar todos os exemplos)
  python3 valida_unicode1.py -e -v                 (exemplos com verbose)
  python3 valida_unicode1.py --deep "texto"        (modo profundo - detecta mais)
  python3 valida_unicode1.py -e --deep             (exemplos em modo profundo)
  echo "texto" | python3 valida_unicode1.py -      (ler de stdin)
"""
    )
    p.add_argument('inputs', nargs='*', help='Strings to scan; use - for stdin')
    p.add_argument('-e', '--examples', action='store_true', help='Run built-in examples')
    p.add_argument('-v', '--verbose', action='store_true', help='Verbose mode (more details)')
    p.add_argument('--deep', action='store_true', help='Deep mode (detect Best-Fit, Fullwidth, etc)')
    args = p.parse_args()

    if args.examples:
        total = len(EXAMPLES)
        mode = " [MODO DEEP]" if args.deep else ""
        print(f"\n📋 Rodando {total} exemplos{mode}...\n")
        for name, ex in EXAMPLES:
            report(ex, label=name, verbose=args.verbose, deep=args.deep)
        return

    if not args.inputs:
        p.print_help()
        return

    for it in args.inputs:
        if it == '-':
            try:
                txt = sys.stdin.buffer.read().decode('utf-8', errors='replace')
            except Exception as e:
                print(f"{Colors.RED}❌ Error reading stdin: {e}{Colors.RESET}")
                return
            report(txt, "<stdin>", verbose=args.verbose, deep=args.deep)
        else:
            report(it, label=it, verbose=args.verbose, deep=args.deep)

if __name__ == "__main__":
    main()
