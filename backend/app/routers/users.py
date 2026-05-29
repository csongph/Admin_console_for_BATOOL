"""
routers/users.py
────────────────
Admin จัดการผู้ใช้ระบบ — สร้าง / แก้ไข / ลบ / reset password
ทุก endpoint ต้อง login ก่อน (get_current_user) และต้องเป็น admin role

Endpoints:
  GET    /api/users               → list ผู้ใช้ทั้งหมด
  POST   /api/users               → สร้างผู้ใช้ใหม่
  PUT    /api/users/{id}          → แก้ไข role / display_name / is_active
  POST   /api/users/{id}/reset-password → reset password
  DELETE /api/users/{id}          → ลบผู้ใช้ (ลบตัวเองไม่ได้)
"""
import logging
from typing import Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, field_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user, get_password_hash
from app.db.database import get_db
from app.db.models import AdminUser
from app.services import auth_service
from app.routers.activity import record_activity

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Users"])

VALID_ROLES = {"admin", "editor", "viewer"}


# ─── Guard: ต้องเป็น admin ────────────────────────────────────────────────────

async def require_admin(
    current_user: dict      = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
) -> dict:
    username = current_user.get("username", "")
    result   = await db.execute(select(AdminUser).where(AdminUser.username == username))
    user     = result.scalar_one_or_none()
    if not user or user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="คุณไม่มีสิทธิ์ดำเนินการนี้ — ต้องเป็น Admin เท่านั้น",
        )
    return current_user


# ─── Schemas ──────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    username:     str
    password:     str
    role:         str = "viewer"
    display_name: str = ""

    @field_validator("username")
    @classmethod
    def clean_username(cls, v: str) -> str:
        v = v.strip().lower()
        if not v:
            raise ValueError("username ต้องไม่ว่าง")
        if len(v) < 3:
            raise ValueError("username ต้องมีอย่างน้อย 3 ตัวอักษร")
        if len(v) > 64:
            raise ValueError("username ยาวเกิน 64 ตัวอักษร")
        import re
        if not re.match(r'^[a-z0-9_\-.]+$', v):
            raise ValueError("username ใช้ได้เฉพาะ a-z, 0-9, _, -, .")
        return v

    @field_validator("password")
    @classmethod
    def check_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("password ต้องมีอย่างน้อย 6 ตัวอักษร")
        return v

    @field_validator("role")
    @classmethod
    def check_role(cls, v: str) -> str:
        if v not in VALID_ROLES:
            raise ValueError(f"role ต้องเป็น {VALID_ROLES}")
        return v


