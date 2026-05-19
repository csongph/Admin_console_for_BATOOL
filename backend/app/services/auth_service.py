import bcrypt
from datetime import timedelta
from app.core.config import settings
from app.core.security import create_access_token

_RAW_USERS = {"admin": "admin123"}


def authenticate_user(username: str, password: str) -> bool:
    raw = _RAW_USERS.get(username)
    if not raw:
        return False
    return password == raw  # dev mode: plain compare


def generate_token(username: str) -> dict:
    expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
    token = create_access_token(
        data={"sub": username},
        expires_delta=timedelta(minutes=expire_minutes),
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": expire_minutes * 60,
    }