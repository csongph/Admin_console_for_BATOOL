"""
log_retention_scheduler.py
──────────────────────────
Background task — ตรวจ retention settings และลบ log เก่าอัตโนมัติ

แก้ไข:
  - ใช้ APScheduler แทน asyncio.sleep fixed 3600s
  - อ่าน interval_hours จาก DB ทุกรอบ (dynamic)
  - reschedule อัตโนมัติเมื่อ interval เปลี่ยน
  - error จะ retry รอบถัดไปแทนการหยุด
"""

import asyncio
import logging
from typing import Optional

logger = logging.getLogger(__name__)

_scheduler = None
_current_interval_hours: int = 0   # track interval ปัจจุบัน เพื่อ reschedule เมื่อเปลี่ยน


async def _run_retention_job():
    """งานหลัก — รันทุกรอบที่ scheduler ยิง"""
    global _scheduler, _current_interval_hours

    try:
        from app.db.database import AsyncSessionLocal
        from app.services import log_retention_service
        from app.routers import activity as activity_router

        async with AsyncSessionLocal() as db:
            # ดึง interval_hours ปัจจุบันจาก DB
            settings = await log_retention_service.get_retention_settings(db)
            interval_hours = settings.get("interval_hours", 24)

            # reschedule ถ้า interval เปลี่ยน
            if _scheduler and interval_hours != _current_interval_hours and interval_hours > 0:
                _scheduler.reschedule_job(
                    "log_retention",
                    trigger="interval",
                    hours=interval_hours,
                )
                logger.info(
                    "[log-retention] Rescheduled — interval changed %dh → %dh",
                    _current_interval_hours,
                    interval_hours,
                )
                _current_interval_hours = interval_hours

            # รัน retention
            result = await log_retention_service.run_scheduled_retention(db)
            if result.get("skipped"):
                logger.debug("[log-retention] Skipped: %s", result.get("reason"))
            else:
                logger.info(
                    "[log-retention] Done — batool=%d admin=%d retention=%dd",
                    result.get("batool_deleted", 0),
                    result.get("admin_deleted", 0),
                    result.get("retention_days", 0),
                )

            # รัน activity retention
            activity_result = await activity_router.run_scheduled_activity_clear(db)
            if activity_result:
                logger.info(
                    "[activity-retention] Done — deleted=%d interval=%dd",
                    activity_result.get("deleted", 0),
                    activity_result.get("interval_days", 0),
                )

    except Exception as e:
        logger.error("[log-retention] Job error (will retry next interval): %s", e, exc_info=True)


def start_scheduler():
    global _scheduler, _current_interval_hours

    try:
        from apscheduler.schedulers.asyncio import AsyncIOScheduler  # type: ignore
    except ImportError:
        logger.warning(
            "[log-retention] apscheduler ไม่ได้ติดตั้ง — fallback ใช้ asyncio loop แทน"
        )
        _start_fallback_loop()
        return

    if _scheduler is not None and _scheduler.running:
        logger.info("[log-retention] Scheduler already running")
        return

    _current_interval_hours = 1  # default รอบแรก — จะ reschedule เมื่อรันครั้งแรก

    _scheduler = AsyncIOScheduler(timezone="UTC")
    _scheduler.add_job(
        _run_retention_job,
        trigger="interval",
        hours=_current_interval_hours,
        id="log_retention",
        replace_existing=True,
        max_instances=1,        # ห้ามรันซ้อน
        misfire_grace_time=300, # ถ้า miss ไป ยังรันได้ใน 5 นาที
    )
    _scheduler.start()
    logger.info("[log-retention] APScheduler started — initial interval %dh", _current_interval_hours)

    # รันครั้งแรกทันทีหลัง startup (ไม่รอ 1 ชม.)
    asyncio.get_event_loop().call_soon(
        lambda: asyncio.ensure_future(_run_retention_job())
    )


def stop_scheduler():
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("[log-retention] APScheduler stopped")
    _scheduler = None


# ── Fallback กรณีไม่มี apscheduler ──────────────────────────────────────────

_fallback_task: Optional[asyncio.Task] = None


def _start_fallback_loop():
    global _fallback_task
    if _fallback_task is None or _fallback_task.done():
        _fallback_task = asyncio.ensure_future(_fallback_loop())
        logger.info("[log-retention] Fallback asyncio loop started")


async def _fallback_loop():
    """Fallback loop — อ่าน interval_hours จาก DB ทุกรอบ"""
    logger.info("[log-retention] Fallback loop running")

    # รอ 10 วิหลัง startup แล้วรันครั้งแรก
    await asyncio.sleep(10)

    while True:
        await _run_retention_job()

        # อ่าน interval ใหม่จาก DB
        try:
            from app.db.database import AsyncSessionLocal
            from app.services import log_retention_service
            async with AsyncSessionLocal() as db:
                settings = await log_retention_service.get_retention_settings(db)
                sleep_seconds = max(3600, settings.get("interval_hours", 24) * 3600)
        except Exception:
            sleep_seconds = 3600

        logger.debug("[log-retention] Fallback sleeping %ds", sleep_seconds)
        await asyncio.sleep(sleep_seconds)