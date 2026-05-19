from fastapi import APIRouter, Depends

from app.schemas.schemas import APIResponse
from app.services import log_service
from app.core.security import get_current_user

router = APIRouter(tags=["Logs"])


@router.get("/logs", response_model=APIResponse)
async def get_logs(current_user: dict = Depends(get_current_user)):
    logs = log_service.get_all_logs()
    return APIResponse(
        success=True,
        message="Logs retrieved successfully",
        data=[log.dict() for log in logs],
    )
