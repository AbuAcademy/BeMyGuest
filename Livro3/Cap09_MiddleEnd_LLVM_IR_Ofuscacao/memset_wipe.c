#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void handle_secret(const char *secret) {
    size_t len = strlen(secret);
    char *buf = malloc(len + 1);
    memcpy(buf, secret, len + 1);

    printf("Segredo alocado em: %p\n", (void *)buf);
    printf("PID: %d\n", getpid());
    printf("Pressione ENTER para continuar...(mas antes, leia a memória!)\n");
    getchar();  // pausa ANTES do memset/free

    // Limpeza de segurança... eliminada pelo compilador com -O1
    memset(buf, 0, len + 1);
    free(buf);

    printf("free() chamado — segredo 'apagado'\n");
    printf("Pressione ENTER para encerrar...\n");
    getchar();  // pausa DEPOIS do free... leia a memória de novo para comparar
}

int main() {
    handle_secret("s3cr3t_p4ssw0rd");
    return 0;
}
