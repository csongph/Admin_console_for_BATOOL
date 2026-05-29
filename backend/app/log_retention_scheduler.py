"""
log_retention_scheduler.py
──────────────────────────
Background task — ตรวจ retention settings และลบ log เก่าอัตโนมัติ
"""

import asyncio
import logging
from typing import Optional

from app.db.database import AsyncSessionLocal
from app.services import log_retention_service

logger = logging.getLogger(__name__)

CHECK_INTERVAL_SECONDS = 3600  # ตรวจทุก 1 ชม.
_scheduler_task: Optional[asyncio.Task] = None


async def _scheduler_loop():
    logger.info("[log-retention] Scheduler started — check every %ds", CHECK_INTERVAL_SECONDS)
    while True:
        try:
            async with AsyncSessionLocal() as db:
                await log_retention_service.run_scheduled_retention(db)
        except Exception as e:
            logger.error("[log-retention] Scheduler error: %s", e)
        await asyncio.sleep(CHECK_INTERVAL_SECONDS)


def start_scheduler():
    global _scheduler_task
    if _scheduler_task is None or _scheduler_task.done():
        _scheduler_task = asyncio.create_task(_scheduler_loop())
        logger.info("[log-retention] Scheduler task created")


def stop_scheduler():
    global _scheduler_task
    if _scheduler_task and not _scheduler_task.done():
        _scheduler_task.cancel()
        logger.info("[log-retention] Scheduler task cancelled")
