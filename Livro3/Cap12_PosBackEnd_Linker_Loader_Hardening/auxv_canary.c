#include <sys/auxv.h>
#include <stdio.h>
#include <stdint.h>

int main() {
    // 1. Captura o ponteiro dos 16 bytes aleatórios no AUXV
    unsigned char *random_bytes = (unsigned char *)getauxval(AT_RANDOM);
    
    // 2. Extrai o Stack Canary atual direto do registrador %fs:0x28 em assembly
    uint64_t canary;
    __asm__("mov %%fs:0x28, %0" : "=r"(canary));

    printf("Endereço do AT_RANDOM no AUXV: %p\n", (void *)random_bytes);
    
    // Imprime os 16 bytes da semente do Kernel
    printf("Bytes no AT_RANDOM:           ");
    for (int i = 0; i < 16; i++) {
        printf("%02x", random_bytes[i]);
    }
    
    // Imprime o Canary ativo no frame da função (em formato Little-Endian)
    printf("\nStack Canary ativo (Hex):      %016lx\n", canary);
    return 0;
}
