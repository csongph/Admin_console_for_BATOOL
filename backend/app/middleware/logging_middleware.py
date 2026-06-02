import os
import time
import logging
from collections import deque
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from datetime import datetime, timezone

from app.db.database import AsyncSessionLocal
from app.db.models import AdminConsoleLog

logger = logging.getLogger(__name__)
_RECENT_REQUEST_LOGS = deque(maxlen=500)


def get_recent_request_logs(limit: int = 200) -> list[dict]:
    items = list(_RECENT_REQUEST_LOGS)
    return items[-limit:]


def clear_recent_request_logs() -> int:
    count = len(_RECENT_REQUEST_LOGS)
    _RECENT_REQUEST_LOGS.clear()
    return count


def _caller_source_file() -> str:
    """
    หา source_file จาก logging record ของ caller จริง
    คืนค่าในรูป 'routers/mappings.py:164'
    """
    import traceback
    import sys

    # walk the call stack เพื่อหา frame แรกที่ไม่ใช่ logging / middleware
    skip_prefixes = (
        os.path.join("logging"),
        os.path.join("middleware", "logging_middleware"),
        os.path.join("starlette"),
        os.path.join("uvicorn"),
        os.path.join("fastapi"),
        "<frozen",
    )
    for frame_info in traceback.extract_stack():
        filename = frame_info.filename
        # normalize ให้เป็น relative path จาก "app/"
        if "app" + os.sep in filename:
            rel = filename.split("app" + os.sep, 1)[-1]
        else:
            rel = os.path.basename(filename)

        # ข้าม frame ที่ไม่น่าสนใจ
        if any(filename.replace("\\", "/").endswith(p.replace("\\", "/")) for p in skip_prefixes):
            continue
        if filename.startswith("<"):
            continue
        return f"{rel}:{frame_info.lineno}"

    return "unknown"


class _FileTrackingHandler(logging.Handler):
    """
    Handler ที่แนบ source_file กลับมาด้วย โดยใช้ข้อมูลจาก LogRecord โดยตรง
    (%(filename)s:%(lineno)d) — แม่นยำกว่า stack walk
    """

    def emit(self, record: logging.LogRecord) -> None:
        # ดึงชื่อไฟล์จริงจาก record (Python logging ติดมาให้แล้ว)
        # record.pathname = full path, record.filename = basename only
        pathname = record.pathname or ""
        if "app" + os.sep in pathname:
            rel = pathname.split("app" + os.sep, 1)[-1]
        else:
            rel = record.filename

        # เก็บใน record เผื่อ middleware จะอ่านทีหลัง
        record.source_file = f"{rel}:{record.lineno}"


# ติดตั้ง handler ระดับ root ให้ทำงานตลอดเวลา
_tracking_handler = _FileTrackingHandler()
_tracking_handler.setLevel(logging.DEBUG)
logging.getLogger().addHandler(_tracking_handler)


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000

        # source_file สำหรับ middleware log line นี้
        this_file = f"middleware/logging_middleware.py:{logging.currentframe().f_lineno}"

        logger.info(
            f"{request.method} {request.url.path} "
            f"→ {response.status_code} ({duration_ms:.1f}ms)"
        )

        try:
            path = request.url.path or ""
            if not path.startswith("/api/admin-logs"):
                level = (
                    "ERROR" if response.status_code >= 500
                    else "WARN"  if response.status_code >= 400
                    else "INFO"
                )
                message = (
                    f"{request.method} {path} "
                    f"-> {response.status_code} ({duration_ms:.1f}ms)"
                )
                detail = (
                    f"client={request.client.host if request.client else '-'} "
                    f"query={request.url.query or '-'}"
                )
                created_at   = datetime.now(timezone.utc)
                external_key = f"admin:{request.method}:{path}:{int(created_at.timestamp() * 1000)}"
                source_file  = this_file

                _RECENT_REQUEST_LOGS.append({
                    "level":       level,
                    "source":      "admin-console",
                    "source_file": source_file,
                    "message":     message,
                    "detail":      detail,
                    "created_at":  created_at.isoformat(),
                })
                async with AsyncSessionLocal() as db:
                    db.add(AdminConsoleLog(
                        level        = level,
                        message      = message,
                        detail       = detail,
                        source_file  = source_file,
                        external_key = external_key,
                        created_at   = created_at,
                    ))
                    await db.commit()
        except Exception as e:
            logger.warning("Failed to persist system log: %s", e)

        response.headers["X-Process-Time-Ms"] = f"{duration_ms:.1f}"
        return response