#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
volatile int counter = 0;

void* worker(void* arg) {
    int id = *(int*)arg;

    for (int i = 0; i < 100; i++) {
        pthread_mutex_lock(&lock);  // Tenta pegar o lock. Se estiver ocupado, vira context switch.

        // Simula trabalho lento de propósito na seção crítica.
        counter++;
        printf("[Thread %d] Counter: %d\n", id, counter);
        usleep(10000);  // 10ms

        pthread_mutex_unlock(&lock);
    }

    return NULL;
}

int main() {
    printf("PID: %d - Criando contenção de threads\n", getpid());
    pthread_t threads[10];
    int ids[10];
    
    // Cria 10 threads para brigar por um lock (mesmo mutex)
    for (int i = 0; i < 10; i++) {
        ids[i] = i;
        pthread_create(&threads[i], NULL, worker, &ids[i]);
    }
    
    for (int i = 0; i < 10; i++) {
        pthread_join(threads[i], NULL);
    }
    
    printf("Counter final: %d\n", counter);
    return 0;
}
