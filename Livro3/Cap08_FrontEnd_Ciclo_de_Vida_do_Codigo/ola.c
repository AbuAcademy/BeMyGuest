#include <stdio.h>

#define MSG "Agora vai!\n"
#define DEBUG_MODE

int main() {
    #ifdef DEBUG_MODE
        printf("DEBUG: Iniciando o Programa\n");
    #endif
    
    printf(MSG);
    return 0;
}
