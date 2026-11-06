#include <stdio.h>
#include <unistd.h>

// Gadget de conveniência para o lab
__attribute__((used, naked))
void gadget(void) {
    __asm__(
        "pop %rdi\n\t"
        "ret\n\t"
    );
}

void vulneravel(void) {
    char buffer[64];
    printf("Endereco do buffer: %p\n", (void *)buffer);
    printf("Entrada> ");
    fflush(stdout);
    
    // Vulnerabilidade: leitura de 512 bytes em um buffer de apenas 64
    read(0, buffer, 512);   
    puts("Processamento concluido.\n");
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    vulneravel();
    return 0;
}
