#!/bin/bash

# Script para monitorar context switches das threads de cs_cena4

PID=$(pidof cs_cena4)

if [ -z "$PID" ]; then
    echo "Erro: cs_cena4 não está rodando!"
    echo "Execute em outro terminal: sudo ./cs_cena4"
    exit 1
fi

echo "PID encontrado: $PID"
sleep 1

# Pega os TIDs das threads
echo "Aguardando threads serem criadas..."
sleep 2

THREADS=$(ls /proc/$PID/task/ 2>/dev/null | grep -v $PID | head -3)

if [ -z "$THREADS" ]; then
    echo "Erro: Não conseguiu encontrar as threads!"
    exit 1
fi

# Converte para array
THREAD_ARRAY=($THREADS)
echo "Threads encontradas: ${THREAD_ARRAY[@]}"

if [ ${#THREAD_ARRAY[@]} -lt 2 ]; then
    echo "Erro: Esperava 2 threads, encontrou ${#THREAD_ARRAY[@]}"
    exit 1
fi

THREAD_LOW=${THREAD_ARRAY[0]}
THREAD_HIGH=${THREAD_ARRAY[1]}

echo ""
echo "=== Monitorando Context Switches ==="
echo "Thread BAIXA (TS):  $THREAD_LOW"
echo "Thread ALTA (FF):   $THREAD_HIGH"
echo ""

# Cria arquivo temporário com o comando
cat > /tmp/watch_cs_cmd.sh << 'EOF'
#!/bin/bash
PID=$1
THREAD_LOW=$2
THREAD_HIGH=$3

echo "========================"
date +%H:%M:%S
echo "========================"
echo ""
echo "--- THREAD BAIXA (SCHED_OTHER) ---"
grep -E 'voluntary_ctxt_switches|nonvoluntary_ctxt_switches' /proc/$PID/task/$THREAD_LOW/status
echo ""
echo "--- THREAD ALTA (SCHED_FIFO) ---"
grep -E 'voluntary_ctxt_switches|nonvoluntary_ctxt_switches' /proc/$PID/task/$THREAD_HIGH/status
echo ""
echo "--- TOTAL ---"
awk '/voluntary_ctxt_switches/{v += $2} /nonvoluntary_ctxt_switches/{n += $2} END {print "Total voluntary: " v "\nTotal nonvoluntary: " n}' /proc/$PID/task/*/status
EOF

chmod +x /tmp/watch_cs_cmd.sh

# Monitora com watch
watch -n 0.2 "/tmp/watch_cs_cmd.sh $PID $THREAD_LOW $THREAD_HIGH"
