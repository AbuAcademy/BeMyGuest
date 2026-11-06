#include <stdio.h>

// A forma correta: parênteses em volta de TUDO
#define SQUARE(x) x * x

int main() {
    int result = SQUARE(2 + 3);  	// Você espera 25, né?  
    printf("Agora sim: %d\n", result); // Vai dar 11 essa porra!
    return 0;
}
