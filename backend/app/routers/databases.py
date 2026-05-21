"""
routers/databases.py
────────────────────
แก้ไขจาก version เดิม — เพิ่ม:
  1. sanitize + validate key (lowercase, strip spaces, regex)
  2. duplicate check แบบ case-insensitive
  3. structured error response  (error code + message)
  4. lookup endpoint สำหรับ dropdown /api/database-records/enabled
  5. logging
  6. backward compatible — ทุก route เดิมยังทำงานได้ปกติ
"""
import re
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, field_validator
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import DatabaseRecord, MappingRule, SessionRecord

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Databases"])

# ── Key sanitize helper ───────────────────────────────────────────────────────
_KEY_PATTERN = re.compile(r"^[a-z0-9_]+$")


def sanitize_key(raw: str) -> str:
    """
    MSSQL PROD  -> mssqlprod
    My DB_01    -> mydb_01
    """
    return re.sub(r"\s+", "", raw.strip().lower())


def validate_key(key: str) -> str:
    """Raise ValueError ถ้า key ไม่ผ่าน — ใช้ใน Pydantic validator"""
    sanitized = sanitize_key(key)
    if not sanitized:
        raise ValueError("Key must not be empty")
    if not _KEY_PATTERN.match(sanitized):
        raise ValueError(
            "Key must contain only lowercase letters (a-z), digits (0-9), "
            "and underscores (_)"
        )
    return sanitized


# ─── Schemas ──────────────────────────────────────────────────────────────────

class DatabaseCreate(BaseModel):
    key:     str
    name:    str
    version: str  = ""
    status:  str  = "active"
    enabled: bool = True

    @field_validator("key")
    @classmethod
    def clean_key(cls, v: str) -> str:
        return validate_key(v)

    @field_validator("name")
    @classmethod
    def clean_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Name must not be empty")
        return v


