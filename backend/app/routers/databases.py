from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import DatabaseRecord, MappingRule, SessionRecord

router = APIRouter(tags=["Databases"])


# ─── Schemas ──────────────────────────────────────────────────────────────────

class DatabaseCreate(BaseModel):
    key:     str
    name:    str
    version: str  = ""
    status:  str  = "active"
    enabled: bool = True


class DatabaseUpdate(BaseModel):
    key:     Optional[str]  = None
    name:    Optional[str]  = None
    version: Optional[str]  = None
    status:  Optional[str]  = None
    enabled: Optional[bool] = None


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
        return  # already seeded
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
    return APIResponse(
        success=True,
        message=f"{len(data)} database(s) retrieved",
        data=data,
    )


@router.post("/databases", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
async def create_database(
    body:         DatabaseCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    existing = await db.execute(select(DatabaseRecord).where(DatabaseRecord.key == body.key))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail=f"Database key '{body.key}' already exists")
    record = DatabaseRecord(**body.dict())
    db.add(record)
    await db.commit()
    await db.refresh(record)
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
    for field, value in body.dict(exclude_none=True).items():
        setattr(record, field, value)
    await db.commit()
    await db.refresh(record)
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
    return APIResponse(success=True, message="Database removed", data=data)
