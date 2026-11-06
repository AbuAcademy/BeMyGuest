#include <stdio.h>

int soma(int a, int b) {		// Esta é a callee (quem é chamada)

    int resultado = a + b;
    return resultado;
}

int main() {				// Esta é a caller (quem chama)
    int valor = 71;  		// valor “importante”
    int resultado = soma(51, 69);
    
//    printf("Resultado: %d, Valor: %d\n", resultado, valor);
    return 0;
}
