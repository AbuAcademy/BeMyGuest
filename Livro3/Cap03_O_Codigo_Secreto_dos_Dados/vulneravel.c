#include <stdio.h>
#include <string.h>

// A função que o atacante quer executar
void funcao_secreta() {
    printf("\n--> Parabéns! Você foi ownado! <--\n");
    printf("A ordem dos bytes estava correta!\n\n");
}

// A função vulnerável
void copia_dados(char *input) {
    char buffer[64]; // Nosso buffer tem apenas 64 bytes

    printf("Copiando dados para o buffer...\n");
    strcpy(buffer, input); 	// Aqui dá merda 
    printf("Dados copiados!\n");
}

// O fluxo normal do programa
int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Uso: %s <string>\n", argv[0]);
        return 1;
    }
    
    printf("Programa iniciando normalmente.\n");
    copia_dados(argv[1]);
    printf("Programa terminando normalmente.\n");
    return 0;
}
