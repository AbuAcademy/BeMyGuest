#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// CASO 1: safe — stack buffer, FORTIFY efetivo
void safe(const char *input)
{
    char buf[32];
    strcpy(buf, input);
    puts(buf);
}

// CASO 2: wrapper — ponto cego clássico
void wrapper_vuln(char *dst, const char *src) {
    strcpy(dst, src);   
}

void wrapper(const char *input) {
    char buf[32];
    wrapper_vuln(buf, input);
    puts(buf);
}

// CASO 3: decay — array some no parâmetro 

void decay_vuln(char buffer[32], const char *input) {
    strcpy(buffer, input);  /* buffer virou char* — tamanho perdido */
}

void decay(const char *input) {
    char buf[32];
    decay_vuln(buf, input);
    puts(buf);
}

/* CASO 4: dynamic — O "superpoder" do Nível 3 (Dynamic Tracking)
void dynamic_check(const char *input, size_t n) {
    char *buf = malloc(n);
    if (buf) {
        strcpy(buf, input); 
        puts(buf);
        free(buf);
    }
}

// CASO 5: ghost — O Ponto Cego Absoluto (Global Context Loss)
char *g_buf;
void ghost_check(const char *input) {
    strcpy(g_buf, input);
}

*/

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr,
            "uso: %s <modo> <input>\n"
            "  modos: safe | wrapper | decay\n",
            argv[0]);
        return 1;
    }

    const char *mode  = argv[1];
    const char *input = argv[2];

    if      (!strcmp(mode, "safe"))    safe(input);
    else if (!strcmp(mode, "wrapper")) wrapper(input);
    else if (!strcmp(mode, "decay"))   decay(input);

    /* Ativação dos casos extras para o desafio do Nível 3: 
    else if (!strcmp(mode, "dynamic")) dynamic_check(input, 32);
    else if (!strcmp(mode, "ghost"))   { g_buf = malloc(32); ghost_check(input); }
    */

    else {
        fprintf(stderr, "modo inválido: %s\n", mode);
        return 1;
    }

    return 0;
}
