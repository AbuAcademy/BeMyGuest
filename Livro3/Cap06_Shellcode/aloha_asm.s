[BITS 64]

global _start           		; define o símbolo _start como global

section .data 			; define a seção de dados 
msg:   db  'Aloha',0xa 		; Mensagem que será impressa na tela

section .text 			; define a seção .text (código)
_start:
	; write (1, msg, 6)
	mov rdi, 1            	; fd = 1 (stdout)
	mov rsi, msg        ; endereço da msg (string) para a saída
	mov rdx, 6          ; número de bytes (count/nbytes)
	mov rax, 1          ; 1 = syscall write
	syscall         	; chama o S.O. para executar o write
 
	; exit(0)
	mov rax, 60         ; 60 = exit system call
	xor rdi, rdi        ; código de retorno = 0
	syscall         	; chama o S.O. para executar o exit
