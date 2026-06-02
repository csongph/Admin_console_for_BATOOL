from pydantic import BaseModel, field_validator
from typing import Any, Optional


# ─── Standard API response wrapper ───────────────────────────────────────────

class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Any] = None


# ─── Auth schemas ─────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def normalize_username(cls, v: str) -> str:
        # ต้องตรงกับ UserCreate.clean_username — strip + lowercase
        return v.strip().lower()


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


# ─── Log schemas ──────────────────────────────────────────────────────────────

class LogEntry(BaseModel):
    id: int
    timestamp: str
    level: str
    message: str
    source_file: Optional[str] = None


# ─── System schemas ───────────────────────────────────────────────────────────

class SystemStatus(BaseModel):
    status: str  # "running" | "stopped"