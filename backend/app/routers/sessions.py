from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import SessionRecord

router = APIRouter(tags=["Sessions"])


# ─── Schemas ──────────────────────────────────────────────────────────────────

class SessionCreate(BaseModel):
    id:          str
    user:        str
    role:        str = "user"
    db:          str
    tables:      int = 0
    ttl_minutes: int = 60


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/sessions", response_model=APIResponse)
async def get_sessions(
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(SessionRecord))
    rows   = result.scalars().all()
    data   = [r.to_dict() for r in rows]

    stats = {
        "active":  sum(1 for s in data if s["status"] == "active"),
        "warning": sum(1 for s in data if s["status"] == "warning"),
        "expired": sum(1 for s in data if s["status"] == "expired"),
    }
    return APIResponse(
        success=True,
        message=f"{len(data)} session(s) retrieved",
        data={"sessions": data, "stats": stats},
    )


@router.post("/sessions", response_model=APIResponse)
async def register_session(
    body:         SessionCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    """Upsert session — ถ้ามีอยู่แล้วให้ reset แทนที่จะ 409"""
    created = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    result  = await db.execute(select(SessionRecord).where(SessionRecord.id == body.id))
    record  = result.scalar_one_or_none()

    if record:
        # อัปเดต session เดิม — reset เวลาและค่าใหม่
        record.user         = body.user
        record.role         = body.role
        record.db           = body.db
        record.tables       = body.tables
        record.ttl_minutes  = body.ttl_minutes
        record.created      = created
        record.status_cache = "active"
        message = "Session refreshed"
    else:
        record  = SessionRecord(**body.dict(), created=created)
        db.add(record)
        message = "Session registered"

    await db.commit()
    await db.refresh(record)
    return APIResponse(success=True, message=message, data=record.to_dict())


@router.delete("/sessions/{session_id}", response_model=APIResponse)
async def revoke_session(
    session_id:   str,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(SessionRecord).where(SessionRecord.id == session_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Session not found")
    data = record.to_dict()
    await db.delete(record)
    await db.commit()
    return APIResponse(success=True, message="Session revoked", data=data)


@router.delete("/sessions", response_model=APIResponse)
async def cleanup_expired(
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result  = await db.execute(select(SessionRecord))
    rows    = result.scalars().all()
    expired = [r for r in rows if r.to_dict()["status"] == "expired"]
    for r in expired:
        await db.delete(r)
    await db.commit()
    return APIResponse(
        success=True,
        message=f"{len(expired)} expired session(s) removed",
        data={"removed": len(expired)},
    )