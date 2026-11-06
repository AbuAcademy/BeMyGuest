#include <string.h>

void wrapper(char *dst, const char *src) {
    strcpy(dst, src); 	// Esta chamada será compilada sem Fortify
}
