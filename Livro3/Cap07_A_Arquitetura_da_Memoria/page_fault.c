#include <stdio.h>

int main() {
 	char *ptr = NULL; 	// Ponteiro nulo
 	*ptr = 'A'; 		// Tenta desreferenciar o ponteiro nulo
 	printf("Isso nunca será impresso.\n");

	return 0;
}
