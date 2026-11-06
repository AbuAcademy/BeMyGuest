#include "sec.h"
#include <stdio.h>

int main(void) {
    printf("[SYSTEM]: Starting engine...\n");
    // O ponteiro não é amarrado de forma estática
    exec_audit("User session started");
    return 0;
}
