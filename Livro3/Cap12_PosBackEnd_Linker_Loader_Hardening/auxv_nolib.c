#include <elf.h>
#include <stdint.h>

static inline long sys_write(int fd, const void *buf, unsigned long count) {
    long ret;
    __asm__ __volatile__(
        "syscall"
        : "=a"(ret)
        : "a"(1), "D"(fd), "S"(buf), "d"(count)
        : "rcx", "r11", "memory"
    );
    return ret;
}

static inline void sys_exit(int status) {
    __asm__ __volatile__(
        "syscall"
        :
        : "a"(60), "D"(status)
        : "rcx", "r11"
    );
}

// Converte um número de 64 bits para string hexadecimal na stack
void print_hex(uint64_t val) {
    char buf[19]; // "0x" + 16 chars hexa + "\n"
    buf[0] = '0';
    buf[1] = 'x';
    buf[18] = '\n';
    
    const char *hex_chars = "0123456789abcdef";
    for (int i = 17; i >= 2; i--) {
        buf[i] = hex_chars[val & 0xF];
        val >>= 4;
    }
    sys_write(1, buf, 19);
}

__attribute__((naked)) void _start(void) {
    uint64_t *sp;
    __asm__ __volatile__("mov %%rsp, %0" : "=r"(sp));

    {
        uint64_t argc = *sp;
        uint64_t *envp = sp + 1 + argc + 1;

        while (*envp != 0) {
            envp++;
        }
        envp++; 

        Elf64_auxv_t *auxv = (Elf64_auxv_t *) envp;

        for (; auxv->a_type != AT_NULL; auxv++) {
            if (auxv->a_type == AT_RANDOM) {
                sys_write(1, "AT_RANDOM found at: ", 20);
                // auxv->a_un.a_val contém o endereço de memória apontado pelo kernel
                print_hex((uint64_t)auxv->a_un.a_val);
                break;
            }
        }

        sys_exit(0);
    }
}
