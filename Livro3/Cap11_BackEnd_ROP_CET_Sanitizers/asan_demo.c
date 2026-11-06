#include <stdlib.h>
#include <string.h>
#include <stdio.h>

volatile int sink;

void heap_overflow(void) {
    char *buf = malloc(16);
    strcpy(buf, "este texto tem mais de 16 bytes!!");
    sink = buf[0];
    free(buf);
}

void use_after_free(void) {
    char *buf = malloc(32);
    free(buf);
    buf[0] = 'X';
    sink = buf[0];
}

void stack_overflow(void) {
    char local[8];
    local[10] = 0xff;
    sink = local[10];
}

int main(int argc, char **argv) {
    if (argc < 2) return 1;

    switch (argv[1][0]) {
        case '1': heap_overflow(); break;
        case '2': use_after_free(); break;
        case '3': stack_overflow(); break;
    }

    return 0;
}
