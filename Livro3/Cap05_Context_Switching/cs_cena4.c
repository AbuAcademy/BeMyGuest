#define _GNU_SOURCE
#include <stdio.h>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

volatile int running = 1;

// Função para fixar thread em um core específico
void set_cpu_affinity(int cpu) {
    cpu_set_t set;
    CPU_ZERO(&set);
    CPU_SET(cpu, &set);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &set);
}

// Função para definir prioridade FIFO
void set_fifo_priority(int priority) {
    struct sched_param param;
    param.sched_priority = priority;
    
    if (sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
        fprintf(stderr, "Erro ao definir FIFO: %s\n", strerror(errno));
    } else {
        printf("[ALTA] SCHED_FIFO com prioridade %d aplicado!\n", priority);
    }
}

void* low_priority_worker(void* arg) {
    set_cpu_affinity(0);
    printf("[BAIXA] Iniciada (ID: %lu) - SCHED_OTHER\n", pthread_self());
    
    while (running) {
        for (volatile long i = 0; i < 1000000000; i++);
    }
    return NULL;
}

void* high_priority_worker(void* arg) {
    set_cpu_affinity(0);
    set_fifo_priority(50);  // Aplica SCHED_FIFO com prioridade 50
    printf("[ALTA] Iniciada (ID: %lu)\n", pthread_self());
    
    while (running) {
        // sem sleep... apenas loop rápido para preemptar constantemente
        for (volatile long i = 0; i < 10000000; i++);
    }
    return NULL;
}

int main() {
    printf("=== Simulando Context Switches com SCHED_FIFO ===\n");
    printf("PID: %d\n\n", getpid());
    
    pthread_t low_thread, high_thread;

    // Thread de baixa prioridade (SCHED_OTHER padrão)
    int ret = pthread_create(&low_thread, NULL, low_priority_worker, NULL);
    if (ret != 0) {
        fprintf(stderr, "Erro thread baixa: %s\n", strerror(ret));
        return 1;
    }

    sleep(2);

    // Thread de alta prioridade
    ret = pthread_create(&high_thread, NULL, high_priority_worker, NULL);
    if (ret != 0) {
        fprintf(stderr, "Erro ao criar thread alta: %s\n", strerror(ret));
        running = 0;
        pthread_join(low_thread, NULL);
        return 1;
    }

    printf("\n=== Vai rodar por 15 segundos ===\n");

    sleep(15);
    running = 0;

    pthread_join(low_thread, NULL);
    pthread_join(high_thread, NULL);

    return 0;
}
