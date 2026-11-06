#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

// Ponteiro de função estático para armazenar o endereço do malloc real
static void *(*real_malloc)(size_t) = NULL;

// Nossa versão hookeada do malloc — intercepta antes da libc
void *malloc(size_t size) {
    // Se for a primeira chamada, resolvemos o endereço do próximo malloc na árvore do linker
    if (!real_malloc) {
        real_malloc = dlsym(RTLD_NEXT, "malloc"); 
    }

    // Executa a alocação real de forma transparente para o programa
    void *ptr = real_malloc(size);

    // Registra a telemetria com segurança na saída de erro padrão (stderr)
    // Nota: Usamos stderr para não misturar com o fluxo de saída regular (stdout) do programa
    fprintf(stderr, "[Monitor] Alocação solicitada: malloc(%zu) → Endereço: %p\n", size, ptr);

    return ptr;
}
