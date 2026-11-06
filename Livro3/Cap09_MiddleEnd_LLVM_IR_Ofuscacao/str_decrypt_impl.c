#include <stdint.h>

void __str_decrypt(char *dst, const char *src, int len, uint8_t key) {
    for (int i = 0; i < len; i++)
        dst[i] = src[i] ^ key;
}
