#!/bin/bash
# Script para análise de layout de memória

echo "[+] Analyzing memory layout for PID: $1"

# Examinar /proc/maps para padrões ASLR
cat /proc/$1/maps | awk '{print $1, $2, $6}' | while read range perms file; do
    start=$(echo $range | cut -d'-' -f1)
    echo "[*] $file: $start ($perms)"
    
    # Extrair índices de page table para análise
    python3 -c "
addr = int('$start', 16)
pml4 = (addr >> 39) & 0x1FF
pdp = (addr >> 30) & 0x1FF  
pd = (addr >> 21) & 0x1FF
pt = (addr >> 12) & 0x1FF
print(f'  PML4: {pml4}, PDP: {pdp}, PD: {pd}, PT: {pt}')
"
done
