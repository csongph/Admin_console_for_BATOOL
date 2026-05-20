"""
system_service.py
─────────────────
เก็บ system state ใน DB ผ่าน SystemSetting model
แทนที่จะเก็บใน memory ซึ่งหายทุกครั้งที่ server restart
"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import SystemSetting


_STATUS_KEY = "system_status"
_DEFAULT    = "stopped"


async def get_status(db: AsyncSession) -> dict:
    row = await _get_setting(db, _STATUS_KEY)
    return {"status": row}


async def start_system(db: AsyncSession) -> dict:
    await _set_setting(db, _STATUS_KEY, "running")
    return {"status": "running"}


async def stop_system(db: AsyncSession) -> dict:
    await _set_setting(db, _STATUS_KEY, "stopped")
    return {"status": "stopped"}


async def _get_setting(db: AsyncSession, key: str) -> str:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    return row.value if row else _DEFAULT


async def _set_setting(db: AsyncSession, key: str, value: str) -> None:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    if row:
        row.value = value
    else:
        db.add(SystemSetting(key=key, value=value))
    await db.commit()