#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void process_data(FILE *f) {
    char buffer[16];
    int ch, i = 0;
    
    // Parser inseguro: lê até encontrar quebra de linha
    while ((ch = fgetc(f)) != EOF && ch != '\n') {
        buffer[i++] = ch; // Stack Buffer Overflow latente!
    }
    
    if (i > 0 && buffer[0] == 'A' && buffer[1] == 'B') {
        if (buffer[16] == 'X') { // Escrita/Leitura ilegal de 1 byte
            printf("Bug crítico acionado!\n");
        }
    }
}

int main(int argc, char **argv) {
    if (argc < 2) return 1;
    FILE *f = fopen(argv[1], "r");
    if (!f) return 1;
    process_data(f);
    fclose(f);
    return 0;
}
