#include <stdio.h>

__attribute__((noinline))
int ps(int x) {
    return x * 2 + 1;
}

int main(void) {
    printf("Resultado: %d\n", ps(21));
    return 0;
}
