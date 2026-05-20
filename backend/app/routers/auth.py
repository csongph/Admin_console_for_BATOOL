from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel

from app.schemas.schemas import LoginRequest, APIResponse
from app.services import auth_service
from app.core.security import get_current_user

router = APIRouter(tags=["Auth"])


class RefreshRequest(BaseModel):
    access_token: str


@router.post("/login", response_model=APIResponse)
async def login(request: LoginRequest):
    if not auth_service.authenticate_user(request.username, request.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    token_data = auth_service.generate_token(request.username)
    return APIResponse(success=True, message="Login successful", data=token_data)


@router.post("/refresh", response_model=APIResponse)
async def refresh_token(current_user: dict = Depends(get_current_user)):
    """ออก token ใหม่โดยใช้ token เดิมที่ยังไม่หมดอายุ"""
    token_data = auth_service.generate_token(current_user["username"])
    return APIResponse(success=True, message="Token refreshed", data=token_data)


@router.get("/me", response_model=APIResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    return APIResponse(success=True, message="OK", data=current_user)