#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

KERNEL_DIR=${1}

# Validação do diretório raiz do kernel
if [ -z "$KERNEL_DIR" ] || [ ! -d "$KERNEL_DIR/fs" ]; then
    echo -e "${RED}[-] Erro: Diretório do código-fonte do kernel inválido ou incompleto.${NC}"
    echo -e "${YELLOW}[!] Uso: $0 ~/linux-source-6.14.0${NC}"
    exit 1
fi

banner() {
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}==============================================================================${NC}\n"
}

# ------------------------------------------------------------------------------
# MODULO 1: STACK ASLR
# ------------------------------------------------------------------------------
banner "MÓDULO 1: Stack ASLR (Reserva de espaço, Masking e Shift)"

echo -e "${BLUE}[1.1] Reserva inicial de espaço no execve (fs/exec.c):${NC}"
grep -rnE -A 2 -B 2 "STACK_RND_MASK << PAGE_SHIFT" "$KERNEL_DIR/fs/" 2>/dev/null
echo ""

echo -e "${BLUE}[1.2] A matemática da entropia da pilha (mm/util.c):${NC}"
grep -rnE -A 8 -B 2 "current->flags & PF_RANDOMIZE" "$KERNEL_DIR/mm/util.c" 2>/dev/null | \
grep -E "PF_RANDOMIZE|random_variable|STACK_RND_MASK|PAGE_SHIFT|PAGE_ALIGN" -A 1 -B 1 --color=always
echo ""

# ------------------------------------------------------------------------------
# MODULO 2: MMAP & SHARED LIBRARIES ASLR (.so)
# ------------------------------------------------------------------------------
banner "MÓDULO 2: mmap & Shared Libraries ASLR (libc, ld.so, etc.)"

echo -e "${BLUE}[2.1] Função de entropia mmap específica para x86 (arch/x86/mm/mmap.c):${NC}"
grep -rnE -A 10 "unsigned long arch_mmap_rnd\(" "$KERNEL_DIR/arch/x86/" 2>/dev/null
echo ""

echo -e "${BLUE}[2.2] Configuração do layout do mmap (mm/mmap.c / arch/x86/mm/mmap.c):${NC}"
grep -rnE -A 8 "arch_pick_mmap_layout\(" "$KERNEL_DIR/arch/x86/" 2>/dev/null
echo ""

# ------------------------------------------------------------------------------
# MODULO 3: HEAP ASLR (brk)
# ------------------------------------------------------------------------------
banner "MÓDULO 3: Heap ASLR (Alocações via brk / randomize_va_space > 1)"

echo -e "${BLUE}[3.1] Randomização da base do segmento brk (arch/x86/kernel/process.c):${NC}"
grep -rnE -A 10 "arch_randomize_brk\(" "$KERNEL_DIR/arch/x86/" 2>/dev/null
echo ""

echo -e "${BLUE}[3.2] Verificação do nível 2 da sysctl randomize_va_space para o brk (fs/binfmt_elf.c):${NC}"
# v1 buscava "randomize_va_space == 2" em mm/ — string que nunca existiu ali.
# A checagem real usa uma "fotografia" (snapshot) do sysctl, tomada via READ_ONCE()
# no início do load_elf_binary(), e mora em fs/binfmt_elf.c.
grep -rnE -A 4 "snapshot_randomize_va_space > 1" "$KERNEL_DIR/fs/binfmt_elf.c" 2>/dev/null
echo ""

# ------------------------------------------------------------------------------
# MODULO 4: EXECUTABLE / PIE BASE ASLR (.text)
# ------------------------------------------------------------------------------
banner "MÓDULO 4: Executável / PIE Base ASLR (Position Independent Executables)"

echo -e "${BLUE}[4.1] Cálculo da base aleatória para binários ET_DYN / PIE (fs/binfmt_elf.c):${NC}"
grep -rnE -A 8 "ELF_ET_DYN_BASE" "$KERNEL_DIR/fs/binfmt_elf.c" 2>/dev/null
echo ""

echo -e "${BLUE}[4.2] Atribuição do load_bias no carregamento das seções LOAD (fs/binfmt_elf.c):${NC}"
grep -rnE -A 6 "load_bias = " "$KERNEL_DIR/fs/binfmt_elf.c" 2>/dev/null | head -n 20
echo ""

# ------------------------------------------------------------------------------
# MODULO 5: vDSO & vvar PAGE ASLR
# ------------------------------------------------------------------------------
banner "MÓDULO 5: vDSO & vvar Page ASLR (Virtual Dynamic Shared Object)"

echo -e "${BLUE}[5.1] Cálculo de entropia e offset do vDSO (arch/x86/entry/vdso/vma.c):${NC}"

grep -rnE -A 10 "vdso_addr\(" "$KERNEL_DIR/arch/x86/entry/vdso/" 2>/dev/null
if [ $? -ne 0 ] || [ -z "$(grep -rlE "vdso_addr\(" "$KERNEL_DIR/arch/x86/entry/vdso/" 2>/dev/null)" ]; then
    echo -e "${YELLOW}[!] vdso_addr() não encontrada — normal a partir do kernel 6.9.${NC}"
    echo -e "${YELLOW}    O vDSO agora herda a entropia do mmap (ver Módulo 2).${NC}"
fi
echo ""

echo -e "${BLUE}[5.2] Mapeamento das páginas do vDSO na memória do processo:${NC}"
grep -rnE -A 8 "arch_setup_additional_pages\(" "$KERNEL_DIR/arch/x86/entry/vdso/" 2>/dev/null
echo ""
