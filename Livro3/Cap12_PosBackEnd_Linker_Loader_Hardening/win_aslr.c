#include <windows.h>
#include <stdio.h>
int global_var = 0xBEBACAFE;
void aslr(void) {}
int main(void) {
    int stack_var = 71;
    void *heap_var = HeapAlloc(GetProcessHeap(), 0, 1024);
    printf(".text  (main)      : 0x%p\n", (void*)main);
    printf(".data  (global)    : 0x%p\n", (void*)&global_var);
    printf("Stack  (local)     : 0x%p\n", (void*)&stack_var);
    printf("Heap   (alloc)     : 0x%p\n", heap_var);
    HeapFree(GetProcessHeap(), 0, heap_var);
    return 0;
}
