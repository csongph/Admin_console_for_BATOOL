"""
log_retention_service.py
────────────────────────
จัดการ retention / ลบ log เก่าใน batool_logs และ admin_console_logs
"""

import logging
from datetime import datetime, timezone, timedelta
from typing import Optional, Literal

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import SystemSetting, BatoolLog, AdminConsoleLog
from app.middleware.logging_middleware import clear_recent_request_logs

logger = logging.getLogger(__name__)

LogScope = Literal["batool", "admin", "all"]

KEY_ENABLED        = "log_retention_enabled"
KEY_DAYS           = "log_retention_days"
KEY_INTERVAL_HOURS = "log_retention_interval_hours"
KEY_LAST_RUN       = "log_retention_last_run"

DEFAULTS = {
    KEY_ENABLED:        "false",
    KEY_DAYS:           "30",
    KEY_INTERVAL_HOURS: "24",
    KEY_LAST_RUN:       "",
}


async def _get_setting(db: AsyncSession, key: str) -> str:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    return row.value if row else DEFAULTS.get(key, "")


async def _set_setting(db: AsyncSession, key: str, value: str, commit: bool = True) -> None:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    if row:
        row.value = value
    else:
        db.add(SystemSetting(key=key, value=value))
    if commit:
        await db.commit()


async def get_retention_settings(db: AsyncSession) -> dict:
    enabled = await _get_setting(db, KEY_ENABLED)
    days_raw = await _get_setting(db, KEY_DAYS)
    interval_raw = await _get_setting(db, KEY_INTERVAL_HOURS)
    last_run = await _get_setting(db, KEY_LAST_RUN)

    try:
        days = max(1, int(days_raw or DEFAULTS[KEY_DAYS]))
    except ValueError:
        days = int(DEFAULTS[KEY_DAYS])

    try:
        interval_hours = max(1, int(interval_raw or DEFAULTS[KEY_INTERVAL_HOURS]))
    except ValueError:
        interval_hours = int(DEFAULTS[KEY_INTERVAL_HOURS])

    next_run = ""
    if enabled == "true" and last_run:
        try:
            last_dt = datetime.fromisoformat(last_run.replace("Z", "+00:00"))
            next_dt = last_dt + timedelta(hours=interval_hours)
            next_run = next_dt.isoformat()
        except ValueError:
            pass

    return {
        "enabled":          enabled == "true",
        "retention_days":   days,
        "interval_hours":   interval_hours,
        "last_run":         last_run or None,
        "next_run":         next_run or None,
    }


async def set_retention_settings(
    db: AsyncSession,
    *,
    enabled: Optional[bool] = None,
    retention_days: Optional[int] = None,
    interval_hours: Optional[int] = None,
) -> dict:
    if enabled is not None:
        await _set_setting(db, KEY_ENABLED, "true" if enabled else "false", commit=False)
    if retention_days is not None:
        await _set_setting(db, KEY_DAYS, str(max(1, retention_days)), commit=False)
    if interval_hours is not None:
        await _set_setting(db, KEY_INTERVAL_HOURS, str(max(1, interval_hours)), commit=False)
    await db.commit()
    return await get_retention_settings(db)


def _normalize_scope(log_type: Optional[str]) -> LogScope:
    if log_type in ("batool", "batool-backend"):
        return "batool"
    if log_type in ("admin", "admin-console", "admin-backend"):
        return "admin"
    return "all"


async def _purge_table(db: AsyncSession, model, cutoff: Optional[datetime]) -> int:
    q = delete(model)
    if cutoff is not None:
        q = q.where(model.created_at < cutoff)
    result = await db.execute(q)
    return result.rowcount or 0


async def purge_logs(
    db: AsyncSession,
    *,
    before: Optional[datetime] = None,
    retention_days: Optional[int] = None,
    log_type: Optional[str] = None,
    clear_memory: bool = True,
) -> dict:
    """ลบ log จากตารางที่เลือก — batool | admin | all"""
    scope = _normalize_scope(log_type)
    cutoff = before
    if cutoff is None and retention_days is not None:
        cutoff = datetime.now(timezone.utc) - timedelta(days=max(1, retention_days))

    batool_deleted = 0
    admin_deleted = 0

    if scope in ("batool", "all"):
        batool_deleted = await _purge_table(db, BatoolLog, cutoff)
    if scope in ("admin", "all"):
        admin_deleted = await _purge_table(db, AdminConsoleLog, cutoff)

    await db.commit()

    memory_deleted = 0
    if clear_memory and scope in ("admin", "all"):
        memory_deleted = clear_recent_request_logs()

    total = batool_deleted + admin_deleted
    return {
        "deleted": total,
        "batool_deleted": batool_deleted,
        "admin_deleted": admin_deleted,
        "memory_deleted": memory_deleted,
        "cutoff": cutoff.isoformat() if cutoff else None,
        "scope": scope,
    }


async def run_scheduled_retention(db: AsyncSession) -> dict:
    settings = await get_retention_settings(db)
    if not settings["enabled"]:
        return {"skipped": True, "reason": "disabled"}

    now = datetime.now(timezone.utc)
    interval = timedelta(hours=settings["interval_hours"])
    last_run_raw = settings.get("last_run")

    if last_run_raw:
        try:
            last_run = datetime.fromisoformat(last_run_raw.replace("Z", "+00:00"))
            if now - last_run < interval:
                return {"skipped": True, "reason": "not_due", "next_run": settings.get("next_run")}
        except ValueError:
            pass

    result = await purge_logs(
        db,
        retention_days=settings["retention_days"],
        log_type="all",
        clear_memory=True,
    )
    await _set_setting(db, KEY_LAST_RUN, now.isoformat())
    logger.info(
        "[log-retention] batool=%d admin=%d retention=%dd",
        result["batool_deleted"],
        result["admin_deleted"],
        settings["retention_days"],
    )
    return {"skipped": False, **result, "retention_days": settings["retention_days"]}
