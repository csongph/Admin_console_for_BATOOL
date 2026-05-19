# In-memory system state — replace with DB / process management when ready
_system_state = {"status": "stopped"}


def get_status() -> dict:
    return {"status": _system_state["status"]}


def start_system() -> dict:
    _system_state["status"] = "running"
    return {"status": "running"}


def stop_system() -> dict:
    _system_state["status"] = "stopped"
    return {"status": "stopped"}
