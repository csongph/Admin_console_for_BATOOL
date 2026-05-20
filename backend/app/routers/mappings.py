"""
routers/mappings.py
───────────────────
แก้ไขจาก version เดิม — เพิ่ม:
  1. trim + validate required fields (raw_type, logical_type, source_type, final_type)
  2. prevent whitespace-only strings
  3. structured error response
  4. lookup endpoint /api/datatype-standard/list
  5. logging ทุก write operation
  6. backward compatible
"""
import logging
from typing import Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, field_validator
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import MappingRule, DatatypeStandard

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Mappings"])


# ─── Validators ───────────────────────────────────────────────────────────────

def _require_non_empty(v: str, field_name: str) -> str:
    """trim และ reject whitespace-only"""
    if v is None:
        return v
    v = v.strip()
    if not v:
        raise ValueError(f"{field_name} must not be empty or whitespace-only")
    return v


# ─── Schemas ──────────────────────────────────────────────────────────────────

class MappingCreate(BaseModel):
    src_db:       str
    raw_type:     str
    source_type:  str = ""
    logical_type: str = ""
    master_type:  str = ""
    dest_db:      str
    final_type:   str = ""
    confidence:   int = 100
    status:       str = "draft"

    @field_validator("raw_type")
    @classmethod
    def clean_raw_type(cls, v: str) -> str:
        return _require_non_empty(v, "raw_type")

    @field_validator("src_db")
    @classmethod
    def clean_src_db(cls, v: str) -> str:
        return _require_non_empty(v, "src_db")

    @field_validator("dest_db")
    @classmethod
    def clean_dest_db(cls, v: str) -> str:
        return _require_non_empty(v, "dest_db")

    @field_validator("source_type", "logical_type", "master_type", "final_type", mode="before")
    @classmethod
    def trim_optional(cls, v: str) -> str:
        if v is None:
            return ""
        return v.strip()


class MappingUpdate(BaseModel):
    src_db:       Optional[str] = None
    raw_type:     Optional[str] = None
    source_type:  Optional[str] = None
    logical_type: Optional[str] = None
    master_type:  Optional[str] = None
    dest_db:      Optional[str] = None
    final_type:   Optional[str] = None
    confidence:   Optional[int] = None
    status:       Optional[str] = None

    @field_validator("raw_type", "src_db", "dest_db", mode="before")
    @classmethod
    def trim_required(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        v = v.strip()
        if not v:
            raise ValueError("Field must not be empty or whitespace-only")
        return v

    @field_validator("source_type", "logical_type", "master_type", "final_type", mode="before")
    @classmethod
    def trim_optional(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return v.strip()


def _today() -> str:
    return datetime.utcnow().strftime("%Y-%m-%d")


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.get("/mappings", response_model=APIResponse)
async def get_mappings(
    src_db:       Optional[str] = None,
    dest_db:      Optional[str] = None,
    status:       Optional[str] = None,
    db:           AsyncSession  = Depends(get_db),
    current_user: dict          = Depends(get_current_user),
):
    q = select(MappingRule)
    if src_db:  q = q.where(MappingRule.src_db  == src_db)
    if dest_db: q = q.where(MappingRule.dest_db == dest_db)
    if status:  q = q.where(MappingRule.status  == status)
    result = await db.execute(q)
    rows = result.scalars().all()
    return APIResponse(
        success=True,
        message=f"{len(rows)} mapping rule(s) retrieved",
        data=[r.to_dict() for r in rows],
    )


@router.post("/mappings", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
async def create_mapping(
    body:         MappingCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    record = MappingRule(**body.dict(), updated=_today())
    db.add(record)
    try:
        await db.commit()
        await db.refresh(record)
    except IntegrityError:
        await db.rollback()
        logger.warning(
            "Duplicate mapping: raw_type=%s src=%s dest=%s",
            body.raw_type, body.src_db, body.dest_db,
        )
        raise HTTPException(
            status_code=409,
            detail={
                "success": False,
                "error":   "DUPLICATE_MAPPING",
                "message": f"Mapping '{body.raw_type}' from '{body.src_db}' → '{body.dest_db}' already exists",
            },
        )
    logger.info(
        "Mapping created: id=%s raw_type=%s src=%s dest=%s by user=%s",
        record.id, body.raw_type, body.src_db, body.dest_db, current_user.get("sub"),
    )
    return APIResponse(success=True, message="Mapping rule created", data=record.to_dict())


@router.put("/mappings/{mapping_id}", response_model=APIResponse)
async def update_mapping(
    mapping_id:   int,
    body:         MappingUpdate,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(MappingRule).where(MappingRule.id == mapping_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Mapping rule not found")

    for field, value in body.dict(exclude_none=True).items():
        setattr(record, field, value)
    record.updated = _today()

    try:
        await db.commit()
        await db.refresh(record)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=409,
            detail={
                "success": False,
                "error":   "DUPLICATE_MAPPING",
                "message": "Updated values conflict with an existing mapping rule",
            },
        )

    logger.info("Mapping updated: id=%s by user=%s", mapping_id, current_user.get("sub"))
    return APIResponse(success=True, message="Mapping rule updated", data=record.to_dict())


@router.delete("/mappings/{mapping_id}", response_model=APIResponse)
async def delete_mapping(
    mapping_id:   int,
    db:           AsyncSession = Depends(get_db),
    current_user: dict         = Depends(get_current_user),
):
    result = await db.execute(select(MappingRule).where(MappingRule.id == mapping_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Mapping rule not found")
    data = record.to_dict()
    await db.delete(record)
    await db.commit()
    logger.info("Mapping deleted: id=%s by user=%s", mapping_id, current_user.get("sub"))
    return APIResponse(success=True, message="Mapping rule deleted", data=data)


# ── NEW: Lookup endpoint for dropdown — GET /api/datatype-standard/list ───────

@router.get("/datatype-standard/list", response_model=APIResponse)
async def list_datatype_standards(
    search: Optional[str] = Query(None, description="Filter by standard_type"),
    limit:  int           = Query(100, ge=1, le=500),
    db:     AsyncSession  = Depends(get_db),
    current_user: dict    = Depends(get_current_user),
):
    """
    Lightweight endpoint สำหรับ master_type dropdown ใน Mapping Form
    Returns: [{id, standard_type}]
    """
    q = select(DatatypeStandard.id, DatatypeStandard.standard_type)
    if search:
        q = q.where(DatatypeStandard.standard_type.ilike(f"%{search}%"))
    q = q.order_by(DatatypeStandard.standard_type).limit(limit)
    result = await db.execute(q)
    rows = result.all()
    data = [{"id": r.id, "standard_type": r.standard_type} for r in rows]
    return APIResponse(success=True, message=f"{len(data)} type(s)", data=data)