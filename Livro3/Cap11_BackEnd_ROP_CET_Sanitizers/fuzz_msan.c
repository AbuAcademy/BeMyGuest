#include <stdint.h>
#include <stddef.h>

void secret(const uint8_t *data, size_t size) {
    int state; // Não-inicializada (Contém lixo)

    if (size > 3 && data[0] == 'M' && data[1] == 'S') {
        // O valor lixo passa a influenciar o fluxo lógico
        if (state == 0x41414141) { 
            // Caminho que expõe dados latentes
        }
    }
}

// Ponto de entrada oficial exigido pelo libFuzzer
int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    secret(Data, Size);
    return 0;
}
