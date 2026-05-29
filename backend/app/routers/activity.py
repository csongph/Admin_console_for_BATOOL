import json
import logging
from typing import Optional
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, desc, func, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import UpdateActivity, AdminUser, SystemSetting

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Activities"])


# ─── Guards ───────────────────────────────────────────────────────────────────

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


# ─── Schemas ──────────────────────────────────────────────────────────────────

class ActivityCreate(BaseModel):
    username:    str
    action:      str
    target_type: str    = "mapping"
    target_id:   Optional[str] = None
    summary:     str    = ""
    detail:      Optional[dict] = None


# ─── Helper ที่ router อื่นเรียกใช้ ──────────────────────────────────────────

async def record_activity(
    db:          AsyncSession,
    username:    str,
    action:      str,
    target_type: str = "mapping",
    target_id:   Optional[str] = None,
    summary:     str = "",
    detail:      Optional[dict] = None,
) -> UpdateActivity:
    act = UpdateActivity(
        username    = username,
        action      = action,
        target_type = target_type,
        target_id   = str(target_id) if target_id is not None else None,
        summary     = summary,
        detail      = json.dumps(detail, ensure_ascii=False) if detail else None,
        created_at  = datetime.now(timezone.utc),
    )
    db.add(act)
    return act


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/activities", response_model=APIResponse)
async def get_activities(
    username:    Optional[str] = Query(None),
    action:      Optional[str] = Query(None),
    target_type: Optional[str] = Query(None),
    limit:       int           = Query(50, ge=1, le=200),
    offset:      int           = Query(0,  ge=0),
    db:          AsyncSession  = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    q = select(UpdateActivity).order_by(desc(UpdateActivity.created_at))
    if username:    q = q.where(UpdateActivity.username    == username)
    if action:      q = q.where(UpdateActivity.action      == action)
    if target_type: q = q.where(UpdateActivity.target_type == target_type)

    count_q = select(func.count()).select_from(q.subquery())
    total   = (await db.execute(count_q)).scalar_one()

    q = q.limit(limit).offset(offset)
    rows = (await db.execute(q)).scalars().all()

    return APIResponse(
        success = True,
        message = f"{total} activity record(s)",
        data    = {
            "total":      total,
            "limit":      limit,
            "offset":     offset,
            "activities": [r.to_dict() for r in rows],
        },
    )


# ── FIX: /activities/clear ต้องอยู่ก่อน /activities/{activity_id} ──────────
@router.delete("/activities/clear", response_model=APIResponse)
async def clear_activities(
    before:       Optional[str] = Query(None, description="ISO datetime — ลบ log ที่เก่ากว่านี้ ถ้าไม่ระบุ = ลบทั้งหมด"),
    db:           AsyncSession  = Depends(get_db),
    current_user: dict          = Depends(require_admin),
):
    q = delete(UpdateActivity)

    cutoff_dt: Optional[datetime] = None
    if before:
        try:
            cutoff_dt = datetime.fromisoformat(before.replace("Z", "+00:00"))
        except ValueError:
            raise HTTPException(status_code=422, detail=f"before ไม่ใช่ ISO datetime ที่ถูกต้อง: {before!r}")
        q = q.where(UpdateActivity.created_at < cutoff_dt)

    result = await db.execute(q)
    await db.commit()

    deleted = result.rowcount
    msg = f"ลบ {deleted} activity record(s)"
    if cutoff_dt:
        msg += f" ที่เก่ากว่า {cutoff_dt.isoformat()}"
    else:
        msg += " (ทั้งหมด)"

    logger.info("[clear_activities] %s by %s", msg, current_user.get("username"))
    return APIResponse(success=True, message=msg, data={"deleted": deleted})


# ── Activity auto-clear schedule (server-side) ───────────────────────────────

KEY_ACTIVITY_SCHEDULE_ENABLED = "activity_schedule_enabled"
KEY_ACTIVITY_SCHEDULE_DAYS    = "activity_schedule_days"
KEY_ACTIVITY_SCHEDULE_LAST    = "activity_schedule_last_run"

_ACTIVITY_DEFAULTS = {
    KEY_ACTIVITY_SCHEDULE_ENABLED: "false",
    KEY_ACTIVITY_SCHEDULE_DAYS:    "7",
    KEY_ACTIVITY_SCHEDULE_LAST:    "",
}


async def _activity_setting(db: AsyncSession, key: str) -> str:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    return row.value if row else _ACTIVITY_DEFAULTS.get(key, "")


async def _set_activity_setting(db: AsyncSession, key: str, value: str) -> None:
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == key))
    row = result.scalar_one_or_none()
    if row:
        row.value = value
    else:
        db.add(SystemSetting(key=key, value=value))


