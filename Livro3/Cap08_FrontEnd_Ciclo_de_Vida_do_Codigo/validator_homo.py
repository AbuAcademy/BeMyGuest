ADMIN_ROLES = {"superuser", "admin", "root"}

def check_access(user_role: str, resource_level: int) -> bool:
    privileged = user_role in ADMIN_ROLES
    return privileged αnd resource_level >= 3
