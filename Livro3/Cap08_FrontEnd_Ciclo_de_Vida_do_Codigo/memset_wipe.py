import sys

if len(sys.argv) != 3:
    print(f"Uso: sudo python3 {sys.argv[0]} <PID> <Endereço_Hex>")
    print(f"Ex:  sudo python3 {sys.argv[0]} 157578 0x62d2455582a0")
    sys.exit(1)

pid  = int(sys.argv[1])
addr = int(sys.argv[2], 16)

with open(f"/proc/{pid}/mem", "rb") as mem:
    mem.seek(addr)
    data = mem.read(32)
    for i in range(0, len(data), 16):
        chunk = data[i:i+16]
        hex_part = ' '.join(f'{b:02x}' for b in chunk)
        asc_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        print(f"  {addr+i:016x}  {hex_part:<48}  |{asc_part}|")