class UserUpdate(BaseModel):
    role:         Optional[str]  = None
    display_name: Optional[str]  = None
    is_active:    Optional[bool] = None

    @field_validator("role")
    @classmethod
    def check_role(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_ROLES:
            raise ValueError(f"role ต้องเป็น {VALID_ROLES}")
        return v


class ResetPasswordRequest(BaseModel):
    new_password: str

    @field_validator("new_password")
    @classmethod
    def check_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("password ต้องมีอย่างน้อย 6 ตัวอักษร")
        return v


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/users", response_model=APIResponse)
async def list_users(
    db:          AsyncSession = Depends(get_db),
    _:           dict         = Depends(get_current_user),   # login แล้วก็ดูได้
):
    result = await db.execute(select(AdminUser).order_by(AdminUser.created_at))
    rows   = result.scalars().all()
    return APIResponse(
        success = True,
        message = f"{len(rows)} user(s)",
        data    = [r.to_dict() for r in rows],
    )


@router.post("/users", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    body:         UserCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    min_len = await auth_service.min_password_length(db)
    if len(body.password) < min_len:
        raise HTTPException(
            status_code=422,
            detail=f"password ต้องมีอย่างน้อย {min_len} ตัวอักษร",
        )
    # ตรวจซ้ำ
    exist = (await db.execute(select(AdminUser).where(AdminUser.username == body.username))).scalar_one_or_none()
    if exist:
        raise HTTPException(status_code=409, detail=f"Username '{body.username}' มีอยู่แล้ว")

    user = AdminUser(
        username     = body.username,
        hashed_pw    = get_password_hash(body.password),
        role         = body.role,
        display_name = body.display_name.strip(),
        is_active    = True,
        created_at   = datetime.now(timezone.utc),
    )
    db.add(user)
    await db.flush()

    await record_activity(
        db          = db,
        username    = current_user["username"],
        action      = "create",
        target_type = "user",
        target_id   = str(user.id),
        summary     = f"สร้างผู้ใช้ใหม่: {body.username} (role: {body.role})",
        detail      = {"after": user.to_dict()},
    )
    await db.commit()
    await db.refresh(user)

    logger.info("User created: %s by admin %s", body.username, current_user["username"])
    return APIResponse(success=True, message=f"สร้างผู้ใช้ '{body.username}' สำเร็จ", data=user.to_dict())


@router.put("/users/{user_id}", response_model=APIResponse)
async def update_user(
    user_id:      int,
    body:         UserUpdate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    result = await db.execute(select(AdminUser).where(AdminUser.id == user_id))
    user   = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")

    before = user.to_dict()
    changes: dict = {}

    if body.role is not None and body.role != user.role:
        # ห้าม downgrade ตัวเองออกจาก admin
        if user.username == current_user["username"] and body.role != "admin":
            raise HTTPException(status_code=400, detail="ไม่สามารถเปลี่ยน role ของตัวเองได้")
        # ห้าม downgrade env superadmin
        from app.core.config import settings as _settings
        if user.username == _settings.ADMIN_USERNAME and body.role != "admin":
            raise HTTPException(status_code=400, detail="ไม่สามารถเปลี่ยน role ของ superadmin จาก env ได้")
        changes["role"] = {"from": user.role, "to": body.role}
        user.role = body.role

    if body.display_name is not None:
        changes["display_name"] = {"from": user.display_name, "to": body.display_name.strip()}
        user.display_name = body.display_name.strip()

    if body.is_active is not None and body.is_active != user.is_active:
        if user.username == current_user["username"]:
            raise HTTPException(status_code=400, detail="ไม่สามารถ disable ตัวเองได้")
        changes["is_active"] = {"from": user.is_active, "to": body.is_active}
        user.is_active = body.is_active

    await record_activity(
        db          = db,
        username    = current_user["username"],
        action      = "update",
        target_type = "user",
        target_id   = str(user_id),
        summary     = f"แก้ไขผู้ใช้: {user.username} ({', '.join(changes.keys())})" if changes else f"แก้ไขผู้ใช้: {user.username}",
        detail      = {"before": before, "changes": changes, "after": user.to_dict()},
    )
    await db.commit()
    await db.refresh(user)

    logger.info("User updated: id=%s by admin %s", user_id, current_user["username"])
    return APIResponse(success=True, message="อัปเดตผู้ใช้สำเร็จ", data=user.to_dict())


@router.post("/users/{user_id}/reset-password", response_model=APIResponse)
async def reset_password(
    user_id:      int,
    body:         ResetPasswordRequest,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    result = await db.execute(select(AdminUser).where(AdminUser.id == user_id))
    user   = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")

    min_len = await auth_service.min_password_length(db)
    if len(body.new_password) < min_len:
        raise HTTPException(
            status_code=422,
            detail=f"password ต้องมีอย่างน้อย {min_len} ตัวอักษร",
        )

    user.hashed_pw = get_password_hash(body.new_password)

    await record_activity(
        db          = db,
        username    = current_user["username"],
        action      = "update",
        target_type = "user",
        target_id   = str(user_id),
        summary     = f"Reset password ของ {user.username}",
        detail      = {"action": "reset_password", "target_user": user.username},
    )
    await db.commit()

    logger.info("Password reset: user=%s by admin %s", user.username, current_user["username"])
    return APIResponse(success=True, message=f"Reset password ของ '{user.username}' สำเร็จ")


@router.delete("/users/{user_id}", response_model=APIResponse)
async def delete_user(
    user_id:      int,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    result = await db.execute(select(AdminUser).where(AdminUser.id == user_id))
    user   = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")
    if user.username == current_user["username"]:
        raise HTTPException(status_code=400, detail="ไม่สามารถลบตัวเองได้")

    # ป้องกันลบ env superadmin
    from app.core.config import settings as _settings
    if user.username == _settings.ADMIN_USERNAME:
        raise HTTPException(status_code=400, detail="ไม่สามารถลบ superadmin จาก env ได้")

    data = user.to_dict()
    await db.delete(user)

    await record_activity(
        db          = db,
        username    = current_user["username"],
        action      = "delete",
        target_type = "user",
        target_id   = str(user_id),
        summary     = f"ลบผู้ใช้: {data['username']} (role: {data['role']})",
        detail      = {"before": data},
    )
    await db.commit()

    logger.info("User deleted: %s by admin %s", data["username"], current_user["username"])
    return APIResponse(success=True, message=f"ลบผู้ใช้ '{data['username']}' สำเร็จ", data=data)