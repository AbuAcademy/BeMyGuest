#include <stdio.h>

void login(char *username) {
    char log_msg[128];
    // Vulnerabilidade 1: Format String (Info Leak)
    // O atacante envia "%p" repetidamente para caminhar pela stack.
    snprintf(log_msg, sizeof(log_msg), username); 
    printf("Log: %s\n", log_msg); 

    // Vulnerabilidade 2: Stack Overflow
    char buffer[64];
    printf("Digite sua senha: \n");
    gets(buffer);   // O 'gets' atropela a stack até o RIP.
}

int main(int argc, char **argv) {
    if (argc > 1) login(argv[1]);
    return 0;
}
