from datetime import datetime, timezone
from sqlalchemy import Integer, String, Boolean, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


def _now():
    return datetime.now(timezone.utc)


class MappingRule(Base):
    __tablename__ = "mapping_rules"

    id:           Mapped[int]  = mapped_column(Integer, primary_key=True, autoincrement=True)
    src_db:       Mapped[str]  = mapped_column(String(64), nullable=False)
    raw_type:     Mapped[str]  = mapped_column(String(128), nullable=False)
    source_type:  Mapped[str]  = mapped_column(String(128), default="")
    logical_type: Mapped[str]  = mapped_column(String(128), default="")
    master_type:  Mapped[str]  = mapped_column(String(128), default="")
    dest_db:      Mapped[str]  = mapped_column(String(64), nullable=False)
    final_type:   Mapped[str]  = mapped_column(String(128), default="")
    confidence:   Mapped[int]  = mapped_column(Integer, default=100)
    status:       Mapped[str]  = mapped_column(String(32), default="draft")
    updated:      Mapped[str]  = mapped_column(String(16), default=lambda: datetime.utcnow().strftime("%Y-%m-%d"))

    def to_dict(self) -> dict:
        return {
            "id":           self.id,
            "src_db":       self.src_db,
            "raw_type":     self.raw_type,
            "source_type":  self.source_type,
            "logical_type": self.logical_type,
            "master_type":  self.master_type,
            "dest_db":      self.dest_db,
            "final_type":   self.final_type,
            "confidence":   self.confidence,
            "status":       self.status,
            "updated":      self.updated,
        }


class DatabaseRecord(Base):
    __tablename__ = "database_records"

    id:      Mapped[int]  = mapped_column(Integer, primary_key=True, autoincrement=True)
    key:     Mapped[str]  = mapped_column(String(64), unique=True, nullable=False)
    name:    Mapped[str]  = mapped_column(String(128), nullable=False)
    version: Mapped[str]  = mapped_column(String(32), default="")
    status:  Mapped[str]  = mapped_column(String(32), default="active")
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)

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


class SessionRecord(Base):
    __tablename__ = "session_records"

    id:          Mapped[str]  = mapped_column(String(64), primary_key=True)
    user:        Mapped[str]  = mapped_column(String(128), nullable=False)
    role:        Mapped[str]  = mapped_column(String(32), default="user")
    db:          Mapped[str]  = mapped_column(String(64), nullable=False)
    tables:      Mapped[int]  = mapped_column(Integer, default=0)
    ttl_minutes: Mapped[int]  = mapped_column(Integer, default=60)
    created:     Mapped[str]  = mapped_column(String(32), default=lambda: datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"))

    def to_dict(self) -> dict:
        from datetime import datetime
        created_dt = datetime.strptime(self.created, "%Y-%m-%d %H:%M:%S")
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