#include <string.h>

// Função exportada pela biblioteca compartilhada
int check_auth(const char *passwd) {
    return strcmp(passwd, "s3cr3t_p4ss") == 0;
}
