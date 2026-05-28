import json
import logging
from typing import Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, desc, func, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import UpdateActivity, AdminUser

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
    action:      str                   # create | update | delete | bulk_import
    target_type: str    = "mapping"
    target_id:   Optional[str] = None
    summary:     str    = ""
    detail:      Optional[dict] = None  # ข้อมูลละเอียด (before/after)


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
    """บันทึก activity — เรียกจาก router อื่น ไม่ต้อง commit (caller commit เอง)"""
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
    username:    Optional[str] = Query(None, description="กรองตาม username"),
    action:      Optional[str] = Query(None, description="create|update|delete|bulk_import"),
    target_type: Optional[str] = Query(None),
    limit:       int           = Query(50,  ge=1, le=200),
    offset:      int           = Query(0,   ge=0),
    db:          AsyncSession  = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    """ดึงรายการ Update Activities (เรียงจากใหม่สุด)"""
    q = select(UpdateActivity).order_by(desc(UpdateActivity.created_at))

    if username:    q = q.where(UpdateActivity.username    == username)
    if action:      q = q.where(UpdateActivity.action      == action)
    if target_type: q = q.where(UpdateActivity.target_type == target_type)

    # count total
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


@router.get("/activities/{activity_id}", response_model=APIResponse)
async def get_activity_detail(
    activity_id:  int,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    """ดูรายละเอียด activity เดี่ยว — รวม before/after snapshot"""
    result = await db.execute(select(UpdateActivity).where(UpdateActivity.id == activity_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Activity not found")

    data = record.to_dict()
    # parse detail JSON ถ้ามี
    if data["detail"]:
        try:
            data["detail"] = json.loads(data["detail"])
        except Exception:
            pass

    return APIResponse(success=True, message="Activity detail", data=data)


@router.delete("/activities/clear", response_model=APIResponse)
async def clear_activities(
    before:       Optional[str] = Query(None, description="ISO datetime — ลบ log ที่เก่ากว่านี้ ถ้าไม่ระบุ = ลบทั้งหมด"),
    db:           AsyncSession  = Depends(get_db),
    current_user: dict          = Depends(require_admin),
):
    """
    ลบ Update Activity log
    - ไม่ระบุ before → ลบทั้งหมด
    - ระบุ before (ISO 8601) → ลบเฉพาะที่ created_at < before
    """
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


@router.post("/activities", response_model=APIResponse, include_in_schema=False)
async def create_activity_direct(
    body:         ActivityCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    """Internal endpoint — บันทึก activity โดยตรง"""
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