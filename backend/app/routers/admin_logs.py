"""
routers/admin_logs.py
─────────────────────
เก็บ log ระบบของ admin ลงฐานข้อมูล (SystemLog table)
แยกจาก UpdateActivity ที่เก็บ user action

Endpoints:
  GET  /api/admin-logs          → ดึง system log ทั้งหมด (admin เท่านั้น)
  POST /api/admin-logs          → บันทึก log (internal helper)
  DELETE /api/admin-logs/clear  → ลบ log เก่า (admin เท่านั้น)
"""
import logging
from typing import Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, desc, delete, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import AdminUser, SystemLog
from app.middleware.logging_middleware import get_recent_request_logs, clear_recent_request_logs

logger = logging.getLogger(__name__)
router = APIRouter(tags=["AdminLogs"])


# ─── Guard ────────────────────────────────────────────────────────────────────

async def require_admin(
    current_user: dict       = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
) -> dict:
    username = current_user.get("username", "")
    result   = await db.execute(select(AdminUser).where(AdminUser.username == username))
    user     = result.scalar_one_or_none()
    if not user or user.role != "admin":
        raise HTTPException(status_code=403, detail="ต้องเป็น Admin เท่านั้น")
    return current_user


# ─── Schema ───────────────────────────────────────────────────────────────────

class LogCreate(BaseModel):
    level:   str = "INFO"    # INFO | WARN | ERROR | DEBUG
    source:  str = "system"  # system | auth | sync | mapping | ...
    message: str
    detail:  Optional[str] = None


# ─── Helper (ใช้ใน router อื่น) ──────────────────────────────────────────────

async def write_system_log(
    db:      AsyncSession,
    level:   str,
    source:  str,
    message: str,
    detail:  Optional[str] = None,
) -> None:
    """บันทึก system log — เรียกจาก router อื่น, caller commit เอง"""
    entry = SystemLog(
        level      = level.upper(),
        source     = source,
        message    = message,
        detail     = detail,
        created_at = datetime.now(timezone.utc),
    )
    db.add(entry)


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/admin-logs", response_model=APIResponse)
async def get_admin_logs(
    level:   Optional[str] = Query(None, description="INFO|WARN|ERROR|DEBUG"),
    source:  Optional[str] = Query(None),
    limit:   int           = Query(200, ge=1, le=500),
    offset:  int           = Query(0,   ge=0),
    db:      AsyncSession  = Depends(get_db),
    _:       dict          = Depends(require_admin),
):
    """ดึง System Log ทั้งหมด (เรียงจากใหม่สุด)"""
    q = select(SystemLog).order_by(desc(SystemLog.created_at))
    if level:  q = q.where(SystemLog.level  == level.upper())
    if source: q = q.where(SystemLog.source == source)

    count_q = select(func.count()).select_from(q.subquery())
    total   = (await db.execute(count_q)).scalar_one()

    q    = q.limit(limit).offset(offset)
    rows = (await db.execute(q)).scalars().all()
    logs = [r.to_dict() for r in rows]

    # Fallback: if DB has no rows yet after deploy/restart, return in-memory recent request logs
    if not logs:
        memory_logs = get_recent_request_logs(limit=limit)
        logs = list(reversed(memory_logs))
        total = len(logs)

    return APIResponse(
        success = True,
        message = f"{total} log(s)",
        data    = {
            "total":  total,
            "limit":  limit,
            "offset": offset,
            "logs":   logs,
        },
    )


@router.delete("/admin-logs/clear", response_model=APIResponse)
async def clear_admin_logs(
    before:  Optional[str] = Query(None, description="ISO datetime — ลบที่เก่ากว่า"),
    db:      AsyncSession  = Depends(get_db),
    current_user: dict     = Depends(require_admin),
):
    q = delete(SystemLog)
    cutoff_dt: Optional[datetime] = None
    if before:
        try:
            cutoff_dt = datetime.fromisoformat(before.replace("Z", "+00:00"))
        except ValueError:
            raise HTTPException(status_code=422, detail=f"before ไม่ถูกต้อง: {before!r}")
        q = q.where(SystemLog.created_at < cutoff_dt)

    result  = await db.execute(q)
    await db.commit()
    deleted = result.rowcount
    memory_deleted = clear_recent_request_logs()
    logger.info("[admin-logs] cleared %d log(s) by %s", deleted, current_user.get("username"))
    return APIResponse(
        success=True,
        message=f"ลบ {deleted} log(s)",
        data={"deleted": deleted, "memory_deleted": memory_deleted},
    )


@router.post("/admin-logs", response_model=APIResponse, include_in_schema=False)
async def create_log_direct(
    body: LogCreate,
    db:   AsyncSession = Depends(get_db),
    _:    dict         = Depends(get_current_user),
):
    """Internal — บันทึก log โดยตรง"""
    await write_system_log(db, body.level, body.source, body.message, body.detail)
    await db.commit()
    return APIResponse(success=True, message="logged")