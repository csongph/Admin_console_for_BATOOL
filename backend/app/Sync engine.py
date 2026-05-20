import asyncio
import logging
import traceback
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select, func, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import AsyncSessionLocal
from app.db.models import MappingRule, DatabaseRecord, DatatypeStandard

logger = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────────────────────
BATCH_SIZE   = 100   # จำนวน row ต่อ batch
MAX_RETRIES  = 3     # จำนวน retry สูงสุดต่อ row


# ── Lookup helpers ────────────────────────────────────────────────────────────

async def _lookup_db(session: AsyncSession, key: str) -> Optional[DatabaseRecord]:
    """Case-insensitive, trim-safe lookup"""
    key_clean = key.strip().lower()
    result = await session.execute(
        select(DatabaseRecord).where(
            func.lower(DatabaseRecord.key) == key_clean
        )
    )
    return result.scalar_one_or_none()


async def _lookup_master_type(session: AsyncSession, standard_type: str) -> Optional[DatatypeStandard]:
    result = await session.execute(
        select(DatatypeStandard).where(
            DatatypeStandard.standard_type == standard_type.strip()
        )
    )
    return result.scalar_one_or_none()


# ── Row processor ─────────────────────────────────────────────────────────────

async def _process_row(session: AsyncSession, rule: MappingRule) -> dict:
    """
    Process single mapping_rule row.
    Returns dict with status, error_message, synced_at.
    ไม่ throw — error handling ทั้งหมดอยู่ใน function นี้ (row-level isolation)
    """
    start = datetime.now(timezone.utc)
    rule_id = rule.id

    try:
        # STEP 1: lookup src_db
        src_db_rec = await _lookup_db(session, rule.src_db)
        if not src_db_rec:
            logger.warning("[sync] rule_id=%s SOURCE_DB_NOT_FOUND src_db=%s", rule_id, rule.src_db)
            return {"status": "error", "error_message": "SOURCE_DB_NOT_FOUND", "synced_at": None}

        # STEP 2: lookup dest_db
        dest_db_rec = await _lookup_db(session, rule.dest_db)
        if not dest_db_rec:
            logger.warning("[sync] rule_id=%s DEST_DB_NOT_FOUND dest_db=%s", rule_id, rule.dest_db)
            return {"status": "error", "error_message": "DEST_DB_NOT_FOUND", "synced_at": None}

        # STEP 3: lookup master_type (optional — ถ้า master_type ว่างให้ข้ามได้)
        master_rec = None
        if rule.master_type and rule.master_type.strip():
            master_rec = await _lookup_master_type(session, rule.master_type)
            if not master_rec:
                logger.warning("[sync] rule_id=%s MASTER_TYPE_NOT_FOUND master_type=%s", rule_id, rule.master_type)
                return {"status": "error", "error_message": "MASTER_TYPE_NOT_FOUND", "synced_at": None}

        # STEP 4: insert datatype_raw_mapping + datatype_mapping
        # ใช้ raw SQL + ON CONFLICT DO NOTHING เพื่อ idempotency
        standard_id = master_rec.id if master_rec else None

        try:
            await session.execute(
                text("""
                    INSERT INTO datatype_raw_mapping
                        (db_id, source_type, raw_type, logical_type, standard_id)
                    VALUES
                        (:db_id, :source_type, :raw_type, :logical_type, :standard_id)
                    ON CONFLICT DO NOTHING
                """),
                {
                    "db_id":        src_db_rec.id,
                    "source_type":  rule.source_type or "",
                    "raw_type":     rule.raw_type,
                    "logical_type": rule.logical_type or "",
                    "standard_id":  standard_id,
                },
            )
        except Exception as e:
            # datatype_raw_mapping อาจยังไม่มี column — log แล้วข้าม
            logger.debug("[sync] rule_id=%s datatype_raw_mapping insert skipped: %s", rule_id, e)

        try:
            if standard_id is not None:
                await session.execute(
                    text("""
                        INSERT INTO datatype_mapping
                            (db_id, standard_id, final_type)
                        VALUES
                            (:db_id, :standard_id, :final_type)
                        ON CONFLICT DO NOTHING
                    """),
                    {
                        "db_id":      dest_db_rec.id,
                        "standard_id": standard_id,
                        "final_type":  rule.final_type or "",
                    },
                )
        except Exception as e:
            logger.debug("[sync] rule_id=%s datatype_mapping insert skipped: %s", rule_id, e)

        # STEP 5: mark synced
        elapsed_ms = int((datetime.now(timezone.utc) - start).total_seconds() * 1000)
        logger.info(
            "[sync] rule_id=%s SYNCED src=%s dest=%s raw_type=%s elapsed_ms=%d",
            rule_id, rule.src_db, rule.dest_db, rule.raw_type, elapsed_ms,
        )
        return {
            "status":        "synced",
            "error_message": None,
            "synced_at":     datetime.now(timezone.utc),
        }

    except Exception as exc:
        logger.error(
            "[sync] rule_id=%s DATABASE_ERROR: %s\n%s",
            rule_id, exc, traceback.format_exc(),
        )
        return {"status": "error", "error_message": "DATABASE_ERROR", "synced_at": None}


# ── Main sync cycle ───────────────────────────────────────────────────────────

async def run_sync_cycle() -> dict:
    """
    Sync ทุก pending row แบบ batch + row-level isolation
    Returns metrics dict
    """
    metrics = {"processed": 0, "synced": 0, "errors": 0, "skipped": 0}
    cycle_start = datetime.now(timezone.utc)
    logger.info("[sync] Cycle started at %s", cycle_start.isoformat())

    async with AsyncSessionLocal() as session:
        try:
            # ดึง pending rows (batch)
            result = await session.execute(
                select(MappingRule)
                .where(MappingRule.status == "pending")
                .where(MappingRule.retry_count < MAX_RETRIES)
                .order_by(MappingRule.id)
                .limit(BATCH_SIZE)
            )
            rows = result.scalars().all()

            if not rows:
                logger.info("[sync] No pending rows — cycle complete")
                return metrics

            logger.info("[sync] Processing %d pending row(s)", len(rows))

            for rule in rows:
                metrics["processed"] += 1
                outcome = await _process_row(session, rule)

                # อัปเดต rule ตาม outcome (row-level — ไม่ทำให้ row อื่นพัง)
                try:
                    rule.status        = outcome["status"]
                    rule.error_message = outcome["error_message"]
                    rule.synced_at     = outcome["synced_at"]
                    if outcome["status"] == "error":
                        rule.retry_count = (rule.retry_count or 0) + 1
                        metrics["errors"] += 1
                    else:
                        rule.retry_count = 0
                        metrics["synced"] += 1
                    await session.commit()
                except Exception as commit_err:
                    await session.rollback()
                    logger.error("[sync] Failed to commit rule_id=%s: %s", rule.id, commit_err)
                    metrics["errors"] += 1

        except Exception as cycle_err:
            logger.error("[sync] Cycle-level error: %s\n%s", cycle_err, traceback.format_exc())
            await session.rollback()

    elapsed = (datetime.now(timezone.utc) - cycle_start).total_seconds()
    logger.info(
        "[sync] Cycle complete: processed=%d synced=%d errors=%d elapsed=%.2fs",
        metrics["processed"], metrics["synced"], metrics["errors"], elapsed,
    )
    return metrics


# ─── Standalone execution ─────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    )
    result = asyncio.run(run_sync_cycle())
    print(f"\n✅ Sync result: {result}")
    sys.exit(0 if result["errors"] == 0 else 1)