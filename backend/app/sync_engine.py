"""
sync_engine.py
──────────────
กระจายข้อมูลจาก mapping_rules → datatype_raw_mapping + datatype_mapping
ของ BATOOL แบบ production-ready:

  • Session แยกต่อ row — row-level isolation สมบูรณ์
  • Retry logic พร้อม exponential backoff
  • Auto-scheduler (background task) ทุก SYNC_INTERVAL_SECONDS
  • Manual trigger ผ่าน /api/sync/run
  • Status tracking ผ่าน /api/sync/status
  • Idempotent: ON CONFLICT DO UPDATE — รันซ้ำกี่ครั้งก็ได้
"""

import asyncio
import logging
import traceback
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select, func, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import AsyncSessionLocal
from app.db.models import MappingRule, DatabaseRecord, DatatypeStandard

logger = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────────────────────
BATCH_SIZE            = 100
MAX_RETRIES           = 3
SYNC_INTERVAL_SECONDS = 300        # auto-sync ทุก 5 นาที
RETRY_BACKOFF_SECONDS = [0, 5, 30] # delay ก่อน retry แต่ละครั้ง

# ── Runtime state ─────────────────────────────────────────────────────────────
_sync_running          = False
_last_run_at: Optional[datetime] = None
_last_metrics: dict   = {}
_scheduler_task: Optional[asyncio.Task] = None


# ─────────────────────────────────────────────────────────────────────────────
# Lookup helpers (ใช้ session ที่ส่งเข้ามา)
# ─────────────────────────────────────────────────────────────────────────────

async def _lookup_db(session: AsyncSession, key: str) -> Optional[DatabaseRecord]:
    result = await session.execute(
        select(DatabaseRecord).where(func.lower(DatabaseRecord.key) == key.strip().lower())
    )
    return result.scalar_one_or_none()


async def _lookup_master_type(session: AsyncSession, standard_type: str) -> Optional[DatatypeStandard]:
    result = await session.execute(
        select(DatatypeStandard).where(DatatypeStandard.standard_type == standard_type.strip())
    )
    return result.scalar_one_or_none()


# ─────────────────────────────────────────────────────────────────────────────
# Row processor — session แยกต่อ row เพื่อ isolation สมบูรณ์
# ─────────────────────────────────────────────────────────────────────────────

async def _process_row(rule_id: int, rule_data: dict) -> dict:
    """
    Process single row ด้วย session แยก
    ถ้า error ใน row นี้ไม่กระทบ row อื่น — transaction clean ทุกครั้ง
    """
    start = datetime.now(timezone.utc)

    async with AsyncSessionLocal() as session:
        try:
            # 1. validate src_db
            src_db_rec = await _lookup_db(session, rule_data["src_db"])
            if not src_db_rec:
                return {"status": "error", "error_message": "SOURCE_DB_NOT_FOUND", "synced_at": None}

            # 2. validate dest_db
            dest_db_rec = await _lookup_db(session, rule_data["dest_db"])
            if not dest_db_rec:
                return {"status": "error", "error_message": "DEST_DB_NOT_FOUND", "synced_at": None}

            # 3. validate master_type (optional)
            standard_id = None
            master_type = rule_data.get("master_type", "")
            if master_type and master_type.strip():
                master_rec = await _lookup_master_type(session, master_type)
                if not master_rec:
                    return {"status": "error", "error_message": "MASTER_TYPE_NOT_FOUND", "synced_at": None}
                standard_id = master_rec.id

            # 4. upsert datatype_raw_mapping
            await session.execute(
                text("""
                    INSERT INTO datatype_raw_mapping
                        (db_id, source_type, raw_type, logical_type, standard_id)
                    VALUES
                        (:db_id, :source_type, :raw_type, :logical_type, :standard_id)
                    ON CONFLICT (db_id, raw_type)
                    DO UPDATE SET
                        source_type  = EXCLUDED.source_type,
                        logical_type = EXCLUDED.logical_type,
                        standard_id  = EXCLUDED.standard_id
                """),
                {
                    "db_id":        src_db_rec.id,
                    "source_type":  rule_data.get("source_type") or "",
                    "raw_type":     rule_data["raw_type"],
                    "logical_type": rule_data.get("logical_type") or "",
                    "standard_id":  standard_id,
                },
            )

            # 5. upsert datatype_mapping (เฉพาะเมื่อมี standard_id)
            if standard_id is not None:
                await session.execute(
                    text("""
                        INSERT INTO datatype_mapping
                            (db_id, standard_id, final_type)
                        VALUES
                            (:db_id, :standard_id, :final_type)
                        ON CONFLICT (db_id, standard_id)
                        DO UPDATE SET
                            final_type = EXCLUDED.final_type
                    """),
                    {
                        "db_id":       dest_db_rec.id,
                        "standard_id": standard_id,
                        "final_type":  rule_data.get("final_type") or "",
                    },
                )

            await session.commit()

            elapsed_ms = int((datetime.now(timezone.utc) - start).total_seconds() * 1000)
            logger.info(
                "[sync] SYNCED rule_id=%s %s→%s raw_type=%s elapsed_ms=%d",
                rule_id, rule_data["src_db"], rule_data["dest_db"], rule_data["raw_type"], elapsed_ms,
            )
            return {"status": "synced", "error_message": None, "synced_at": datetime.now(timezone.utc)}

        except Exception as exc:
            await session.rollback()
            logger.error("[sync] ERROR rule_id=%s: %s\n%s", rule_id, exc, traceback.format_exc())
            return {"status": "error", "error_message": "DATABASE_ERROR", "synced_at": None}


