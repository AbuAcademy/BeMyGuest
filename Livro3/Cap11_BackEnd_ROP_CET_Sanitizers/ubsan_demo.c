#include <stdio.h>

int main(void) {
    int max = 2147483647; // INT_MAX para sistemas de 32-bit/64-bit
    volatile int overflow = max + 1; // signed integer overflow (UB)
    printf("Resultado: %d\n", overflow);
    return 0;
}	
