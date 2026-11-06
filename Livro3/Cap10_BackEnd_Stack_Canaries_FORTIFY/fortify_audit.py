#!/usr/bin/env python3
#
# fortify_audit.py
#
# Reality-based FORTIFY auditor
#
# Camadas:
#   1. checksec-like visibility
#   2. LLVM IR semantic analysis
#   3. radare2 binary analysis
#   4. correlation engine
#
# Requisitos:
#   sudo apt install radare2 clang
#
# Uso:
#
#   python3 fortify_audit.py ./fortify_basics_gcc
#
#   python3 fortify_audit.py ./fortify_basics_clang --ir fortify.ll
#
#   clang -O2 -D_FORTIFY_SOURCE=2 \
#         -emit-llvm -S fortify_basics.c -o fortify.ll
#

import subprocess
import argparse
import json
import re
import os
import tempfile
from collections import defaultdict

# ─────────────────────────────────────────────────────────────
# ANSI
# ─────────────────────────────────────────────────────────────

G = "\033[32m"
Y = "\033[33m"
R = "\033[31m"
B = "\033[1m"
C = "\033[36m"
DIM = "\033[2m"
X = "\033[0m"

# ─────────────────────────────────────────────────────────────
# helpers
# ─────────────────────────────────────────────────────────────

def sh(cmd):
    try:
        return subprocess.check_output(
            cmd,
            shell=True,
            text=True,
            stderr=subprocess.DEVNULL,
            errors="ignore"
        )
    except subprocess.CalledProcessError:
        return ""

# ─────────────────────────────────────────────────────────────
# checksec layer
# ─────────────────────────────────────────────────────────────

def checksec(binary):

    out = sh(f"checksec --file={binary}")

    result = {
        "enabled": False,
        "fortified": None,
        "fortifiable": None
    }

    if not out:
        return result

    clean = re.sub(r"\x1b\[[0-9;]*m", "", out)

    m = re.search(
        r"\d+\s+Symbols\s+(\w+)\s+(\d+)\s+(\d+)",
        clean
    )

    if m:
        result["enabled"] = m.group(1).upper() == "YES"
        result["fortified"] = int(m.group(2))
        result["fortifiable"] = int(m.group(3))

    return result

# ─────────────────────────────────────────────────────────────
# LLVM IR layer
# ─────────────────────────────────────────────────────────────

def parse_llvm_ir(ir_file):

    if not ir_file or not os.path.exists(ir_file):
        return {}

    data = open(ir_file).read()

    functions = {}

    current = None
    body = []

    for line in data.splitlines():

        m = re.match(r"define .* @([\w\d_]+)\(", line)

        if m:

            if current:
                functions[current] = "\n".join(body)

            current = m.group(1)
            body = []
            continue

        if current:
            body.append(line)

    if current:
        functions[current] = "\n".join(body)

    analysis = {}

    for fn, body in functions.items():

        state = {
            "fortified": False,
            "raw": False,
            "tailcall": False,
            "objectsize_known": False,
            "risk": "LOW",
            "reason": []
        }

        if "__strcpy_chk" in body:
            state["fortified"] = True
            state["objectsize_known"] = True
            state["reason"].append("compiler emitted __strcpy_chk")

        if re.search(r"tail call .*@strcpy", body):
            state["tailcall"] = True
            state["raw"] = True
            state["risk"] = "HIGH"
            state["reason"].append("tail-call to raw strcpy")

        elif re.search(r"@strcpy\(", body):
            state["raw"] = True
            state["risk"] = "HIGH"
            state["reason"].append("raw strcpy in IR")

        if "llvm.objectsize" in body:
            state["objectsize_known"] = True

        analysis[fn] = state

    return analysis

# ─────────────────────────────────────────────────────────────
# radare2 layer
# ─────────────────────────────────────────────────────────────

def r2_json(binary, cmd):

    full = f"r2 -2 -Aqc '{cmd}' {binary}"

    out = sh(full)

    if not out:
        return None

    try:
        return json.loads(out)
    except:
        return None

def get_functions(binary):

    data = r2_json(binary, "aflj")

    if not data:
        return []

    return data

def get_xrefs(binary, symbol):

    cmd = f"axtj sym.imp.{symbol}"

    data = r2_json(binary, cmd)

    if not data:
        return []

    return data

def function_by_offset(funcs, offset):

    for f in funcs:

        start = f.get("offset", 0)
        size = f.get("size", 0)

        if start <= offset < (start + size):
            return f.get("name")

    return "unknown"

# ─────────────────────────────────────────────────────────────
# binary analysis
# ─────────────────────────────────────────────────────────────

TARGETS = [
    "strcpy",
    "strcat",
    "sprintf",
    "memcpy"
]

def analyze_binary(binary):

    funcs = get_functions(binary)

    protected = []
    raw = []

    for target in TARGETS:

        chk = f"__{target}_chk"

        # fortified xrefs
        chk_refs = get_xrefs(binary, chk)

        for x in chk_refs:

            owner = function_by_offset(funcs, x["from"])

            protected.append({
                "function": owner,
                "target": chk,
                "offset": x["from"]
            })

        # raw xrefs
        raw_refs = get_xrefs(binary, target)

        for x in raw_refs:

            owner = function_by_offset(funcs, x["from"])

            # ignore fortified plt calls
            if "_chk" in owner:
                continue

            raw.append({
                "function": owner,
                "target": target,
                "offset": x["from"]
            })

    return protected, raw