class DatabaseUpdate(BaseModel):
    key:     Optional[str]  = None
    name:    Optional[str]  = None
    version: Optional[str]  = None
    status:  Optional[str]  = None
    enabled: Optional[bool] = None

    @field_validator("key")
    @classmethod
    def clean_key(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return validate_key(v)

    @field_validator("name")
    @classmethod
    def clean_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        v = v.strip()
        if not v:
            raise ValueError("Name must not be empty")
        return v


# ─── Default databases to seed on first run ───────────────────────────────────

_DEFAULTS = [
    {"key": "sqlserver",  "name": "SQL Server", "version": "2019", "status": "active", "enabled": True},
    {"key": "postgresql", "name": "PostgreSQL",  "version": "15.x", "status": "active", "enabled": True},
    {"key": "mysql",      "name": "MySQL",        "version": "8.x",  "status": "active", "enabled": True},
    {"key": "oracle",     "name": "Oracle",       "version": "19c",  "status": "beta",   "enabled": True},
    {"key": "confluent",  "name": "Confluent",    "version": "7.x",  "status": "active", "enabled": True},
]


async def _seed_defaults(db: AsyncSession):
    result = await db.execute(select(DatabaseRecord))
    if result.scalars().first() is not None:
        return
    for d in _DEFAULTS:
        db.add(DatabaseRecord(**d))
    await db.commit()


async def _count_rules(db: AsyncSession, key: str) -> int:
    result = await db.execute(
        select(func.count()).select_from(MappingRule).where(
            (MappingRule.src_db == key) | (MappingRule.dest_db == key)
        )
    )
    return result.scalar_one()


async def _count_sessions(db: AsyncSession, key: str) -> int:
    result = await db.execute(
        select(func.count()).select_from(SessionRecord).where(SessionRecord.db == key)
    )
    return result.scalar_one()


async def _key_exists(db: AsyncSession, key: str, exclude_id: Optional[int] = None) -> bool:
    """Case-insensitive duplicate check"""
    from sqlalchemy import func as sqlfunc
    q = select(DatabaseRecord).where(
        sqlfunc.lower(DatabaseRecord.key) == key.lower()
    )
    if exclude_id is not None:
        q = q.where(DatabaseRecord.id != exclude_id)
    result = await db.execute(q)
    return result.scalar_one_or_none() is not None


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/databases", response_model=APIResponse)
async def get_databases(
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    await _seed_defaults(db)
    result = await db.execute(select(DatabaseRecord))
    rows = result.scalars().all()
    data = []
    for r in rows:
        rules    = await _count_rules(db, r.key)
        sessions = await _count_sessions(db, r.key)
        data.append(r.to_dict(rules=rules, sessions=sessions))
    return APIResponse(success=True, message=f"{len(data)} database(s) retrieved", data=data)


@router.post("/databases", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
async def create_database(
    body:         DatabaseCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    # key ผ่าน Pydantic validator แล้ว (sanitize + regex)
    if await _key_exists(db, body.key):
        logger.warning("Duplicate DB key attempt: %s", body.key)
        raise HTTPException(
            status_code=409,
            detail={
                "success":  False,
                "error":    "DATABASE_KEY_ALREADY_EXISTS",
                "message":  f"Database key '{body.key}' already exists",
            },
        )
    record = DatabaseRecord(**body.dict())
    db.add(record)
    await db.commit()
    await db.refresh(record)
    logger.info("Database created: key=%s by user=%s", body.key, current_user.get("username"))
    return APIResponse(success=True, message="Database added", data=record.to_dict())


@router.put("/databases/{db_id}", response_model=APIResponse)
async def update_database(
    db_id:        int,
    body:         DatabaseUpdate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(DatabaseRecord).where(DatabaseRecord.id == db_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Database not found")

    updates = body.dict(exclude_none=True)

    # ถ้า key เปลี่ยน ต้อง check duplicate ด้วย
    if "key" in updates and await _key_exists(db, updates["key"], exclude_id=db_id):
        raise HTTPException(
            status_code=409,
            detail={
                "success": False,
                "error":   "DATABASE_KEY_ALREADY_EXISTS",
                "message": f"Database key '{updates['key']}' already exists",
            },
        )

    for field, value in updates.items():
        setattr(record, field, value)
    await db.commit()
    await db.refresh(record)
    logger.info("Database updated: id=%s by user=%s", db_id, current_user.get("username"))
    return APIResponse(success=True, message="Database updated", data=record.to_dict())


@router.delete("/databases/{db_id}", response_model=APIResponse)
async def delete_database(
    db_id:        int,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(DatabaseRecord).where(DatabaseRecord.id == db_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Database not found")
    data = record.to_dict()
    await db.delete(record)
    await db.commit()
    logger.info("Database deleted: key=%s by user=%s", data["key"], current_user.get("username"))
    return APIResponse(success=True, message="Database removed", data=data)


# ── NEW: Lookup endpoint for dropdown — GET /api/database-records/enabled ─────

@router.get("/database-records/enabled", response_model=APIResponse)
async def get_enabled_databases(
    search: Optional[str] = Query(None, description="Filter by key prefix"),
    limit:  int           = Query(100,  ge=1, le=500),
    db:     AsyncSession  = Depends(get_db),
    current_user: dict    = Depends(get_current_user),
):
    """
    Lightweight endpoint สำหรับ dropdown ใน Mapping Form
    Returns: [{id, key}] เฉพาะ enabled=true
    """
    q = select(DatabaseRecord.id, DatabaseRecord.key).where(
        DatabaseRecord.enabled == True  # noqa: E712
    )
    if search:
        q = q.where(DatabaseRecord.key.ilike(f"%{search}%"))
    q = q.order_by(DatabaseRecord.key).limit(limit)
    result = await db.execute(q)
    rows = result.all()
    data = [{"id": r.id, "key": r.key} for r in rows]
    return APIResponse(success=True, message=f"{len(data)} database(s)", data=data)