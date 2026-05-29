from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.services import log_service
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import AdminUser

router = APIRouter(tags=["Logs"])


async def _require_admin(
    current_user: dict         = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
) -> dict:
    username = current_user.get("username", "")
    result   = await db.execute(select(AdminUser).where(AdminUser.username == username))
    user     = result.scalar_one_or_none()
    if not user or user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")
    return current_user


@router.get("/logs", response_model=APIResponse)
async def get_logs(current_user: dict = Depends(get_current_user)):
    """ดึง logs ทั้งหมด — ใช้ตอน initial load"""
    logs = await log_service.get_all_logs()
    return APIResponse(
        success=True,
        message="Logs retrieved successfully",
        data=[log.dict() for log in logs],
    )


@router.delete("/logs", response_model=APIResponse)
async def clear_logs(current_user: dict = Depends(_require_admin)):
    """ล้าง log ที่แสดงใน Log Viewer (batool_logs cache)"""
    deleted = await log_service.clear_display_logs()
    return APIResponse(
        success=True,
        message=f"Cleared {deleted} log(s)",
        data={"deleted": deleted},
    )


@router.get("/logs/new", response_model=APIResponse)
async def get_new_logs(current_user: dict = Depends(get_current_user)):
    """ดึงเฉพาะ logs ใหม่ที่ยังไม่เคยส่ง — ใช้สำหรับ polling"""
    logs = await log_service.get_new_logs()
    return APIResponse(
        success=True,
        message=f"{len(logs)} new log(s)",
        data=[log.dict() for log in logs],
    )
