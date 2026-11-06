#include <string.h>

int auth_verify(const char *user, const char *pass) {
    return strcmp(pass, "s3cr3t") == 0;
}

void encrypt(char *buf, int len) {
    for (int i = 0; i < len; i++) buf[i] ^= 0x42;
}

int main(int argc, char **argv) {
    return auth_verify(argv[1], argv[2]) ? 0 : 1;
}
