# mem_layout.ps1
# Parser para arquivos .MAP do MSVC
# Compatível com PowerShell 7.6+

$mapFile    = "mem_layout.map"
$runtimeOut = "rt_out.txt"

# ─── Runtime loader ─────────────────────────────────────────
$runtimeData = @{}
if (Test-Path $runtimeOut) {
    foreach ($line in Get-Content $runtimeOut) {
        if ($line -match '^\[(.+?)\]\s*=\s*([\da-fA-F`]+)') {
            $runtimeData[$matches[1].Trim()] = $matches[2].Replace('`','')
        }
    }
}

$mapLines = Get-Content $mapFile

# ─── Preferred load address ─────────────────────────────────
$preferredBase = [uint64]0x140000000
foreach ($line in $mapLines) {
    if ($line -match 'Preferred load address is ([0-9A-Fa-f]+)') {
        $preferredBase = [uint64]("0x" + $matches[1])
        break
    }
}

# ─── Build section base lookup direto da coluna Rva+Base ────
$sectionBase = @{}
foreach ($line in $mapLines) {
    if ($line -match '^\s+([0-9A-Fa-f]{4}):([0-9A-Fa-f]{8})\s+\S+\s+([0-9A-Fa-f]{16})\b') {
        $sn  = [int]("0x$($matches[1])")
        $off = [uint64]("0x$($matches[2])")
        $rvb = [uint64]("0x$($matches[3])")
        if ($rvb -ge $preferredBase -and -not $sectionBase.ContainsKey($sn)) {
            $sectionBase[$sn] = ($rvb - $preferredBase) - $off
        }
    }
}

# ─── Consolida seções lógicas ────────────────────────────────
$logSec   = [System.Collections.Specialized.OrderedDictionary]::new()
$inSect   = $false

foreach ($line in $mapLines) {
    if ($line -match '^\s+Start\s+Length\s+Name\s+Class') { $inSect = $true; continue }
    if (-not $inSect) { continue }
    if ($line -match '^\s+([0-9A-Fa-f]{4}):([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]+)H\s+(\S+)\s+(\S+)') {
        $sn   = [int]("0x$($matches[1])")
        $off  = [uint64]("0x$($matches[2])")
        $len  = [uint64]("0x$($matches[3])")
        $full = $matches[4]
        $base = $full -replace '\$.*',''
        if (-not $logSec.Contains($base)) {
            $logSec[$base] = [PSCustomObject]@{ Sec=$sn; FirstOffset=$off; TotalLen=[uint64]0; Subs=@() }
        }
        $logSec[$base].TotalLen += $len
        $logSec[$base].Subs    += $full
    }
}

# ─── Descrições ─────────────────────────────────────────────
$sectionDesc = @{
    ".text"  = "Código executável"
    ".CRT"   = "Inicialização do runtime C/C++"
    ".rdata" = "Dados somente leitura"
    ".rtc"   = "Runtime checks / debug"
    ".xdata" = "Metadados de unwind / SEH x64"
    ".edata" = "Tabela de exportação (Export Table)"
    ".data"  = "Dados inicializados"
    ".bss"   = "Dados não inicializados (BSS)"
    ".pdata" = "Tabela de funções / unwind x64"
    ".idata" = "Import Address Table (IAT)"
    ".00cfg" = "Metadados do Control Flow Guard (CFG)"
}

# ─── Exibição das seções ─────────────────────────────────────
Write-Host "`n[--- LAYOUT DE SEÇÕES (DO ARQUIVO .MAP) ---]" -ForegroundColor Cyan

foreach ($name in $logSec.Keys) {
    $s    = $logSec[$name]
    $rva  = if ($sectionBase.ContainsKey($s.Sec)) { $sectionBase[$s.Sec] + $s.FirstOffset } else { $null }
    $desc = if ($sectionDesc.ContainsKey($name)) { $sectionDesc[$name] } else { "Seção customizada" }

    Write-Host "`n$name  ($desc)" -ForegroundColor Yellow
    Write-Host "  Seção / Offset  : $($s.Sec):$('{0:X8}' -f $s.FirstOffset)"
    Write-Host "  Tamanho Total   : 0x$($s.TotalLen.ToString('X'))  ($($s.TotalLen) bytes)"

    if ($rva -ne $null) {
        $vaStatic = $preferredBase + $rva
        Write-Host "  RVA             : 0x$($rva.ToString('X'))"
        Write-Host "  VA Estático     : 0x$($vaStatic.ToString('X16'))"
    } else {
        Write-Host "  RVA             : N/A (sem símbolos públicos nesta seção)"
        Write-Host "  VA Estático     : N/A"
    }

    Write-Host "  Subsections     :"
    foreach ($sub in ($s.Subs | Sort-Object -Unique)) {
        Write-Host "      - $sub"
    }
}

# ─── Funções principais ──────────────────────────────────────
Write-Host "`n[--- FUNÇÕES PRINCIPAIS ---]" -ForegroundColor Cyan

foreach ($line in $mapLines) {
    if ($line -match '^\s+([0-9A-Fa-f]{4}):([0-9A-Fa-f]{8})\s+(\S+)\s+([0-9A-Fa-f]{16})\b') {
        $sn     = [int]("0x$($matches[1])")
        $offset = [uint64]("0x$($matches[2])")
        $sym    = $matches[3]
        $rvb    = [uint64]("0x$($matches[4])")
        if ($sym -notin @("main","function")) { continue }

        $rva      = $rvb - $preferredBase
        $vaStatic = $rvb

        Write-Host "`n$sym" -ForegroundColor Yellow
        Write-Host "  Offset na seção : 0x$($offset.ToString('X'))"
        Write-Host "  RVA (real)      : 0x$($rva.ToString('X'))"
        Write-Host "  VA Estático     : 0x$($vaStatic.ToString('X16'))"
    }
}

# ─── Variáveis globais ───────────────────────────────────────
Write-Host "`n[--- VARIÁVEIS GLOBAIS ---]" -ForegroundColor Cyan

$globals = @(
    @{ Name="global_data"; Desc="int → seção .data" },
    @{ Name="global_text"; Desc="char* → seção .data (aponta para string em .rdata)" },
    @{ Name="global_bss";  Desc="int → seção .bss (zerado pelo loader)" }
)

foreach ($g in $globals) {
    foreach ($line in $mapLines) {
        $pat = '^\s+([0-9A-Fa-f]{4}):([0-9A-Fa-f]{8})\s+' + [regex]::Escape($g.Name) + '\s+([0-9A-Fa-f]{16})\b'
        if ($line -match $pat) {
            $offset   = [uint64]("0x$($matches[2])")
            $rvb      = [uint64]("0x$($matches[3])")
            $rva      = $rvb - $preferredBase
            $vaStatic = $rvb

            Write-Host "`n$($g.Name)  ($($g.Desc))" -ForegroundColor Yellow
            Write-Host "  Offset na seção : 0x$($offset.ToString('X'))"
            Write-Host "  RVA (real)      : 0x$($rva.ToString('X'))"
            Write-Host "  VA Estático     : 0x$($vaStatic.ToString('X16'))"
        }
    }
}

# ─── Correlação estático vs runtime ─────────────────────────
Write-Host "`n[--- CORRELAÇÃO ESTÁTICO vs RUNTIME ---]" -ForegroundColor Cyan

foreach ($k in ($runtimeData.Keys | Sort-Object)) {
    Write-Host " $k`t→ Runtime VA: $($runtimeData[$k])"
}

Write-Host "`n[OK] Parser concluído com sucesso." -ForegroundColor Green
