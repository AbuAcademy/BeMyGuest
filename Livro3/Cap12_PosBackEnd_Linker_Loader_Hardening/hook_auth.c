#include <stdio.h>

// Assinatura idêntica à do binário alvo
int check_auth(const char *passwd) {
    // Registra o input original fornecido pelo usuário (Capacidade de Keylogging)
    fprintf(stderr, "[H00K] check_auth interceptado [texto capturado]: '%s'\n", passwd);
    fprintf(stderr, "[H00K] Forçando retorno 'true' de forma arbitrária...\n");
    return 1; 		// 1 = Sucesso na validação
}
