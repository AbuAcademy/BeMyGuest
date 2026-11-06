#include <stdio.h>
#include <stdlib.h>

void owned() {
    printf("Exploit: Função owned() chamada!\n");
}

void vuln(int x, int s) {
    int res = x << s; 	// UB se s >= 32
    
    if (s == 32) {
        owned();
    }
    printf("Resultado do shift: %d\n", res);
}

int main(int argc, char **argv) {
    if (argc < 2) return 1;
    vuln(1, atoi(argv[1]));
    return 0;
}
