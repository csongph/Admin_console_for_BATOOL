"""
log_service.py
──────────────
ดึง logs จาก BA Tool backend และ persist ลง batool_logs
"""

import httpx
from typing import List, Iterable
from datetime import datetime, timezone
from sqlalchemy import select

from app.schemas.schemas import LogEntry
from app.db.database import AsyncSessionLocal
from app.db.models import BatoolLog

BA_TOOL_URL = "https://ba-tool-backend.onrender.com"

_last_seen_id: int = 0


def _parse_created_at(ts: str) -> datetime:
    raw = (ts or "").strip()
    if not raw:
        return datetime.now(timezone.utc)
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return datetime.now(timezone.utc)


async def _persist_to_batool_logs(entries: Iterable[LogEntry]) -> None:
    rows: list[BatoolLog] = []
    keys: list[str] = []

    for e in entries:
        external_key = f"batool:{e.id}"
        keys.append(external_key)
        rows.append(BatoolLog(
            level=e.level.upper(),
            message=e.message,
            detail=f"batool_id={e.id}; timestamp={e.timestamp}",
            external_key=external_key,
            created_at=_parse_created_at(e.timestamp),
        ))

    if not rows:
        return

    try:
        async with AsyncSessionLocal() as db:
            existing = await db.execute(
                select(BatoolLog.external_key).where(BatoolLog.external_key.in_(keys))
            )
            seen = {r for r in existing.scalars().all() if r}
            for row in rows:
                if row.external_key in seen:
                    continue
                db.add(row)
            await db.commit()
    except Exception:
        return


async def get_all_logs() -> List[LogEntry]:
    global _last_seen_id
    entries = await _fetch_raw()
    if entries:
        await _persist_to_batool_logs(entries)
        _last_seen_id = max(e.id for e in entries)
    return entries


async def get_new_logs() -> List[LogEntry]:
    global _last_seen_id
    all_entries = await _fetch_raw()
    new_entries = [e for e in all_entries if e.id > _last_seen_id]
    if new_entries:
        await _persist_to_batool_logs(new_entries)
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
