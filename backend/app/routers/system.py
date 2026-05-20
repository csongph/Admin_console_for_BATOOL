from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.services import system_service
from app.core.security import get_current_user
from app.db.database import get_db

router = APIRouter(tags=["System"])


@router.get("/status", response_model=APIResponse)
async def get_status(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = await system_service.get_status(db)
    return APIResponse(success=True, message="Status retrieved", data=data)


@router.post("/start", response_model=APIResponse)
async def start_system(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = await system_service.start_system(db)
    return APIResponse(success=True, message="System started", data=data)


@router.post("/stop", response_model=APIResponse)
async def stop_system(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = await system_service.stop_system(db)
    return APIResponse(success=True, message="System stopped", data=data)
