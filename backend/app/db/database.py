from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text
from typing import AsyncGenerator

from app.core.config import settings

_url = settings.DATABASE_URL
if _url.startswith("postgresql://"):
    _url = _url.replace("postgresql://", "postgresql+asyncpg://", 1)
elif _url.startswith("postgres://"):
    _url = _url.replace("postgres://", "postgresql+asyncpg://", 1)

engine = create_async_engine(
    _url,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
    echo=False,
    connect_args={"prepared_statement_cache_size": 0},
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
    """สร้าง table ทั้งหมดถ้ายังไม่มี + safe migrations"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

        # ── Safe migrations (idempotent ALTER TABLE) ──────────────────────────

        # session_records.status_cache (เดิม)
        await conn.execute(text(
            "ALTER TABLE session_records "
            "ADD COLUMN IF NOT EXISTS status_cache VARCHAR(16) DEFAULT 'active'"
        ))

        # mapping_rules — sync/audit fields (migration 001)
        await conn.execute(text(
            "ALTER TABLE mapping_rules "
            "ADD COLUMN IF NOT EXISTS error_message VARCHAR(256) DEFAULT NULL"
        ))
        await conn.execute(text(
            "ALTER TABLE mapping_rules "
            "ADD COLUMN IF NOT EXISTS synced_at TIMESTAMP WITH TIME ZONE DEFAULT NULL"
        ))
        await conn.execute(text(
            "ALTER TABLE mapping_rules "
            "ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0"
        ))
        await conn.execute(text(
            "ALTER TABLE mapping_rules "
            "ADD COLUMN IF NOT EXISTS source_type VARCHAR(128) DEFAULT ''"
        ))

        # unique index บน database_records.key (case-insensitive)
        await conn.execute(text(
            "CREATE UNIQUE INDEX IF NOT EXISTS uq_db_record_key_lower "
            "ON database_records (LOWER(key))"
        ))