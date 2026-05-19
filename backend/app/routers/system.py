from fastapi import APIRouter, Depends

from app.schemas.schemas import APIResponse
from app.services import system_service
from app.core.security import get_current_user

router = APIRouter(tags=["System"])


@router.get("/status", response_model=APIResponse)
async def get_status(current_user: dict = Depends(get_current_user)):
    data = system_service.get_status()
    return APIResponse(success=True, message="Status retrieved", data=data)


@router.post("/start", response_model=APIResponse)
async def start_system(current_user: dict = Depends(get_current_user)):
    data = system_service.start_system()
    return APIResponse(success=True, message="System started", data=data)


@router.post("/stop", response_model=APIResponse)
async def stop_system(current_user: dict = Depends(get_current_user)):
    data = system_service.stop_system()
    return APIResponse(success=True, message="System stopped", data=data)
