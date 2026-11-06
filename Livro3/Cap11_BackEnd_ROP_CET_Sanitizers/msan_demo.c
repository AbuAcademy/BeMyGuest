#include <stdio.h>
#include <stdlib.h>

int vuln(int x) {
    int result;              // memoria não inicializada
    if (x > 0)
        result = x * 2;
    // se x <= 0, 'result' fica com lixo da stack
    return result;           // MSan detecta uso de valor não-inicializado
}

int main(void) {
    // msan intercepta o valor lixo alimentando o printf
    printf("%d\n", vuln(-1));  // resultado não-determinístico
    return 0;
}
