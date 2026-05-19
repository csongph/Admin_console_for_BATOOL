from fastapi import APIRouter, HTTPException, status

from app.schemas.schemas import LoginRequest, APIResponse
from app.services import auth_service

router = APIRouter(tags=["Auth"])


@router.post("/login", response_model=APIResponse)
async def login(request: LoginRequest):
    if not auth_service.authenticate_user(request.username, request.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )

    token_data = auth_service.generate_token(request.username)
    return APIResponse(
        success=True,
        message="Login successful",
        data=token_data,
    )
