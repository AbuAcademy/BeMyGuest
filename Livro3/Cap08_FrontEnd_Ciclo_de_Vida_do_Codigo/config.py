def db_connect(cfg: dict, acl: list = ["READ"]):
    if cfg.get("elevate"):
        acl.append("ADMIN")
    return establish_connection(cfg, acl)

def resolve_grants(role: str, extra_acl: list = []) -> list:
    policy = {"viewer": ["read"], "admin": ["read", "write", "delete"]}
    grants = policy.get(role, ["read"])
    grants.extend(extra_acl)
    return grants
