import httpx
from typing import List
from app.schemas.schemas import LogEntry

BA_TOOL_URL = "https://ba-tool-backend.onrender.com"


async def get_all_logs() -> List[LogEntry]:
    async with httpx.AsyncClient(timeout=10) as client:
        res = await client.get(f"{BA_TOOL_URL}/logs")
        res.raise_for_status()
        data = res.json()

    logs = []
    # รองรับทั้ง list ตรงๆ และ {"logs": [...]} หรือ {"data": [...]}
    if isinstance(data, list):
        raw_list = data
    elif isinstance(data, dict):
        raw_list = data.get("logs") or data.get("data") or []
    else:
        raw_list = []

    for i, entry in enumerate(raw_list):
        if isinstance(entry, str):
            # parse "[2026-05-19 06:31:49] INFO message"
            parts = entry.split("]", 1)
            if len(parts) == 2:
                ts_part = parts[0].replace("[", "").strip()
                rest = parts[1].strip()
                words = rest.split(" ", 1)
                level = words[0] if words else "INFO"
                message = words[1] if len(words) > 1 else rest
            else:
                ts_part = ""
                level = "INFO"
                message = entry
            logs.append(LogEntry(
                id=i + 1,
                timestamp=ts_part,
                level=level.upper(),
                message=message,
            ))
        elif isinstance(entry, dict):
            logs.append(LogEntry(
                id=entry.get("id", i + 1),
                timestamp=entry.get("timestamp", entry.get("created_at", "")),
                level=str(entry.get("level", "INFO")).upper(),
                message=entry.get("message", entry.get("msg", str(entry))),
            ))

    return logs