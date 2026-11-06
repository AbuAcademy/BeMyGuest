#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main() {
    printf("PID: %d - Lendo de pipe (vai bloquear)...\n", getpid()); // simula bloqueio de I/O.

    int pipefd[2];
    pipe(pipefd);  // Cria um pipe (canal de comunicação)

    if (fork() == 0) {
        // Processo filho(produz): escreve no pipe a cada 1 segundo
        close(pipefd[0]);	// fecha a leitura

        while (1) {
            write(pipefd[1], "A", 1);		// envia 1 byte ('A')
            printf("[FILHO] Escrevi no pipe... dado enviado\n"); 
            sleep(1);	// gera dados a cada 1 segundo
        }
    } else {
        // Processo pai(consome): tenta ler do pipe (bloqueia se não tiver dados)
        close(pipefd[1]);	// fecha escrita

        char buf;
        while (1) {
            printf("[PAI] Tentando ler... ");
            fflush(stdout);
 
            read(pipefd[0], &buf, 1);  // A mágica acontece aqui (read() bloqueia)

            printf("OK, já li: %c\n", buf);
        }
    }

    return 0;
}