class ActivityRetentionRequest(BaseModel):
    enabled:       bool
    interval_days: int = 7


@router.get("/activities/retention", response_model=APIResponse)
async def get_activity_retention(
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    enabled = await _activity_setting(db, KEY_ACTIVITY_SCHEDULE_ENABLED)
    days_raw = await _activity_setting(db, KEY_ACTIVITY_SCHEDULE_DAYS)
    last_run = await _activity_setting(db, KEY_ACTIVITY_SCHEDULE_LAST)
    try:
        days = max(1, int(days_raw or "7"))
    except ValueError:
        days = 7
    return APIResponse(
        success=True,
        message="Activity retention settings",
        data={
            "enabled":       enabled == "true",
            "interval_days": days,
            "last_run":      last_run or None,
        },
    )


@router.put("/activities/retention", response_model=APIResponse)
async def set_activity_retention(
    body:         ActivityRetentionRequest,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    days = max(1, min(body.interval_days, 365))
    await _set_activity_setting(db, KEY_ACTIVITY_SCHEDULE_ENABLED, "true" if body.enabled else "false")
    await _set_activity_setting(db, KEY_ACTIVITY_SCHEDULE_DAYS, str(days))
    await db.commit()
    return APIResponse(
        success=True,
        message="Activity schedule saved",
        data={"enabled": body.enabled, "interval_days": days},
    )


async def run_scheduled_activity_clear(db: AsyncSession) -> Optional[dict]:
    """เรียกจาก log retention scheduler — ลบ activity เก่ากว่า interval_days"""
    enabled = await _activity_setting(db, KEY_ACTIVITY_SCHEDULE_ENABLED)
    if enabled != "true":
        return None

    days_raw = await _activity_setting(db, KEY_ACTIVITY_SCHEDULE_DAYS)
    last_raw = await _activity_setting(db, KEY_ACTIVITY_SCHEDULE_LAST)
    try:
        interval_days = max(1, int(days_raw or "7"))
    except ValueError:
        interval_days = 7

    now = datetime.now(timezone.utc)
    if last_raw:
        try:
            last_dt = datetime.fromisoformat(last_raw.replace("Z", "+00:00"))
            if (now - last_dt).total_seconds() < interval_days * 86400:
                return None
        except ValueError:
            pass

    cutoff = now - timedelta(days=interval_days)
    result = await db.execute(
        delete(UpdateActivity).where(UpdateActivity.created_at < cutoff)
    )
    await _set_activity_setting(db, KEY_ACTIVITY_SCHEDULE_LAST, now.isoformat())
    await db.commit()
    deleted = result.rowcount
    logger.info("[activity-retention] Deleted %d records older than %s days", deleted, interval_days)
    return {"deleted": deleted, "interval_days": interval_days}


# ── /activities/{activity_id} ต้องอยู่หลัง /activities/clear เสมอ ──────────
@router.get("/activities/{activity_id}", response_model=APIResponse)
async def get_activity_detail(
    activity_id:  int,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(UpdateActivity).where(UpdateActivity.id == activity_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Activity not found")

    data = record.to_dict()
    if data["detail"]:
        try:
            data["detail"] = json.loads(data["detail"])
        except Exception:
            pass

    return APIResponse(success=True, message="Activity detail", data=data)


@router.post("/activities", response_model=APIResponse, include_in_schema=False)
async def create_activity_direct(
    body:         ActivityCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    act = await record_activity(
        db          = db,
        username    = body.username,
        action      = body.action,
        target_type = body.target_type,
        target_id   = body.target_id,
        summary     = body.summary,
        detail      = body.detail,
    )
    await db.commit()
    await db.refresh(act)
    return APIResponse(success=True, message="Activity recorded", data=act.to_dict())