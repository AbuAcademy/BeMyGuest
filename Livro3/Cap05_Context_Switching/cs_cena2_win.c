/* cs_cena2_win.c – I/O blocking context switch (equivalente ao cs_cena2.c Linux) */
#include <windows.h>
#include <stdio.h>
#include <stdint.h>

HANDLE g_pipe_read;
HANDLE g_pipe_write;

/* Produtor: escreve 1 byte por segundo no pipe */
DWORD WINAPI producer(LPVOID param) {
    DWORD written;
    char data = 'A';
    while (1) {
        WriteFile(g_pipe_write, &data, 1, &written, NULL);
        printf("[FILHO] Escrevi no pipe: %c\n", data);
        Sleep(1000);  /* 1 segundo — equivalente ao sleep(1) do Linux */
    }
    return 0;
}

/* Consumidor: bloqueia em ReadFile quando o pipe está vazio */
DWORD WINAPI consumer(LPVOID param) {
    DWORD read_bytes;
    char buf;
    while (1) {
        printf("[PAI] Tentando ler... ");
        fflush(stdout);
        ReadFile(g_pipe_read, &buf, 1, &read_bytes, NULL); /* A mágica: bloqueia aqui */
        printf("OK, li: %c\n", buf);
    }
    return 0;
}

int main() {
    printf("PID: %lu - Lendo de pipe (vai bloquear)...\n",
           GetCurrentProcessId());

    SECURITY_ATTRIBUTES sa = { sizeof(sa), NULL, TRUE };
    if (!CreatePipe(&g_pipe_read, &g_pipe_write, &sa, 0)) {
        printf("CreatePipe falhou: %lu\n", GetLastError());
        return 1;
    }

    HANDLE threads[2];
    threads[0] = CreateThread(NULL, 0, producer, NULL, 0, NULL);
    threads[1] = CreateThread(NULL, 0, consumer, NULL, 0, NULL);

    WaitForMultipleObjects(2, threads, TRUE, INFINITE);

    CloseHandle(g_pipe_read);
    CloseHandle(g_pipe_write);
    return 0;
}
