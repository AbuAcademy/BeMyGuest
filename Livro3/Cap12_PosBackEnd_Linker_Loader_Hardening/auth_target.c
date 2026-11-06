#include <stdio.h>
#include <string.h>

// Declaração do símbolo externo vindo da biblioteca
extern int check_auth(const char *passwd);

int main(void) {
    char input[64];
    printf("Senha: ");
    fflush(stdout);
    if (!fgets(input, sizeof(input), stdin)) return 1;
    input[strcspn(input, "\n")] = '\0';

    if (check_auth(input)) {
        printf("[+] Acesso concedido\n");
    } else {
        printf("[-] Acesso negado\n");
    }
    return 0;
}
