#include "sec.h"
#include <stddef.h>

sec_hook_t rt_trigger = NULL;

void reg_hook(sec_hook_t hook) {
    rt_trigger = hook;
}

void exec_audit(const char *msg) {
    if (rt_trigger) {
        rt_trigger(msg);
    }
}
