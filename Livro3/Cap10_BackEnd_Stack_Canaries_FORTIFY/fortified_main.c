#include <stdio.h>
#include <string.h>

extern void wrapper(char *dst, const char *src);

void safe(const char *input) {
    char buf[16];
    strcpy(buf, input);		// Chamada será protegida pq o compilador ainda conhece o buffer size 

    printf("[safe] %s\n", buf);
}

int main(int argc, char *argv[]) {
    if (argc < 2)
        return 1;

    char buf[16];

    printf("Executando safe...\n");
    safe(argv[1]);

    printf("Executando wrapper da lib externa...\n");
    wrapper(buf, argv[1]);

    printf("Resultado: %s\n", buf);

    return 0;
}
