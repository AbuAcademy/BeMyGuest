#!/bin/bash

# Script para analisar context switches com perf sched (v6.14+)

echo "=== Perf Sched: Análise de Context Switches ==="
echo "Perf version: $(perf --version)"
echo ""

# Verifica se cs_cena4 está rodando
if ! pidof cs_cena4 > /dev/null; then
    echo "ERRO: cs_cena4 não está rodando!"
    echo "Execute em outro terminal: sudo ./cs_cena4"
    exit 1
fi

PID=$(pidof cs_cena4)
echo "PID encontrado: $PID"

PERF=$(which perf)
if [ -z "$PERF" ]; then
    echo "ERRO: perf não encontrado"
    exit 1
fi

# Cria diretório para resultados
mkdir -p perf_results
cd perf_results

# Remove perf.data antigo se existir
rm -f perf.data

echo ""
echo "📊 Registrando eventos de scheduler por 15 segundos..."
echo "(Aguarde...)"
sudo $PERF sched record -p $PID sleep 15 2>/dev/null

if [ ! -f perf.data ]; then
    echo "ERRO: Falha ao registrar"
    exit 1
fi

echo "✅ Registro completo!"
echo ""

# Gera relatórios em arquivos
echo "📄 Gerando relatórios..."

echo "1️⃣  Gerando: latency.txt"
sudo $PERF sched latency > latency.txt 2>&1

echo "2️⃣  Gerando: map.txt (timeline visual)"
sudo $PERF sched map > map.txt 2>&1

echo "3️⃣  Gerando: script.txt (todos os eventos)"
sudo $PERF sched script > script.txt 2>&1

echo "4️⃣  Gerando: script_filtered.txt (apenas cs_cena4)"
grep -E "(cs_cena4|sched_switch)" script.txt > script_filtered.txt 2>&1

echo "5️⃣  Gerando: stats.txt (estatísticas)"
{
    echo "=== ESTATÍSTICAS DE CONTEXT SWITCHES ==="
    echo ""
    echo "Total de eventos sched_switch:"
    grep -c "sched_switch" script_filtered.txt
    echo ""
    echo "Eventos do cs_cena4:"
    grep -c "cs_cena4" script_filtered.txt
    echo ""
    echo "Primeiros 30 eventos sched_switch:"
    echo ""
    grep "sched_switch" script_filtered.txt | head -30
} > stats.txt 2>&1

echo ""
echo "✅ Relatórios gerados!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Arquivos em: perf_results/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 LATENCY.TXT:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -40 latency.txt
echo ""
echo "[... arquivo completo]"
echo ""

echo "📈 MAP.TXT (Timeline):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -40 map.txt
echo ""
echo "[... arquivo completo]"
echo ""

echo "📊 STATS.TXT:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat stats.txt
echo ""

echo "📝 SCRIPT_FILTERED.TXT (cs_cena4 events):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -40 script_filtered.txt
echo ""
echo "[... arquivo completo]"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Comandos úteis para análise:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ver latência de todas as tasks:"
echo "  cat perf_results/latency.txt"
echo ""
echo "Ver timeline visual (qual task rodava quando):"
echo "  cat perf_results/map.txt"
echo ""
echo "Ver estatísticas:"
echo "  cat perf_results/stats.txt"
echo ""
echo "Ver todos os sched_switch:"
echo "  grep sched_switch perf_results/script_filtered.txt | less"
echo ""
echo "Contar quantos context switches:"
echo "  grep -c sched_switch perf_results/script_filtered.txt"
echo ""
echo "Ver preempções (prev_comm -> next_comm):"
echo "  grep sched_switch perf_results/script_filtered.txt | cut -d' ' -f5- | head -30"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Análise concluída!"
