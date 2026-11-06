#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void __attribute__((used)) shell() {
    char *args[] = { "/bin/sh", NULL };
    execve("/bin/sh", args, NULL);
}

__attribute__((noinline))
void opaque(void *dst, const void *src, size_t n) {
    memcpy(dst, src, n);   /* void* apaga o tipo → memcpy@plt, não __memcpy_chk */
}

static char gl_input[512];  	// Fora da stack frame de vuln()

void vuln() {
    char buf[64];
    ssize_t n;

    printf("input: ");
    fflush(stdout);

    n = read(STDIN_FILENO, gl_input, sizeof(gl_input));
    opaque((void *)buf, gl_input, (size_t)n);
}

int main() {
    puts("[ FORTIFY=3 bypass lab ]");
    vuln();
    return 0;
}