# ─────────────────────────────────────────────────────────────────────────────
# Update rule status — session แยกเช่นกัน
# ─────────────────────────────────────────────────────────────────────────────

async def _update_rule(rule_id: int, outcome: dict, retry_count: int) -> bool:
    """อัปเดต mapping_rules ตาม outcome — session แยกต่อ row"""
    async with AsyncSessionLocal() as session:
        try:
            result = await session.execute(
                select(MappingRule).where(MappingRule.id == rule_id)
            )
            rule = result.scalar_one_or_none()
            if not rule:
                return False

            rule.status        = outcome["status"]
            rule.error_message = outcome["error_message"]
            rule.synced_at     = outcome["synced_at"]
            if outcome["status"] == "error":
                rule.retry_count = retry_count + 1
            else:
                rule.retry_count = 0

            await session.commit()
            return True
        except Exception as e:
            await session.rollback()
            logger.error("[sync] Failed to update rule_id=%s: %s", rule_id, e)
            return False


# ─────────────────────────────────────────────────────────────────────────────
# Main sync cycle
# ─────────────────────────────────────────────────────────────────────────────

async def run_sync_cycle() -> dict:
    """
    Sync ทุก row ที่ต้อง sync:
      - status = "pending"
      - status = "active" และ synced_at IS NULL
      - status = "error"  และ retry_count < MAX_RETRIES
    """
    global _sync_running, _last_run_at, _last_metrics

    if _sync_running:
        logger.warning("[sync] Already running — skipped")
        return {"skipped": True, **_last_metrics}

    _sync_running = True
    metrics = {"processed": 0, "synced": 0, "errors": 0}
    cycle_start = datetime.now(timezone.utc)
    logger.info("[sync] Cycle started")

    try:
        # ดึง rows ที่ต้อง sync (read-only session แยก)
        async with AsyncSessionLocal() as session:
            result = await session.execute(
                select(MappingRule)
                .where(
                    (MappingRule.status == "pending") |
                    ((MappingRule.status == "active")  & (MappingRule.synced_at == None)) |
                    ((MappingRule.status == "error")   & (MappingRule.retry_count < MAX_RETRIES))
                )
                .order_by(MappingRule.id)
                .limit(BATCH_SIZE)
            )
            rows = result.scalars().all()

            if not rows:
                logger.info("[sync] Nothing to sync — cycle complete")
                _last_run_at  = cycle_start
                _last_metrics = metrics
                return metrics

            # snapshot ข้อมูลออกมาก่อน — ไม่ผูก session ไว้
            pending = [
                {
                    "id":          r.id,
                    "src_db":      r.src_db,
                    "dest_db":     r.dest_db,
                    "raw_type":    r.raw_type,
                    "source_type": r.source_type,
                    "logical_type":r.logical_type,
                    "master_type": r.master_type,
                    "final_type":  r.final_type,
                    "retry_count": r.retry_count or 0,
                }
                for r in rows
            ]

        logger.info("[sync] %d row(s) to process", len(pending))

        for row in pending:
            metrics["processed"] += 1

            # retry backoff
            backoff = RETRY_BACKOFF_SECONDS[min(row["retry_count"], len(RETRY_BACKOFF_SECONDS) - 1)]
            if backoff > 0:
                await asyncio.sleep(backoff)

            # process + update — session แยกต่อ row
            outcome = await _process_row(row["id"], row)
            ok = await _update_rule(row["id"], outcome, row["retry_count"])

            if outcome["status"] == "synced" and ok:
                metrics["synced"] += 1
            else:
                metrics["errors"] += 1

    except Exception as cycle_err:
        logger.error("[sync] Cycle error: %s\n%s", cycle_err, traceback.format_exc())

    finally:
        _sync_running = False

    elapsed = round((datetime.now(timezone.utc) - cycle_start).total_seconds(), 2)
    logger.info(
        "[sync] Cycle done: processed=%d synced=%d errors=%d elapsed=%.2fs",
        metrics["processed"], metrics["synced"], metrics["errors"], elapsed,
    )
    metrics["elapsed_seconds"] = elapsed
    _last_run_at  = cycle_start
    _last_metrics = metrics
    return metrics


# ─────────────────────────────────────────────────────────────────────────────
# Auto-scheduler
# ─────────────────────────────────────────────────────────────────────────────

async def _scheduler_loop():
    logger.info("[sync] Scheduler started — interval=%ds", SYNC_INTERVAL_SECONDS)
    while True:
        try:
            await run_sync_cycle()
        except Exception as e:
            logger.error("[sync] Scheduler error: %s", e)
        await asyncio.sleep(SYNC_INTERVAL_SECONDS)


def start_scheduler():
    global _scheduler_task
    if _scheduler_task is None or _scheduler_task.done():
        _scheduler_task = asyncio.create_task(_scheduler_loop())
        logger.info("[sync] Scheduler task created")


def stop_scheduler():
    global _scheduler_task
    if _scheduler_task and not _scheduler_task.done():
        _scheduler_task.cancel()
        logger.info("[sync] Scheduler task cancelled")


def get_status() -> dict:
    return {
        "running":          _sync_running,
        "last_run_at":      _last_run_at.isoformat() if _last_run_at else None,
        "last_metrics":     _last_metrics,
        "interval_seconds": SYNC_INTERVAL_SECONDS,
        "scheduler_active": _scheduler_task is not None and not _scheduler_task.done(),
    }


# ─────────────────────────────────────────────────────────────────────────────
# Standalone
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s — %(message)s")
    result = asyncio.run(run_sync_cycle())
    print(f"\n✅ Sync result: {result}")
    sys.exit(0 if result.get("errors", 0) == 0 else 1)