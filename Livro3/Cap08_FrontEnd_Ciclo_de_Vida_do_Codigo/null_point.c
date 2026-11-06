#include <stdio.h>

typedef struct { int uid; int flags; } Session;

int get_uid(Session *s) {
    if (s == NULL) {
        return -1;
    }
    return s->uid + s->flags;
}

int main() {
    Session s = {1000, 0x7};
    printf("uid legítimo : %d\n", get_uid(&s));
    printf("uid nulo     : %d\n", get_uid(NULL));
    return 0;
}
