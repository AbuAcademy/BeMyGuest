#include "sec.h"
#include <stdio.h>
#include <stdlib.h>

void audit_log(const char *event) {
    // Simula gravação crítica para SIEM corporativo
    printf("[AUDIT SIEM]: ALERT -> %s\n", event);
}

void check_failed(void) {
    audit_log("CRITICAL: Permission denied");
    exit(1);
}
