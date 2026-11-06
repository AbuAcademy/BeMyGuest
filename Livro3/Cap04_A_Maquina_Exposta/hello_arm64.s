// hello_arm64.s – AArch64 Linux (Sintaxe GNU AS)
// Monta: aarch64-linux-gnu-gcc -nostdlib -static \
//        hello_arm64.s -o hello_arm64

.section .data
msg:    .ascii  "Hello, World!\n"
len = . - msg

.section .text
.global _start

_start:
    // ── syscall: write(fd=1, buf=msg, count=14) ─────────────
    mov     x8, #64         // sys_write = 64 em AArch64
    mov     x0, #1          // fd = stdout
    adr     x1, msg         // Endereço relativo ao PC (IP-relative)
    mov     x2, #14         // Tamanho
    svc     #0              // Supervisor Call (Gera a interrupção)

    // ── syscall: exit(status=0) ──────────────────────────────
    mov     x8, #93         // sys_exit = 93 em AArch64
    mov     x0, #0          // status = 0
    svc     #0
