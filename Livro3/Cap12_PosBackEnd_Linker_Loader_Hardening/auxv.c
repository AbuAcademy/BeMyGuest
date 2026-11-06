#include <sys/auxv.h>
#include <stdio.h>

int main() {
    // getauxval() busca na tabela AUXV o tipo solicitado
    unsigned char *random_bytes = (unsigned char *)getauxval(AT_RANDOM);

    printf("Endereço de memória de AT_RANDOM: %p\n", (void *)random_bytes);
    printf("Valor de AT_RANDOM (16 bytes): ");
    for (int i = 0; i < 16; i++) {
        printf("%02x", random_bytes[i]);
    }
    printf("\n");
    return 0;
}
