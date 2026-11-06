#include <stdio.h>
#include <string.h>
#include <stdint.h>

// Função simulando um log de auditoria
__attribute__((noinline))
void log_header(void) {
    printf("[ALERT]: Cabeçalho corrompido!\n");
}

int validate(unsigned char *header) {
    uint32_t magic;
    // O memcpy deveria forçar opacidade no SelectionDAG
    memcpy(&magic, header, 4);

    // Avaliação condicional crítica de segurança
    if (magic != 0xBEBACAFE) {
        log_header();
        return -1;
    }
    return 0;
}

int main(void) {
    // Vetor constante simulando um buffer estático
    unsigned char fake_packet[4] = {0xFE, 0xCA, 0xBA, 0xBE};
    
    // A validação recebe o ponteiro do buffer conhecido
    if (validate(fake_packet) == 0) {
        printf("[SYSTEM]: Pacote aceito.\n");
    }
    return 0;
}
