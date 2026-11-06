#include <windows.h>
#include <stdio.h>
int main() {
    __try {
        char *ptr = NULL; // Ponteiro inicializado apontando para 0x0
        *ptr = 'A';       // Desreferenciacao ilegal: Gatilho da falha
        printf("Isso nunca sera impresso.\n");
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        DWORD code = GetExceptionCode();
        // Bloco acionado quando o kernel captura a excecao 0xC0000005
        printf("Access Violation Code: 0x%X\n", code);
    }
    return 0;
}
