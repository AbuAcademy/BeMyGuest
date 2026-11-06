#include "sec.h"
#include <stdio.h>
#include <stdlib.h>

__attribute__((used)) __attribute__((noinline))
void audit_log(const char *event) {
    printf("[AUDIT SIEM]: ALERT -> %s\n", event);
}

__attribute__((used)) __attribute__((noinline))
void check_failed(void) {
    audit_log("CRITICAL: Permission denied");
    exit(1);
}
