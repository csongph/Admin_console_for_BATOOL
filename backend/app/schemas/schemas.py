from pydantic import BaseModel
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


# ─── System schemas ───────────────────────────────────────────────────────────

class SystemStatus(BaseModel):
    status: str  # "running" | "stopped"
