from datetime import timedelta
from app.core.config import settings
from app.core.security import create_access_token, verify_password, get_password_hash


def _build_user_db() -> dict[str, str]:
    """
    สร้าง user map จาก settings — hash password ตอน startup ครั้งเดียว
    เพิ่ม user ได้โดยเพิ่ม ADMIN_USERNAME/ADMIN_PASSWORD ใน .env
    """
    return {
        settings.ADMIN_USERNAME: get_password_hash(settings.ADMIN_PASSWORD),
    }


# hash ครั้งเดียวตอน import — ไม่ hardcode plain text ในโค้ด
_HASHED_USERS: dict[str, str] = _build_user_db()


def authenticate_user(username: str, password: str) -> bool:
    hashed = _HASHED_USERS.get(username)
    if not hashed:
        return False
    return verify_password(password, hashed)


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
