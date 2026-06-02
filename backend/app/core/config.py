from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List, Optional


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    PORT: int = 8000

    ADMIN_USERNAME: str = "admin"
    ADMIN_PASSWORD: str

    ANTHROPIC_API_KEY: Optional[str] = None

    ALLOWED_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:5500",
        "http://localhost:5501",
        "http://127.0.0.1",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:5501",
        "null",
        "https://ba-tool-for-multiple-db.vercel.app",
        "https://admin-console-for-batool-91pz.vercel.app",
    ]
    ALLOWED_ORIGIN_REGEX: Optional[str] = (
        r"https://admin-console-for-batool(-[a-z0-9]+)?\.vercel\.app"
    )

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, value):
        if isinstance(value, str):
            value = value.strip()
            if not value:
                return []
            if value.startswith("["):
                return value
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    class Config:
        env_file = ".env"


settings = Settings()
