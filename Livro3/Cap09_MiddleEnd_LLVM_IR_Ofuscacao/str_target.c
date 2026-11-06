#include <stdio.h>
#include <string.h>

void connect(void) {
    const char *url    = "http://attacker.com/beacon";
    const char *token  = "Bearer eyJhbGciOiJSUzI1NiJ9.secret";
    const char *method = "POST";
    printf("--> Conectando em %s\n", url);
    printf("--> Token: %s\n", token);
    printf("--> Método: %s\n", method);
}

int main(void) {
    connect();
    return 0;
}
