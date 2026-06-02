"""
routers/admin_logs.py
─────────────────────
Log แยกตาราง:
  batool_logs         → BA Tool backend
  admin_console_logs  → Admin Console backend

Endpoints:
  GET    /api/admin-logs              → ดึง log (log_type=batool|admin|all)
  GET    /api/admin-logs/retention    → ตั้งค่า retention
  PUT    /api/admin-logs/retention
  DELETE /api/admin-logs/clear        → ลบ log (log_type=batool|admin|all)
"""
import logging
from typing import Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, desc, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import AdminUser, BatoolLog, AdminConsoleLog
from app.middleware.logging_middleware import get_recent_request_logs, clear_recent_request_logs
from app.services import log_retention_service

logger = logging.getLogger(__name__)
router = APIRouter(tags=["AdminLogs"])


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


class LogCreate(BaseModel):
    level:   str = "INFO"
    message: str
    detail:  Optional[str] = None


class RetentionUpdate(BaseModel):
    enabled:        Optional[bool] = None
    retention_days: Optional[int]  = None
    interval_hours: Optional[int]  = None


def _get_caller_source_file(depth: int = 2) -> str:
    """
    ดึงชื่อไฟล์ + บรรทัดของ caller จริง โดยใช้ inspect.stack()
    depth=2 → caller ของ caller (ข้าม write_admin_console_log เอง)
    คืนค่าในรูป 'routers/admin_logs.py:118'
    """
    import inspect, os
    try:
        stack = inspect.stack()
        if len(stack) > depth:
            frame_info = stack[depth]
            pathname = frame_info.filename or ""
            if "app" + os.sep in pathname:
                rel = pathname.split("app" + os.sep, 1)[-1]
            else:
                rel = os.path.basename(pathname)
            return f"{rel}:{frame_info.lineno}"
    except Exception:
        pass
    return "unknown"


async def write_admin_console_log(
    db:          AsyncSession,
    level:       str,
    message:     str,
    detail:      Optional[str] = None,
    source_file: Optional[str] = None,
) -> None:
    # ถ้าไม่ได้ส่ง source_file มา ให้ auto-detect จาก call stack
    if source_file is None:
        source_file = _get_caller_source_file(depth=2)
    entry = AdminConsoleLog(
        level       = level.upper(),
        message     = message,
        detail      = detail,
        source_file = source_file,
        created_at  = datetime.now(timezone.utc),
    )
    db.add(entry)


def _scope_from_query(log_type: Optional[str]) -> str:
    return log_retention_service._normalize_scope(log_type)


async def _fetch_batool_logs(db: AsyncSession, level: Optional[str], limit: int, offset: int):
    q = select(BatoolLog).order_by(desc(BatoolLog.created_at))
    if level:
        q = q.where(BatoolLog.level == level.upper())
    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(count_q)).scalar_one()
    rows = (await db.execute(q.limit(limit).offset(offset))).scalars().all()
    return total, [r.to_dict() for r in rows]


async def _fetch_admin_logs(db: AsyncSession, level: Optional[str], limit: int, offset: int):
    q = select(AdminConsoleLog).order_by(desc(AdminConsoleLog.created_at))
    if level:
        q = q.where(AdminConsoleLog.level == level.upper())
    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(count_q)).scalar_one()
    rows = (await db.execute(q.limit(limit).offset(offset))).scalars().all()
    return total, [r.to_dict() for r in rows]


@router.get("/admin-logs/retention", response_model=APIResponse)
async def get_log_retention(
    db: AsyncSession = Depends(get_db),
    _:  dict          = Depends(require_admin),
):
    data = await log_retention_service.get_retention_settings(db)
    return APIResponse(success=True, message="Log retention settings", data=data)


@router.put("/admin-logs/retention", response_model=APIResponse)
async def update_log_retention(
    body: RetentionUpdate,
    db:   AsyncSession = Depends(get_db),
    current_user: dict = Depends(require_admin),
):
    data = await log_retention_service.set_retention_settings(
        db,
        enabled=body.enabled,
        retention_days=body.retention_days,
        interval_hours=body.interval_hours,
    )
    logger.info("[admin-logs] retention updated by %s: %s", current_user.get("username"), data)
    return APIResponse(success=True, message="บันทึกการตั้งเวลาลบ log แล้ว", data=data)


