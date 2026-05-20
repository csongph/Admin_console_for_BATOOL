from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Integer, String, Boolean, DateTime, UniqueConstraint, Index, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


def _now_str() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


def _today_str() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ─────────────────────────────────────────────────────────────────────────────
class MappingRule(Base):
    __tablename__ = "mapping_rules"
    __table_args__ = (
        # ป้องกัน duplicate: src_db + raw_type + dest_db ต้อง unique
        UniqueConstraint("src_db", "raw_type", "dest_db", name="uq_mapping_rule"),
        Index("ix_mapping_src_db",   "src_db"),
        Index("ix_mapping_dest_db",  "dest_db"),
        Index("ix_mapping_status",   "status"),
    )

    id:            Mapped[int]           = mapped_column(Integer, primary_key=True, autoincrement=True)
    src_db:        Mapped[str]           = mapped_column(String(64),  nullable=False)
    raw_type:      Mapped[str]           = mapped_column(String(128), nullable=False)
    source_type:   Mapped[str]           = mapped_column(String(128), default="")
    logical_type:  Mapped[str]           = mapped_column(String(128), default="")
    master_type:   Mapped[str]           = mapped_column(String(128), default="")
    dest_db:       Mapped[str]           = mapped_column(String(64),  nullable=False)
    final_type:    Mapped[str]           = mapped_column(String(128), default="")
    confidence:    Mapped[int]           = mapped_column(Integer,     default=100)
    status:        Mapped[str]           = mapped_column(String(32),  default="draft")
    updated:       Mapped[str]           = mapped_column(String(16),  default=_today_str)
    # ── Sync / audit fields (migration 001) ──────────────────────────────────
    error_message: Mapped[Optional[str]] = mapped_column(String(256), nullable=True, default=None)
    synced_at:     Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True, default=None)
    retry_count:   Mapped[int]           = mapped_column(Integer, default=0)

    def to_dict(self) -> dict:
        return {
            "id":            self.id,
            "src_db":        self.src_db,
            "raw_type":      self.raw_type,
            "source_type":   self.source_type,
            "logical_type":  self.logical_type,
            "master_type":   self.master_type,
            "dest_db":       self.dest_db,
            "final_type":    self.final_type,
            "confidence":    self.confidence,
            "status":        self.status,
            "updated":       self.updated,
            "error_message": self.error_message,
            "synced_at":     self.synced_at.isoformat() if self.synced_at else None,
            "retry_count":   self.retry_count,
        }


# ─────────────────────────────────────────────────────────────────────────────
class DatabaseRecord(Base):
    __tablename__ = "database_records"
    __table_args__ = (
        Index("ix_db_record_key", "key"),
    )

    id:      Mapped[int]  = mapped_column(Integer, primary_key=True, autoincrement=True)
    key:     Mapped[str]  = mapped_column(String(64),  unique=True, nullable=False)
    name:    Mapped[str]  = mapped_column(String(128), nullable=False)
    version: Mapped[str]  = mapped_column(String(32),  default="")
    status:  Mapped[str]  = mapped_column(String(32),  default="active")
    enabled: Mapped[bool] = mapped_column(Boolean,     default=True)

    def to_dict(self, rules: int = 0, sessions: int = 0) -> dict:
        return {
            "id":       self.id,
            "key":      self.key,
            "name":     self.name,
            "version":  self.version,
            "status":   self.status,
            "enabled":  self.enabled,
            "rules":    rules,
            "sessions": sessions,
        }


# ─────────────────────────────────────────────────────────────────────────────
class DatatypeStandard(Base):
    """Lookup table สำหรับ standard type ที่ใช้ใน master_type dropdown"""
    __tablename__ = "datatype_standard"

    id:            Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    standard_type: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    description:   Mapped[str] = mapped_column(String(256), default="")

    def to_dict(self) -> dict:
        return {
            "id":            self.id,
            "standard_type": self.standard_type,
            "description":   self.description,
        }


# ─────────────────────────────────────────────────────────────────────────────
class SessionRecord(Base):
    __tablename__ = "session_records"
    __table_args__ = (
        Index("ix_session_db",     "db"),
        Index("ix_session_status", "status_cache"),
    )

    id:           Mapped[str] = mapped_column(String(64),  primary_key=True)
    user:         Mapped[str] = mapped_column(String(128), nullable=False)
    role:         Mapped[str] = mapped_column(String(32),  default="user")
    db:           Mapped[str] = mapped_column(String(64),  nullable=False)
    tables:       Mapped[int] = mapped_column(Integer,     default=0)
    ttl_minutes:  Mapped[int] = mapped_column(Integer,     default=60)
    created:      Mapped[str] = mapped_column(String(32),  default=_now_str)
    status_cache: Mapped[str] = mapped_column(String(16),  default="active")

    def to_dict(self) -> dict:
        try:
            created_dt = datetime.strptime(self.created, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            created_dt = datetime.utcnow()
        elapsed = (datetime.utcnow() - created_dt).total_seconds() / 60
        ttl = max(0, int(self.ttl_minutes - elapsed))
        status = "expired" if ttl <= 0 else "warning" if ttl < 10 else "active"
        return {
            "id":      self.id,
            "user":    self.user,
            "role":    self.role,
            "db":      self.db,
            "tables":  self.tables,
            "created": self.created,
            "ttl":     ttl,
            "status":  status,
        }


# ─────────────────────────────────────────────────────────────────────────────
class SystemSetting(Base):
    """Key-value store สำหรับ system state ที่ต้องอยู่รอดหลัง server restart"""
    __tablename__ = "system_settings"

    key:   Mapped[str] = mapped_column(String(64),  primary_key=True)
    value: Mapped[str] = mapped_column(String(256), nullable=False, default="")