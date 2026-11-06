#include <stdio.h>
#include <unistd.h>
#include <sys/ioctl.h>

int main() {
    pid_t pid = getpid();

    // Verifica se o processo está em foreground
    int fg = (tcgetpgrp(STDIN_FILENO) == getpgrp());

    printf("PID: %d - Rodando loop infinito...\n", pid);

    if (fg) {
        printf("Processo em foreground: Pressione 'Ctrl+C' para parar!\n\n");
    } else {
        printf("Processo em background: Execute 'kill -9 $(pidof cs_cena1) para parar!\n\n");
    }

    volatile unsigned long counter = 0;

    while (1) {
        counter++;
        if (counter % 100000000 == 0) {
            printf("PID %d - Contador: %lu\n", pid, counter);
        }
    }

    return 0;
}
