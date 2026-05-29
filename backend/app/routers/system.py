"""
routers/system.py
─────────────────
System control endpoints + Maintenance Mode

Endpoints:
  GET  /api/system/status           → สถานะระบบ
  POST /api/system/start            → start system
  POST /api/system/stop             → stop system
  GET  /api/system/maintenance      → ดูสถานะ maintenance (ทุกคนเรียกได้ เพื่อให้ฝั่ง user ตรวจได้)
  POST /api/system/maintenance      → toggle maintenance (admin เท่านั้น)
"""

import logging
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Dict
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.services import system_service
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import AdminUser

logger = logging.getLogger(__name__)
router = APIRouter(tags=["System"])


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

class MaintenanceRequest(BaseModel):
    enabled: bool
    reason:  str = ""   # optional — แสดงใน banner ฝั่ง user


# ─── Routes ───────────────────────────────────────────────────────────────────

class SettingsRequest(BaseModel):
    settings: Dict[str, str]


@router.get("/status", response_model=APIResponse)
async def get_status(
    current_user: dict         = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
):
    data = await system_service.get_status(db)
    return APIResponse(success=True, message="Status retrieved", data=data)


@router.post("/start", response_model=APIResponse)
async def start_system(
    current_user: dict         = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
):
    data = await system_service.start_system(db)
    return APIResponse(success=True, message="System started", data=data)


@router.post("/stop", response_model=APIResponse)
async def stop_system(
    current_user: dict         = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
):
    data = await system_service.stop_system(db)
    return APIResponse(success=True, message="System stopped", data=data)


# ── Maintenance ────────────────────────────────────────────────────────────────

@router.get("/settings/public", response_model=APIResponse)
async def get_public_settings(db: AsyncSession = Depends(get_db)):
    """Public — ค่าที่ login page / client ต้องใช้ (ไม่ต้อง auth)"""
    from app.services import auth_service
    data = await auth_service.get_public_auth_settings(db)
    return APIResponse(success=True, message="Public settings", data=data)


@router.get("/settings", response_model=APIResponse)
async def get_settings(
    current_user: dict         = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
):
    data = await system_service.get_settings(db)
    return APIResponse(success=True, message="Settings retrieved", data=data)


@router.put("/settings", response_model=APIResponse)
async def update_settings(
    body:         SettingsRequest,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    data = await system_service.set_settings(db, body.settings)
    logger.info("System settings updated by admin %s", current_user["username"])
    return APIResponse(success=True, message="Settings updated", data=data)


@router.get("/maintenance", response_model=APIResponse)
async def get_maintenance(db: AsyncSession = Depends(get_db)):
    """
    Public endpoint — ไม่ต้อง login
    ให้ฝั่ง user / BATOOL polling ตรวจสอบสถานะได้โดยไม่ต้องมี token
    """
    data = await system_service.get_maintenance(db)
    return APIResponse(success=True, message="Maintenance status", data=data)


@router.post("/maintenance", response_model=APIResponse)
async def set_maintenance(
    body:         MaintenanceRequest,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(require_admin),
):
    """Admin only — toggle maintenance mode"""
    data = await system_service.set_maintenance(db, body.enabled)

    # บันทึก reason ถ้ามี (เก็บใน SystemSetting ด้วย)
    if body.reason.strip():
        from app.db.models import SystemSetting
        result = await db.execute(
            select(SystemSetting).where(SystemSetting.key == "maintenance_reason")
        )
        row = result.scalar_one_or_none()
        if row:
            row.value = body.reason.strip()
        else:
            db.add(SystemSetting(key="maintenance_reason", value=body.reason.strip()))
        await db.commit()

    state = "เปิด" if body.enabled else "ปิด"
    logger.info("Maintenance mode %s by admin %s", state, current_user["username"])
    return APIResponse(
        success=True,
        message=f"Maintenance mode {state}ใช้งานแล้ว",
        data={**data, "reason": body.reason},
    )


@router.get("/maintenance/reason", response_model=APIResponse)
async def get_maintenance_reason(db: AsyncSession = Depends(get_db)):
    """Public — ดึง reason ที่ admin กรอก"""
    from app.db.models import SystemSetting
    result = await db.execute(
        select(SystemSetting).where(SystemSetting.key == "maintenance_reason")
    )
    row = result.scalar_one_or_none()
    return APIResponse(
        success=True,
        message="Maintenance reason",
        data={"reason": row.value if row else ""},
    )