@router.post("/admin-logs/retention/run", response_model=APIResponse)
async def run_log_retention_now(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(require_admin),
):
    result = await log_retention_service.run_scheduled_retention(db)
    return APIResponse(success=True, message="รัน retention แล้ว", data=result)


@router.delete("/admin-logs/clear", response_model=APIResponse)
async def clear_admin_logs(
    before:   Optional[str] = Query(None),
    days:     Optional[int] = Query(None, ge=0, le=3650),
    log_type: Optional[str] = Query(None, description="batool | admin | all"),
    source:   Optional[str] = Query(None, description="alias ของ log_type (backward compat)"),
    db:       AsyncSession  = Depends(get_db),
    current_user: dict      = Depends(require_admin),
):
    scope_param = log_type or source
    cutoff_dt: Optional[datetime] = None
    if before:
        try:
            cutoff_dt = datetime.fromisoformat(before.replace("Z", "+00:00"))
        except ValueError:
            raise HTTPException(status_code=422, detail=f"before ไม่ถูกต้อง: {before!r}")

    retention_days = None
    if cutoff_dt is None and days is not None and days > 0:
        retention_days = days

    if cutoff_dt is not None:
        result = await log_retention_service.purge_logs(
            db, before=cutoff_dt, log_type=scope_param
        )
    elif days == 0:
        result = await log_retention_service.purge_logs(db, log_type=scope_param)
    elif retention_days is not None:
        result = await log_retention_service.purge_logs(
            db, retention_days=retention_days, log_type=scope_param
        )
    else:
        result = await log_retention_service.purge_logs(db, log_type=scope_param)

    logger.info(
        "[admin-logs] cleared by %s scope=%s deleted=%s",
        current_user.get("username"),
        result.get("scope"),
        result.get("deleted"),
    )
    return APIResponse(
        success=True,
        message=f"ลบ {result.get('deleted', 0)} log(s)",
        data=result,
    )


@router.get("/admin-logs", response_model=APIResponse)
async def get_admin_logs(
    level:    Optional[str] = Query(None),
    log_type: Optional[str] = Query("all", description="batool | admin | all"),
    source:   Optional[str] = Query(None, description="alias ของ log_type"),
    limit:    int           = Query(200, ge=1, le=500),
    offset:   int           = Query(0,   ge=0),
    db:       AsyncSession  = Depends(get_db),
    _:        dict          = Depends(require_admin),
):
    scope = _scope_from_query(log_type if log_type != "all" else source or "all")
    logs: list[dict] = []
    total = 0

    if scope == "batool":
        total, logs = await _fetch_batool_logs(db, level, limit, offset)
    elif scope == "admin":
        total, logs = await _fetch_admin_logs(db, level, limit, offset)
        if not logs:
            memory = list(reversed(get_recent_request_logs(limit=limit)))
            logs = memory
            total = len(logs)
    else:
        batool_total, batool_rows = await _fetch_batool_logs(db, level, limit + offset, 0)
        admin_total, admin_rows = await _fetch_admin_logs(db, level, limit + offset, 0)
        merged = sorted(
            batool_rows + admin_rows,
            key=lambda x: x.get("created_at") or "",
            reverse=True,
        )
        logs = merged[offset: offset + limit]
        total = batool_total + admin_total

    return APIResponse(
        success=True,
        message=f"{total} log(s)",
        data={
            "total":    total,
            "limit":    limit,
            "offset":   offset,
            "log_type": scope,
            "logs":     logs,
        },
    )


@router.post("/admin-logs", response_model=APIResponse, include_in_schema=False)
async def create_log_direct(
    body: LogCreate,
    db:   AsyncSession = Depends(get_db),
    _:    dict         = Depends(get_current_user),
):
    await write_admin_console_log(db, body.level, body.message, body.detail)
    await db.commit()
    return APIResponse(success=True, message="logged")