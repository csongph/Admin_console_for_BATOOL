from datetime import timedelta
from app.core.config import settings
from app.core.security import create_access_token, verify_password, get_password_hash

# ── ใช้ bcrypt hash จริง — ห้าม hardcode plain text ──────────────────────────
# สร้าง hash ใหม่ได้ด้วย: python -c "from app.core.security import get_password_hash; print(get_password_hash('YOUR_PASSWORD'))"
_HASHED_USERS: dict[str, str] = {
    "admin": get_password_hash("admin123"),  # เปลี่ยน password ก่อน production
}


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