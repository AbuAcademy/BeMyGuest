#include <stdio.h>
#include <limits.h>

void check(int a) {
    int i;    
    for (i = a; i <= a + 10; i++) {
        if (i < 0) {
            printf("ERRO: Overflow detectado na memória!\n");
            return;
        }
        printf("Processando índice: %d\n", i);
        
        // Proteção contra loop infinito real no lab
        if (i == INT_MIN) break; 
    }
}

int main() {
    printf("Iniciando checagem com INT_MAX...\n");
    check(INT_MAX - 5);
    return 0;
}

