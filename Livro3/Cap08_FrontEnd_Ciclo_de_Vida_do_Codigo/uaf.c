#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int  uid;
    int  priv_level;
    char username[32];
} Principal;

int main(void) {
    Principal *s = malloc(sizeof(Principal));
    if (!s) return 1;

    s->uid        = 1000;
    s->priv_level = 0;
    strncpy(s->username, "abu", sizeof(s->username) - 1);

    fprintf(stderr, "--> s @ %p  uid=%d priv=%d user=%s\n",
            (void *)s, s->uid, s->priv_level, s->username);

    free(s);   /* session closed — dangling pointer lives on */

    fprintf(stderr, "[uaf] read after free: uid=%d priv=%d user=%s\n",
            s->uid, s->priv_level, s->username);

    /* attacker wins the chunk via heap reclaim */
    Principal *ghost = malloc(sizeof(Principal));
    ghost->uid        = 31337;
    ghost->priv_level = 9;
    strncpy(ghost->username, "r00t", sizeof(ghost->username) - 1);

    fprintf(stderr, "--> ghost @ %p  uid=%d priv=%d user=%s\n",
            (void *)ghost, ghost->uid, ghost->priv_level, ghost->username);
    fprintf(stderr, "[uaf] s still sees: uid=%d priv=%d user=%s\n",
            s->uid, s->priv_level, s->username);

    free(ghost);
    return 0;
}
