#include <stdio.h>

int main() { 
   unsigned char xelcold[] =
       "\xeb\x1e"                  // jmp <string> 
      // <_write>: 
      "\xbf\x01\x00\x00\x00"      // mov  edi, 0x1 (arg1: fd = stdout) 
      "\x5e"                      // pop  rsi (captura o ponteiro da string) 
      "\xba\x06\x00\x00\x00"      // mov  edx, 0x6 (arg3: count = 6 bytes) 
      "\xb8\x01\x00\x00\x00"      // mov  eax, 0x1 (syscall sys_write) 
      "\x0f\x05"                  // syscall 

      // <_exit>: 
      "\xb8\x3c\x00\x00\x00"      // mov  eax, 0x3c (syscall sys_exit) 
      "\xbf\x00\x00\x00\x00"      // xor  edi, edi (arg1: status = 0) 
      "\x0f\x05"                  // syscall 

      // <string>: 
      "\xe8\xdd\xff\xff\xff"      // call <_write> (empilha o RIP atual e pula) 
      "Aloha\n";                  // String injetada na seção .text

   void (*ret)() = (void(*)())xelcold; 
   ret(); 
   return 0; 
} 