# ─────────────────────────────────────────────────────────────
# correlation engine
# ─────────────────────────────────────────────────────────────

def correlate(ir, protected, raw):

    result = defaultdict(lambda: {
        "ir": None,
        "protected": 0,
        "raw": 0,
        "score": 100
    })

    for fn, state in ir.items():
        result[fn]["ir"] = state

    for p in protected:
        result[p["function"]]["protected"] += 1

    for r in raw:
        result[r["function"]]["raw"] += 1

    for fn in result:

        score = 100

        if result[fn]["raw"]:
            score -= 70

        if result[fn]["ir"]:

            if result[fn]["ir"]["tailcall"]:
                score -= 20

            if result[fn]["ir"]["raw"]:
                score -= 10

        score = max(score, 0)

        result[fn]["score"] = score

    return result

# ─────────────────────────────────────────────────────────────
# reporting
# ─────────────────────────────────────────────────────────────

def report(binary, cs, ir, protected, raw, corr):

    print(f"\n{'━'*70}")
    print(f"{B}FORTIFY REALITY AUDIT{X}")
    print(f"{DIM}{binary}{X}")
    print(f"{'━'*70}")

    # ─────────────────────────────────────────
    # checksec
    # ─────────────────────────────────────────

    print(f"\n{B}[1] CHECKSEC VIEW{X}")
    print(f"{'─'*50}")

    status = f"{G}YES{X}" if cs["enabled"] else f"{R}NO{X}"

    print(f"FORTIFY : {status}")

    if cs["fortified"] is not None:

        cov = (
            cs["fortified"] /
            max(cs["fortifiable"], 1)
        ) * 100

        print(f"Fortified   : {cs['fortified']}")
        print(f"Fortifiable : {cs['fortifiable']}")
        print(f"Coverage    : {cov:.1f}%")

    # ─────────────────────────────────────────
    # LLVM IR
    # ─────────────────────────────────────────

    if ir:

        print(f"\n{B}[2] LLVM IR SEMANTIC ANALYSIS{X}")
        print(f"{'─'*50}")

        for fn, state in ir.items():

            color = G

            if state["risk"] == "HIGH":
                color = R

            elif state["risk"] == "MEDIUM":
                color = Y

            print(f"\n{C}{fn}{X}")

            print(
                f"  Risk              : "
                f"{color}{state['risk']}{X}"
            )

            print(
                f"  Fortified IR      : "
                f"{state['fortified']}"
            )

            print(
                f"  Raw calls         : "
                f"{state['raw']}"
            )

            print(
                f"  Tail-call         : "
                f"{state['tailcall']}"
            )

            print(
                f"  Object-size known : "
                f"{state['objectsize_known']}"
            )

            for reason in state["reason"]:
                print(f"    -> {reason}")

    # ─────────────────────────────────────────
    # binary layer
    # ─────────────────────────────────────────

    print(f"\n{B}[3] RADARE2 BINARY ANALYSIS{X}")
    print(f"{'─'*50}")

    if protected:

        print(f"\n{G}Protected call-sites{X}")

        for p in protected:

            print(
                f" [OK] {p['function']:<25} "
                f"{hex(p['offset'])} "
                f"-> {p['target']}"
            )

    if raw:

        print(f"\n{R}Raw call-sites{X}")

        for r in raw:

            print(
                f" [X] {r['function']:<25} "
                f"{hex(r['offset'])} "
                f"-> {r['target']}"
            )

    # ─────────────────────────────────────────
    # correlation
    # ─────────────────────────────────────────

    print(f"\n{B}[4] CORRELATION ENGINE{X}")
    print(f"{'─'*50}")

    total_score = 0
    total_funcs = 0

    for fn, info in corr.items():

        total_funcs += 1
        total_score += info["score"]

        score = info["score"]

        color = G

        if score < 70:
            color = Y

        if score < 40:
            color = R

        print(f"\n{C}{fn}{X}")

        print(f"  Protected calls : {info['protected']}")
        print(f"  Raw calls       : {info['raw']}")
        print(f"  Reality score   : {color}{score}%{X}")

        if info["ir"]:

            if info["ir"]["tailcall"]:
                print(f"  {R}tail-call bypass pattern detected{X}")

            if info["ir"]["raw"]:
                print(f"  {R}compiler emitted raw strcpy{X}")

            if info["ir"]["fortified"]:
                print(f"  {G}compiler emitted __strcpy_chk{X}")

    if total_funcs:

        global_score = total_score / total_funcs

        color = G

        if global_score < 70:
            color = Y

        if global_score < 40:
            color = R

        print(f"\n{'─'*50}")

        print(
            f"{B}GLOBAL HARDENING REALITY SCORE : "
            f"{color}{global_score:.1f}%{X}"
        )

# ─────────────────────────────────────────────────────────────
# main
# ─────────────────────────────────────────────────────────────

def main():

    ap = argparse.ArgumentParser()

    ap.add_argument("binary")

    ap.add_argument(
        "--ir",
        help="LLVM IR (.ll)"
    )

    args = ap.parse_args()

    if not os.path.exists(args.binary):

        print(f"{R}binary not found{X}")
        return

    cs = checksec(args.binary)

    ir = parse_llvm_ir(args.ir) if args.ir else {}

    protected, raw = analyze_binary(args.binary)

    corr = correlate(ir, protected, raw)

    report(
        args.binary,
        cs,
        ir,
        protected,
        raw,
        corr
    )

if __name__ == "__main__":
    main()
