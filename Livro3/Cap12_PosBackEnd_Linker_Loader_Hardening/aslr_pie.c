#include <stdio.h>
#include <stdlib.h>

int global = 0x12345678;

int main(void)
{
    int local = 0x71;
    void *heap = malloc(64);

    printf(".text  (main) : %p\n", (void *)main);
    printf(".data  (global): %p\n", (void *)&global);
    printf("Heap          : %p\n", heap);
    printf("Stack         : %p\n", (void *)&local);

    free(heap);
    return 0;
}
