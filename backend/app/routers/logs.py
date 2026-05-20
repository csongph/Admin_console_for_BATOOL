from fastapi import APIRouter, Depends

from app.schemas.schemas import APIResponse
from app.services import log_service
from app.core.security import get_current_user

router = APIRouter(tags=["Logs"])


@router.get("/logs", response_model=APIResponse)
async def get_logs(current_user: dict = Depends(get_current_user)):
    """ดึง logs ทั้งหมด — ใช้ตอน initial load"""
    logs = await log_service.get_all_logs()
    return APIResponse(
        success=True,
        message="Logs retrieved successfully",
        data=[log.dict() for log in logs],
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