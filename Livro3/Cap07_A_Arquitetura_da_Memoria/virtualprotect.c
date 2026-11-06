#include <windows.h>
#include <stdio.h>

int main() {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    DWORD pagesize = si.dwPageSize;

    // 1. Aloca memória privada com permissão padrão Read/Write (PAGE_READWRITE)
    LPVOID ptr = VirtualAlloc(NULL, pagesize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!ptr) {
        printf("Erro ao alocar memoria. Erro: %lu\n", GetLastError());
        return 1;
    }

    printf("[+] Memoria alocada no endereco: 0x%p\n", ptr);
    printf("[+] Tamanho da pagina: %lu bytes\n", pagesize);
    printf("[!] Passo 1: Abra o VMMap, busque pelo nome do programa ou PID: %lu\n", GetCurrentProcessId());
    printf("[>] Pressione ENTER para rodar o VirtualProtect e mudar para RWX...");
    getchar();

    // 2. Altera a permissão da página para PAGE_EXECUTE_READWRITE (RWX)
    DWORD protect;
    if (!VirtualProtect(ptr, pagesize, PAGE_EXECUTE_READWRITE, &protect)) {
        printf("Erro no VirtualProtect. Erro: %lu\n", GetLastError());
        VirtualFree(ptr, 0, MEM_RELEASE);
        return 1;
    }

    printf("\n[+] VirtualProtect executado com sucesso!\n");
    printf("[!] Passo 2: Atualize o VMMap (F5) para observar a mudanca de permissao.\n");
    printf("[>] Pressione ENTER para encerrar...");
    getchar();

    VirtualFree(ptr, 0, MEM_RELEASE);
    return 0;
}
