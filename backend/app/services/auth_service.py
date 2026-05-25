"""
auth_service.py
───────────────
ตรวจสอบ credential จาก 2 แหล่ง (priority order):
  1. AdminUser table ใน DB  — ผู้ใช้ที่ Admin สร้างเพิ่ม
  2. .env ADMIN_USERNAME / ADMIN_PASSWORD  — superadmin fallback

เพิ่ม update_last_login() เพื่อบันทึกเวลา login ล่าสุด
"""
from datetime import timedelta, datetime, timezone
from typing import Optional

from app.core.config import settings
from app.core.security import create_access_token, verify_password, get_password_hash


# ── Superadmin จาก .env (fallback — ใช้ตอนที่ DB ยังไม่มี user) ──────────────
def _env_admin_hash() -> str:
    return get_password_hash(settings.ADMIN_PASSWORD)


# hash ครั้งเดียวตอน import
_ENV_ADMIN_HASH: str = _env_admin_hash()


def authenticate_user_env(username: str, password: str) -> bool:
    """ตรวจ credential จาก .env เท่านั้น (ไม่ต้องใช้ DB)"""
    if username != settings.ADMIN_USERNAME:
        return False
    return verify_password(password, _ENV_ADMIN_HASH)


async def authenticate_user_db(username: str, password: str, db) -> Optional[object]:
    """
    ตรวจ credential จาก AdminUser table
    คืน AdminUser object ถ้าสำเร็จ, None ถ้าไม่ผ่าน
    """
    from sqlalchemy import select
    from app.db.models import AdminUser
    result = await db.execute(select(AdminUser).where(AdminUser.username == username))
    user   = result.scalar_one_or_none()
    if not user or not user.is_active:
        return None
    if not verify_password(password, user.hashed_pw):
        return None
    return user


async def authenticate_user(username: str, password: str, db=None) -> bool:
    """
    ตรวจ credential — ลอง DB ก่อน, ถ้าไม่มีให้ fallback .env
    """
    if db is not None:
        user = await authenticate_user_db(username, password, db)
        if user is not None:
            return True
    # fallback superadmin
    return authenticate_user_env(username, password)


async def update_last_login(username: str, db) -> None:
    """อัปเดต last_login ใน AdminUser (ถ้ามี record)"""
    try:
        from sqlalchemy import select
        from app.db.models import AdminUser
        result = await db.execute(select(AdminUser).where(AdminUser.username == username))
        user   = result.scalar_one_or_none()
        if user:
            user.last_login = datetime.now(timezone.utc)
            await db.commit()
    except Exception:
        pass


def generate_token(username: str) -> dict:
    expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
    token = create_access_token(
        data={"sub": username},
        expires_delta=timedelta(minutes=expire_minutes),
    )
    return {
        "access_token": token,
        "token_type":   "bearer",
        "expires_in":   expire_minutes * 60,
    }
