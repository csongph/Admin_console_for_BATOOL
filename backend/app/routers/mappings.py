from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schemas import APIResponse
from app.core.security import get_current_user
from app.db.database import get_db
from app.db.models import MappingRule

router = APIRouter(tags=["Mappings"])


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
        raise HTTPException(
            status_code=409,
            detail=f"Mapping '{body.raw_type}' from '{body.src_db}' → '{body.dest_db}' already exists",
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
        raise HTTPException(status_code=409, detail="Updated values conflict with an existing mapping rule")

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
    return APIResponse(success=True, message="Mapping rule deleted", data=data)