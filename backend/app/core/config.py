from pydantic_settings import BaseSettings
from typing import List, Optional


class Settings(BaseSettings):
    # ต้องตั้งค่าใน .env หรือ environment variable เสมอ — ไม่มี default ที่มี credentials
    DATABASE_URL: str
    SECRET_KEY: str = "change-this-secret-key-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    PORT: int = 8000

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
    ]
    ALLOWED_ORIGIN_REGEX: Optional[str] = r"(https://.*\.vercel\.app|http://.*)"

    class Config:
        env_file = ".env"


settings = Settings()
