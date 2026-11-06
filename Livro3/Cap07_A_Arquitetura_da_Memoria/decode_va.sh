#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Uso: $0 <endereco_virtual>"
    echo "Exemplo: $0 0x0000001cde996000"
    exit 1
fi

VA=$(( $1 ))

PML4=$(( (VA >> 39) & 0x1FF ))
PDPT=$(( (VA >> 30) & 0x1FF ))
PD=$(( (VA >> 21) & 0x1FF ))
PT=$(( (VA >> 12) & 0x1FF ))
OFF=$(( VA & 0xFFF ))

echo
printf "Endereço Virtual: 0x%016X\n\n" "$VA"

printf "%-10s %-10s %-10s\n" "Campo" "Hex" "Decimal"
printf "%-10s %-10s %-10s\n" "----------" "--------" "--------"

printf "%-10s 0x%03X      %-10d\n" "PML4"   "$PML4" "$PML4"
printf "%-10s 0x%03X      %-10d\n" "PDPT"   "$PDPT" "$PDPT"
printf "%-10s 0x%03X      %-10d\n" "PD"     "$PD"   "$PD"
printf "%-10s 0x%03X      %-10d\n" "PT"     "$PT"   "$PT"
printf "%-10s 0x%03X      %-10d\n" "Offset" "$OFF"  "$OFF"

echo
echo "Offsets dentro das tabelas (Indice x 8 bytes):"
printf "PML4E : 0x%03X x 8 = 0x%03X\n" "$PML4" $((PML4*8))
printf "PDPTE : 0x%03X x 8 = 0x%03X\n" "$PDPT" $((PDPT*8))
printf "PDE   : 0x%03X x 8 = 0x%03X\n" "$PD"   $((PD*8))
printf "PTE   : 0x%03X x 8 = 0x%03X\n" "$PT"   $((PT*8))
