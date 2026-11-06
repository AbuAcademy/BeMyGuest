#include <stdio.h>
#include <stdlib.h>

#ifndef BUILD
#define BUILD 0
#endif

// Macros de mutação
#if BUILD == 0
#define BLOCK() \
    do { \
        volatile int a = 0; \
        a += 1; \
        a ^= 0xAA; \
    } while (0);

#elif BUILD == 1
#define BLOCK() \
    do { \
        volatile char buf[32]; \
        for (int i = 0; i < 8; i++) { \
            buf[i] = (char)(i * 3); \
        } \
    } while (0);

#elif BUILD == 2
#define BLOCK() \
    do { \
        volatile long x = 0x1234; \
        x = (x << 2) ^ 0xBEBACAFE; \
    } while (0);

#else
#define BLOCK()
#endif

// Payload
void payload(void) {
    BLOCK();
    system("echo payload executado");
    BLOCK();
}

int main(void) {
    BLOCK();
    payload();
    BLOCK();
    return 0;
}
