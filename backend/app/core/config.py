from pydantic_settings import BaseSettings
from typing import List, Optional


class Settings(BaseSettings):
    # ต้องตั้งค่าใน .env หรือ environment variable เสมอ — ไม่มี default ที่มี credentials
    DATABASE_URL: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    PORT: int = 8000

    # Admin credentials — อ่านจาก .env เท่านั้น ห้าม hardcode ในโค้ด
    ADMIN_USERNAME: str = "admin"
    ADMIN_PASSWORD: str  # บังคับต้องตั้งใน .env

    # Anthropic — ใส่ใน .env เท่านั้น ห้าม hardcode
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
    ]
    # จำกัดเฉพาะ vercel subdomain — ไม่เปิด http://* ทั้งหมด
    ALLOWED_ORIGIN_REGEX: Optional[str] = r"https://[a-zA-Z0-9-]+\.vercel\.app"

    class Config:
        env_file = ".env"


settings = Settings()
    