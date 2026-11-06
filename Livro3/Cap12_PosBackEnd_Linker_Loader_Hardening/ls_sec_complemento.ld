SECTIONS
{
    .text.security :
    {
         KEEP(*(.text.audit_log))
         KEEP(*(.text.check_failed))
    }
}

/* Complemento: estende o script padrão do linker (ver acompanhamento p.698). */
INSERT AFTER .text;
