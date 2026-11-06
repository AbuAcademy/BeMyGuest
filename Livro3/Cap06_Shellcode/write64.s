[BITS 64]
global _start           ; Define o simbolo _start como global
section .text           ; Define a secao .text (codigo executavel)
_start:
    ; write (1, "Aloha\n", 6)
    mov rdx, 0x00000a61686f6c41  ; Carrega a string invertida em LE -> RDX
    push rdx                     ; Empilha a string (passa a morar na stack)
    mov rsi, rsp                 ; RSI assume o topo da pilha (ptr -> string)
    xor rdi, rdi                 ; Limpa RDI
    inc rdi                      ; RDI = 1 (arg1: fd = stdout)
    xor rax, rax                 ; Limpa RAX
    mov al, 1                    ; RAX = 1 (syscall sys_write)
    xor rdx, rdx                 ; Limpa RDX
    mov dl, 6                    ; RDX = 6 (arg3: count = 6)
    syscall                      ; Invoca write
    ; exit(0)
    mov al, 60                   ; RAX = 60 (syscall sys_exit)
    xor rdi, rdi                 ; RDI = 0 (arg1: status = 0)
    syscall                      ; Invoca exit
