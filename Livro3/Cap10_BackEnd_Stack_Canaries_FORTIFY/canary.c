#include <string.h>
#include <stdio.h>

void vulnerable(const char *input) {
    char buffer[64];
    strcpy(buffer, input);           // overflow clássico
    printf("buffer: %s\n", buffer);
}

int main(int argc, char **argv) {
    if (argc > 1) vulnerable(argv[1]);
    return 0;
}
