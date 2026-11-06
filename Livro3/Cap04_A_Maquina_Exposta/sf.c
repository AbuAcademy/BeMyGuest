#include <stdio.h>

long calc(long a, long b) {
    
    // Variáveis locais
    long soma = a + b;
    long sub = a - b;
    
    return soma;
}

int main() {
    long x = 10;
    long y = 5;
    
    long resultado = calc(x, y);
    
    return 0;
}
