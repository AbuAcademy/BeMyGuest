#include <stdio.h>

typedef struct { int uid; int flags; } Session;

// Forçamos o compilador a não eliminar a função via inline
__attribute__((noinline))
int get_uid(Session *s) {
    // Sem checagem — desreferência direta e perigosa!
    return s->uid + s->flags; 
}

int main(int argc, char **argv) {
    Session s = {1000, 0x7};
    printf("uid legítimo : %d\n", get_uid(&s));

    // Opacidade total: o ponteiro só será NULL se argc for menor ou igual a 99
    Session *null_ptr = (argc > 99) ? &s : NULL;
    printf("uid nulo     : %d\n", get_uid(null_ptr));
    
    return 0;
}
