"""
log_service.py
──────────────
ดึง logs จาก BA_TOOL backend (external) แบบ dedup ด้วย last_seen_id
เพื่อให้ polling ส่งเฉพาะ entries ใหม่เท่านั้น
"""

import httpx
from typing import List
from app.schemas.schemas import LogEntry

BA_TOOL_URL = "https://ba-tool-backend.onrender.com"

# เก็บ id สุดท้ายที่เคยส่งไปแล้ว — ป้องกัน append ซ้ำ
_last_seen_id: int = 0


async def get_all_logs() -> List[LogEntry]:
    """ดึง logs ทั้งหมด (ใช้สำหรับ initial load)"""
    global _last_seen_id
    entries = await _fetch_raw()
    if entries:
        _last_seen_id = max(e.id for e in entries)
    return entries


async def get_new_logs() -> List[LogEntry]:
    """ดึงเฉพาะ logs ที่ id > _last_seen_id (ใช้สำหรับ polling)"""
    global _last_seen_id
    all_entries = await _fetch_raw()
    new_entries = [e for e in all_entries if e.id > _last_seen_id]
    if new_entries:
        _last_seen_id = max(e.id for e in new_entries)
    return new_entries


async def _fetch_raw() -> List[LogEntry]:
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            res = await client.get(f"{BA_TOOL_URL}/logs")
            res.raise_for_status()
            data = res.json()
    except Exception:
        return []

    raw_list: list = []
    if isinstance(data, list):
        raw_list = data
    elif isinstance(data, dict):
        raw_list = data.get("logs") or data.get("data") or []

    logs: List[LogEntry] = []
    for i, entry in enumerate(raw_list):
        if isinstance(entry, str):
            parts = entry.split("]", 1)
            if len(parts) == 2:
                ts_part = parts[0].replace("[", "").strip()
                rest    = parts[1].strip()
                words   = rest.split(" ", 1)
                level   = words[0] if words else "INFO"
                message = words[1] if len(words) > 1 else rest
            else:
                ts_part, level, message = "", "INFO", entry
            logs.append(LogEntry(id=i + 1, timestamp=ts_part, level=level.upper(), message=message))
        elif isinstance(entry, dict):
            logs.append(LogEntry(
                id=entry.get("id", i + 1),
                timestamp=entry.get("timestamp", entry.get("created_at", "")),
                level=str(entry.get("level", "INFO")).upper(),
                message=entry.get("message", entry.get("msg", str(entry))),
            ))
    return logs