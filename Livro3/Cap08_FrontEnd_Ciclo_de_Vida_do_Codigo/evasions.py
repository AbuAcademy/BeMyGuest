# Evasão 1

def _merge_grants(acl: list, grants: list) -> list:
    acl.extend(grants)
    return acl

def db_connect(cfg: dict, acl: list = ["READ"]):
    if cfg.get("elevate"):
        return _merge_grants(acl, ["ADMIN"])
    return establish_connection(cfg, acl)


# Evasão 2

def db_connect_elevated(cfg: dict, acl: list = ["READ"]):
    if cfg.get("elevate"):
        acl += ["ADMIN"]
    return establish_connection(cfg, acl)


# Evasão 3

def pkt_filter(src_ip: str, dst_port: int, routed_internal: bool) -> bool:
    BLOCKED_IPS    = {"10.0.0.1", "192.168.1.100"}
    ALLOWED_PORTS  = {80, 443, 8080}
    src_blocked    = src_ip in BLOCKED_IPS
    port_violation = dst_port not in ALLOWED_PORTS and not routed_internal
    return src_blocked or port_violation
