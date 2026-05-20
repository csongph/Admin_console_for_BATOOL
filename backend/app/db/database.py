from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text
from typing import AsyncGenerator

from app.core.config import settings

# อ่าน URL จาก settings เท่านั้น — ห้าม hardcode ใน code
_url = settings.DATABASE_URL
if _url.startswith("postgresql://"):
    _url = _url.replace("postgresql://", "postgresql+asyncpg://", 1)
elif _url.startswith("postgres://"):
    # Render บางครั้งให้ URL แบบ postgres:// มา
    _url = _url.replace("postgres://", "postgresql+asyncpg://", 1)

engine = create_async_engine(
    _url,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
    echo=False,
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """สร้าง table ทั้งหมดถ้ายังไม่มี"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.execute(text(
            "ALTER TABLE session_records "
            "ADD COLUMN IF NOT EXISTS status_cache VARCHAR(16) DEFAULT 'active'"
        ))
