#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define VALID_TOKEN 1337
#define BUFFER_SIZE 32

// Bloqueia o inline automático para forçar o LLVM a exibir a telemetria explícita da função
__attribute__((noinline)) static bool validate_token(int token) {
    return token == VALID_TOKEN;
}

// Bloqueia o inline para isolar o Cold Path (Caminho Frio)
__attribute__((noinline)) static void access_denied(void) {
    puts("Access denied");
}

// Bloqueia o inline para isolar o Hot Path (Caminho Quente)
__attribute__((noinline)) static void process_data(void) {
    volatile unsigned long checksum = 0;
    for (int i = 0; i < 1000; i++) {
        checksum += i;
    }
}

int main(void) {
    char buffer[BUFFER_SIZE];
    
    // Abordagem moderna: lê a linha de forma segura limitando o tamanho físico do buffer
    while (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        char *endptr;
        
        // Converte o texto capturado para número com validação robusta de tipo
        long token = strtol(buffer, &endptr, 10);
        
        // Se a string de entrada não contiver nenhum número válido, ignora e avança
        if (buffer == endptr) {
            continue; 
        }

        // Bifurcação central: O alvo cirúrgico do PGO
        if (!validate_token((int)token)) {
            access_denied();
            continue;
        }
        
        process_data();
    }
    
    return 0;
}
