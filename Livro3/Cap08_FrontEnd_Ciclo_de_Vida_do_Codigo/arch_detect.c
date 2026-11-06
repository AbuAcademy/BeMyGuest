/* arch_detect.c */
#include <stdio.h>

int main() {

    /* Detecção de Arquitetura (CPU) */
    #if defined(__x86_64__) || defined(__amd64__)
        printf("[+] Arch: x86-64 (Servers / Desktops modernos)\n");
    #elif defined(__i386__)
        printf("[+] Arch: x86-32 (Legado / Embedded)\n");
    #elif defined(__arm__)
        printf("[+] Arch: ARM (Mobile / IoT)\n");
    #elif defined(__aarch64__)
        printf("[+] Arch: ARM64 (Mobile moderno / Apple Silicon)\n");
    #else
        printf("[!] Arch: Unknown\n");
    #endif

    /* Detecção de Endianness (crítico para exploits de rede) */
    #if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
        printf("[+] Memory: Little Endian\n");
    #else
        printf("[+] Memory: Big Endian\n");
    #endif

    return 0;
}
