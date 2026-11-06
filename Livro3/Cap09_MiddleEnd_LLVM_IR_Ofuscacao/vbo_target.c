#include <stdio.h>

// Função alvo da nossa VM. 
int check_auth(int key) {
    int secret = (key * 2) + 1337;
    if (secret == 2027) {
        return 1;
    }
    return 0;
}

int main() {
    int user_key;
    printf("Digite a chave secreta: ");
    scanf("%d", &user_key);

    if (check_auth(user_key)) {
        printf("Acesso Garantido!\n");
    } else {
        printf("Acesso Negado.\n");
    }

    return 0;
}
