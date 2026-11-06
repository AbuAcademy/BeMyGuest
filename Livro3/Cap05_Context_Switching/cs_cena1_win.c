#include <windows.h>
#include <stdio.h>
#include <processthreadsapi.h>
#include <stdint.h>

// Função que consome 100% CPU
DWORD WINAPI cpu_bound_worker(LPVOID param) {
    int thread_id = (int)(intptr_t)param;
    printf("[THREAD %d] Started - Running CPU-bound loop...\n", thread_id);
    printf("[THREAD %d] PID: %lu, TID: %lu\n", thread_id, GetCurrentProcessId(), GetCurrentThreadId());
    
    volatile uint64_t counter = 0;
    
    while (1) {
        counter++;
        
        // Print progress every 500 million iterations
        if (counter % 500000000 == 0) {
            printf("[THREAD %d] Counter: %llu\n", thread_id, counter);
        }
    }
    
    return 0;
}

int main() {
    printf("\n");
    printf("PID: %lu\n", GetCurrentProcessId());
    printf("Press Ctrl+C to stop.\n\n");
    
    HANDLE threads[4];
    
    // Create 4 CPU-bound threads
    for (int i = 0; i < 4; i++) {
        threads[i] = CreateThread(
            NULL,                      // Security attributes
            0,                         // Default stack size
            cpu_bound_worker,          // Thread function
            (LPVOID)(intptr_t)i,       // Parameter - cast int to LPVOID properly
            0,                         // Creation flags (run immediately)
            NULL                       // Thread ID output
        );
        
        if (threads[i] == NULL) {
            printf("ERROR: CreateThread failed for thread %d\n", i);
            return 1;
        }
    }
    
    // Wait for all threads (they won't exit in this scenario)
    WaitForMultipleObjects(4, threads, TRUE, INFINITE);
    
    // Cleanup (unreachable in this case)
    for (int i = 0; i < 4; i++) {
        CloseHandle(threads[i]);
    }
    
    return 0;
}