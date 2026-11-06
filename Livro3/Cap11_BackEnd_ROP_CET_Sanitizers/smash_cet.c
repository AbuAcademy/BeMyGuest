#include <stdio.h>

void smash() {
    printf("[*] Função chamada legitimamente.\n");
    
    // Pega o endereço de retorno na Stack Normal e corrompe
    void **ret_addr = (void **)__builtin_frame_address(0) + 1;
    printf("[*] Corrompendo endereço de retorno normal de %p para 0xbebacafe\n", *ret_addr);
    *ret_addr = (void *)0xbebacafe;
    
    printf("[*] Executando RET... Shadow Stack vai gritar agora!\n");
}

int main() {
    smash();
    printf("[-] Você nunca verá esta mensagem.\n");
    return 0;
}
