from datetime import timedelta

from app.core.security import verify_password, get_password_hash, create_access_token
from app.core.config import settings

# Hardcoded credentials — replace with DB lookup when ready.
# Passwords are hashed on first use (lazy) to avoid startup cost.
_RAW_USERS = {"admin": "admin123"}
_HASHED_CACHE: dict = {}


def _get_hashed(username: str) -> str | None:
    raw = _RAW_USERS.get(username)
    if raw is None:
        return None
    if username not in _HASHED_CACHE:
        _HASHED_CACHE[username] = get_password_hash(raw)
    return _HASHED_CACHE[username]


def authenticate_user(username: str, password: str) -> bool:
    hashed = _get_hashed(username)
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
