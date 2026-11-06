#include <stdio.h>

int main() {
    // Primeira chamada: vai disparar o Lazy Binding (Passos 1 a 6)
    printf("Hacked\n");

    // Segunda chamada: vai saltar DIRETO para a libc (Chamada Subsequente)
    printf("Hacked\n");

    return 0;
}
