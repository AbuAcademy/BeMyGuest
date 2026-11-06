#include <stdio.h>

__attribute__((noinline))
int classify(int x) {
    if (x < 0)
        return -1;
    else if (x == 0)
        return 0;
    else if (x < 100)
        return 1;
    else
        return 2;
}

int main(void) {
    printf("%d\n", classify(-5));
    printf("%d\n", classify(0));
    printf("%d\n", classify(42));
    printf("%d\n", classify(200));
    return 0;
}
