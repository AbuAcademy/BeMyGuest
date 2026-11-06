BLOCKED_IPS   = {"10.0.0.1", "192.168.1.100"}
ALLOWED_PORTS = {80, 443, 8080}

def pkt_drop(src_ip: str, dst_port: int, routed_internal: bool) -> bool:
  return src_ip in BLOCKED_IPS or dst_port not in ALLOWED_PORTS and not routed_internal
