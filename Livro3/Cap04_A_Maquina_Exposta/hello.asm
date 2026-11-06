section .data
    msg db "Hello, World!", 0x0a ; String + newline (LF)
    len equ $ - msg             ; Tamanho calculado dinamicamente
section .text
    global _start
_start:
    ; syscall: write(fd=1, buf=msg, count=len)
    mov     rax, 1           ; sys_write = 1
    mov     rdi, 1           ; fd = stdout (descritor 1)
    lea     rsi, [rel msg]   ; Endereco relativo ao RIP (PIE-ready)
    mov     rdx, len         ; Quantidade de bytes
    syscall                  ; Transfere o controle para o Kernel
    ; syscall: exit(status=0)
    mov     rax, 60          ; sys_exit = 60
    xor     rdi, rdi         ; status = 0 (Otimizacao de opcodes)
    syscall
