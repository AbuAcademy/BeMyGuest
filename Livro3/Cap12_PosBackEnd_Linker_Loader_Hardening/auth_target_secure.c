#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main(void) {
    // 1. Carrega explicitamente a biblioteca legítima de autenticação
    void *handle = dlopen("./libauth.so", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "Erro ao carregar libauth.so\n");
        return 1;
    }

    // 2. Extrai o ponteiro real e confiável diretamente de dentro dela
    int (*real_check_auth)(const char *) = dlsym(handle, "check_auth");

    // 3. Captura o símbolo que o sistema operacional resolveria por padrão
    void *default_symbol = dlsym(RTLD_DEFAULT, "check_auth");

    // 4. A Prova Defensiva: Se o símbolo padrão divergir da nossa lib, é HOOK!
    if (default_symbol != real_check_auth) {
        fprintf(stderr, "[DEFESA] Interposição Detectada!\n");
        dlclose(handle);
        exit(1);
    }

    char input[64];
    printf("Senha: ");
    fflush(stdout);
    if (!fgets(input, sizeof(input), stdin)) {
        dlclose(handle);
        return 1;
    }
    input[strcspn(input, "\n")] = '\0';

    if (real_check_auth(input)) {
        printf("[+] Acesso concedido\n");
    } else {
        printf("[-] Acesso negado\n");
    }

    dlclose(handle);
    return 0;
}
