#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int uid;
    int priv;
} session_t;

__attribute__((noinline))
int session_priv(session_t *s) {
    return s->uid + s->priv;
}

__attribute__((noinline))
void session_drop(void) {
    session_t *s = malloc(sizeof(*s));
    if (!s) return;
    
    s->uid = 1000;
    free(s);
    
    // Vetor ASan: Use-After-Free
    printf("[telemetry] stale uid: %d\n", s->uid);
}

int main(int argc, char **argv) {
    if (argc < 2) return 1;

    // Captura o argumento do terminal exatamente como no seu texto original
    char *cmd = argv[1]; 

    if (!strcmp(cmd, "ubsan")) {
        printf("priv: %d\n", session_priv(NULL));
    } else if (!strcmp(cmd, "asan")) {
        session_drop();
    }

    return 0;
}
