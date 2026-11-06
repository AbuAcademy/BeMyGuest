#ifndef SEC_H
#define SEC_H
typedef void (*sec_hook_t)(const char *event);
extern sec_hook_t rt_trigger;
void reg_hook(sec_hook_t hook);
void exec_audit(const char *msg);
#endif
