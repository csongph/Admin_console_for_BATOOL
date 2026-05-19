from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://database_for_ba_tool_user:n3K888YOjUCDP2ItZw30TuXi7MGBn9hY@dpg-d83ambfaqgkc73fa38ig-a.singapore-postgres.render.com/database_for_ba_tool"
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

    class Config:
        env_file = ".env"


settings = Settings()