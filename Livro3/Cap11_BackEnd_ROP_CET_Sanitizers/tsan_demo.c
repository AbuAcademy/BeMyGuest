#include <pthread.h>
#include <stdio.h>

static int counter = 0; // compartilhado entre threads

void *increment(void *arg) {
    for (int i = 0; i < 100000; i++)
        counter++;  // read-modify-write não atômico — race condition
    return NULL;
}

int main(void) {
    pthread_t t1, t2;
    pthread_create(&t1, NULL, increment, NULL);
    pthread_create(&t2, NULL, increment, NULL);
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    printf("counter: %d\n", counter); // deveria ser 200000, raramente é
    return 0;
}
