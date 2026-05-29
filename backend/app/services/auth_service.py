"""
auth_service.py
───────────────
ตรวจสอบ credential จาก 2 แหล่ง (priority order):
  1. AdminUser table ใน DB  — ผู้ใช้ที่ Admin สร้างเพิ่ม
  2. .env ADMIN_USERNAME / ADMIN_PASSWORD  — superadmin fallback

อ่าน sec_session_timeout / sec_max_attempts จาก system settings
"""
import time
from datetime import timedelta, datetime, timezone
from typing import Optional

from app.core.config import settings
from app.core.security import create_access_token, verify_password, get_password_hash
from app.services import system_service


# ── Superadmin จาก .env (fallback — ใช้ตอนที่ DB ยังไม่มี user) ──────────────
def _env_admin_hash() -> str:
    return get_password_hash(settings.ADMIN_PASSWORD)


_ENV_ADMIN_HASH: str = _env_admin_hash()

# username -> (failed_count, locked_until_unix)
_login_lockouts: dict[str, tuple[int, float]] = {}
LOCKOUT_SECONDS = 15 * 60


async def _session_timeout_minutes(db) -> int:
    try:
        vals = await system_service.get_settings(db)
        return max(5, min(int(vals.get("sec_session_timeout", "60")), 1440))
    except Exception:
        return settings.ACCESS_TOKEN_EXPIRE_MINUTES


async def _max_login_attempts(db) -> int:
    try:
        vals = await system_service.get_settings(db)
        return max(1, min(int(vals.get("sec_max_attempts", "5")), 20))
    except Exception:
        return 5


async def min_password_length(db) -> int:
    try:
        vals = await system_service.get_settings(db)
        return max(4, min(int(vals.get("sec_min_pw_len", "6")), 32))
    except Exception:
        return 6


def is_login_locked(username: str) -> tuple[bool, int]:
    """คืน (locked, seconds_remaining)"""
    key = username.strip().lower()
    entry = _login_lockouts.get(key)
    if not entry:
        return False, 0
    _, locked_until = entry
    now = time.time()
    if now >= locked_until:
        _login_lockouts.pop(key, None)
        return False, 0
    return True, int(locked_until - now)


async def record_failed_login(username: str, db) -> tuple[int, bool]:
    """คืน (failed_count, now_locked)"""
    key = username.strip().lower()
    max_attempts = await _max_login_attempts(db)
    count, locked_until = _login_lockouts.get(key, (0, 0.0))
    if time.time() < locked_until:
        return count, True
    count += 1
    locked = count >= max_attempts
    if locked:
        _login_lockouts[key] = (count, time.time() + LOCKOUT_SECONDS)
    else:
        _login_lockouts[key] = (count, 0.0)
    return count, locked


def clear_login_lockout(username: str) -> None:
    _login_lockouts.pop(username.strip().lower(), None)


def authenticate_user_env(username: str, password: str) -> bool:
    if username != settings.ADMIN_USERNAME:
        return False
    return verify_password(password, _ENV_ADMIN_HASH)


async def authenticate_user_db(username: str, password: str, db) -> Optional[object]:
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
    if db is not None:
        user = await authenticate_user_db(username, password, db)
        if user is not None:
            return True
    return authenticate_user_env(username, password)


async def update_last_login(username: str, db) -> None:
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


async def generate_token(username: str, db=None) -> dict:
    expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
    if db is not None:
        expire_minutes = await _session_timeout_minutes(db)
    token = create_access_token(
        data={"sub": username},
        expires_delta=timedelta(minutes=expire_minutes),
    )
    return {
        "access_token": token,
        "token_type":   "bearer",
        "expires_in":   expire_minutes * 60,
    }


async def get_public_auth_settings(db) -> dict:
    return {
        "sec_max_attempts":    await _max_login_attempts(db),
        "sec_min_pw_len":      await min_password_length(db),
        "sec_session_timeout": await _session_timeout_minutes(db),
    }
