#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

int global_data = 123; // seção .data; variável global inicializada
int global_bss; // seção .bss; variável global não inicializada
const char* global_text = "Região .rdata"; // constante somente leitura

void function() {
    int var_function = 999; // variável local na stack de "function"
    printf("[var_function] = %p\n", (void*)&var_function);
}

int main() {
    // Desativa o buffer do stdout para que o printf mostre cada saída na hora
    setvbuf(stdout, NULL, _IONBF, 0);

    int var_stack = 456; // variável local na stack
    int* ptr_heap = (int*) malloc(sizeof(int)); // variável no heap
    if (ptr_heap != NULL) {
        *ptr_heap = 789;
    }

    printf("\n===== Analisando Layout de Memória =====\n");
    printf("[.text]  = %p\n", (void*)&main);
    printf("[.rdata] = %p\n", (void*)global_text);
    printf("[.data ] = %p\n", (void*)&global_data);
    printf("[.bss ]  = %p\n", (void*)&global_bss);
    printf("[stack ] = %p\n", (void*)&var_stack);
    printf("[heap ]  = %p\n", (void*)ptr_heap);

    if (ptr_heap != NULL) {
        printf("[*heap]  = %d\n", *ptr_heap);
    }

    function();

    printf("PID = %lu\n\n", GetCurrentProcessId());

    // Pausa para análise manual no WinDbg
    Sleep(-1);

    free(ptr_heap);
    return 0;
}
