"""
system_service.py
─────────────────
เก็บ system state ใน DB ผ่าน SystemSetting model
แทนที่จะเก็บใน memory ซึ่งหายทุกครั้งที่ server restart
"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import SystemSetting


_STATUS_KEY      = "system_status"
_MAINTENANCE_KEY = "maintenance_mode"
_DEFAULT         = "stopped"
_DEFAULT_SETTINGS = {
    "sec_session_timeout": "60",
    "sec_min_pw_len": "6",
    "sec_max_attempts": "5",
    "rl_max_req_min": "300",
    "rl_bulk_limit": "5000",
    "rl_sync_interval": "300",
    "rl_max_retry": "3",
}


async def get_status(db: AsyncSession) -> dict:
    row = await _get_setting(db, _STATUS_KEY)
    return {"status": row}


async def start_system(db: AsyncSession) -> dict:
    await _set_setting(db, _STATUS_KEY, "running")
    return {"status": "running"}


async def stop_system(db: AsyncSession) -> dict:
    await _set_setting(db, _STATUS_KEY, "stopped")
    return {"status": "stopped"}


# ── Maintenance Mode ───────────────────────────────────────────────────────────

async def get_maintenance(db: AsyncSession) -> dict:
    value = await _get_setting(db, _MAINTENANCE_KEY)
    return {"maintenance": value == "true"}


async def set_maintenance(db: AsyncSession, enabled: bool) -> dict:
    await _set_setting(db, _MAINTENANCE_KEY, "true" if enabled else "false")
    return {"maintenance": enabled}


async def is_maintenance_active(db: AsyncSession) -> bool:
    value = await _get_setting(db, _MAINTENANCE_KEY)
    return value == "true"


async def get_settings(db: AsyncSession) -> dict:
    result = await db.execute(
        select(SystemSetting).where(SystemSetting.key.in_(_DEFAULT_SETTINGS.keys()))
    )
    rows = result.scalars().all()
    values = dict(_DEFAULT_SETTINGS)
    values.update({row.key: row.value for row in rows})
    return values


async def set_settings(db: AsyncSession, values: dict[str, str]) -> dict:
    saved = {}
    for key, value in values.items():
        if key not in _DEFAULT_SETTINGS:
            continue
        text_value = str(value)
        await _set_setting(db, key, text_value, commit=False)
        saved[key] = text_value
    await db.commit()
    current = await get_settings(db)
    return {**current, **saved}


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _get_setting(db: AsyncSession, key: str) -> str:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    return row.value if row else _DEFAULT


async def _set_setting(db: AsyncSession, key: str, value: str, commit: bool = True) -> None:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    if row:
        row.value = value
    else:
        db.add(SystemSetting(key=key, value=value))
    if commit:
        await db.commit()
