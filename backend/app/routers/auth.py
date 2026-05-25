from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import SessionRecord
from app.schemas.schemas import APIResponse, LoginRequest
from app.services import auth_service

router = APIRouter(tags=["Auth"])


class RefreshRequest(BaseModel):
    access_token: str


async def _upsert_auth_session(db: AsyncSession, username: str) -> None:
    session_id = f"auth-{username}"
    created = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    result = await db.execute(select(SessionRecord).where(SessionRecord.id == session_id))
    record = result.scalar_one_or_none()

    if record:
        record.created = created
        record.ttl_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        record.status_cache = "active"
    else:
        db.add(SessionRecord(
            id=session_id,
            user=username,
            role="admin" if username == settings.ADMIN_USERNAME else "user",
            db="admin-console",
            tables=0,
            ttl_minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
            created=created,
            status_cache="active",
        ))
    await db.commit()


@router.post("/login", response_model=APIResponse)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    ok = await auth_service.authenticate_user(request.username, request.password, db)
    if not ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    token_data = auth_service.generate_token(request.username)
    await _upsert_auth_session(db, request.username)
    await auth_service.update_last_login(request.username, db)
    return APIResponse(success=True, message="Login successful", data=token_data)


@router.post("/refresh", response_model=APIResponse)
async def refresh_token(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    token_data = auth_service.generate_token(current_user["username"])
    await _upsert_auth_session(db, current_user["username"])
    return APIResponse(success=True, message="Token refreshed", data=token_data)


@router.get("/me", response_model=APIResponse)
async def get_me(
    current_user: dict      = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
):
    from sqlalchemy import select
    from app.db.models import AdminUser
    username = current_user["username"]
    result   = await db.execute(select(AdminUser).where(AdminUser.username == username))
    user_rec = result.scalar_one_or_none()
    role = user_rec.role if user_rec else ("admin" if username == settings.ADMIN_USERNAME else "viewer")
    return APIResponse(success=True, message="OK", data={**current_user, "role": role})


@router.post("/logout", response_model=APIResponse)
async def logout(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        delete(SessionRecord).where(SessionRecord.id == f"auth-{current_user['username']}")
    )
    await db.commit()
    return APIResponse(success=True, message="Logged out", data=None)