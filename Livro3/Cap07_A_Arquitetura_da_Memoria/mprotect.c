#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    // 1. Aloca uma página de memória alinhada (requisito do mprotect)
    size_t pagesize = sysconf(_SC_PAGESIZE);
    void *ptr = aligned_alloc(pagesize, pagesize);
    
    if (!ptr) {
        perror("Erro ao alocar memória");
        return 1;
    }

    printf("[+] Memória alocada no endereço: %p\n", ptr);
    printf("[+] O tamanho da página é: %zu bytes\n", pagesize);
    printf("[!] Passo 1: Abra outro terminal e rode o comando cat para o PID: %d\n", getpid());
    printf("[>] Pressione ENTER para rodar o mprotect (mudar para RWX)...");
    getchar();

    // 2. Altera a permissão para PROT_READ | PROT_WRITE | PROT_EXEC (RWX)
    if (mprotect(ptr, pagesize, PROT_READ | PROT_WRITE | PROT_EXEC) == -1) {
        perror("Erro no mprotect");
        free(ptr);
        return 1;
    }

    printf("\n[+] mprotect executado com sucesso!\n");
    printf("[!] Passo 2: Verifique o /proc novamente para ver a mudança nas permissões.\n");
    printf("[>] Pressione ENTER para encerrar o programa...");
    getchar();

    free(ptr);
    return 0;
}
