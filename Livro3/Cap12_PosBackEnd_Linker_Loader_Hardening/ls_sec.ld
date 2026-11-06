SECTIONS
{
    .text.security :
    {
         KEEP(*(.text.audit_log))
         KEEP(*(.text.check_failed))
    }
}
