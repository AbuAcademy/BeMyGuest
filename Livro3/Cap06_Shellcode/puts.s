[BITS 64]
global main             ; declara a funcao main() como global
section .text           ; declara a secao .text
main:                   ; rotulo referente ao simbolo da funcao main()
    mov rdi, msg        ; move o valor da msg (Aloha+0) para rdi
    ;lea rdi, [rel msg] ; alternativa: calcula endereco efetivo
    extern puts         ; define como externa a funcao puts()
    call puts           ; chama a funcao puts(rdi) e mostra rdi na tela
    ret                 ; retorna para o caller
section .data           ; secao de dados
msg:                    ; rotulo referente ao simbolo da msg
    db "Aloha", 0       ; Aloha = string; String termina em nulo (\x00)
