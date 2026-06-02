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
    import traceback
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
        if "app" + os.sep in filename:
            rel = filename.split("app" + os.sep, 1)[-1]
        else:
            rel = os.path.basename(filename)

        if any(filename.replace("\\", "/").endswith(p.replace("\\", "/")) for p in skip_prefixes):
            continue
        if filename.startswith("<"):
            continue
        return f"{rel}:{frame_info.lineno}"

    return "unknown"


class _FileTrackingHandler(logging.Handler):
    def emit(self, record: logging.LogRecord) -> None:
        pathname = record.pathname or ""
        if "app" + os.sep in pathname:
            rel = pathname.split("app" + os.sep, 1)[-1]
        else:
            rel = record.filename
        record.source_file = f"{rel}:{record.lineno}"


_tracking_handler = _FileTrackingHandler()
_tracking_handler.setLevel(logging.DEBUG)
logging.getLogger().addHandler(_tracking_handler)


def _extract_username_from_request(request: Request) -> str:
    """
    พยายามดึง username จาก JWT token ใน Authorization header
    คืน 'anonymous' ถ้าไม่มี token หรือ decode ไม่ได้
    """
    try:
        auth = request.headers.get("authorization", "")
        if not auth.startswith("Bearer "):
            return "anonymous"
        token = auth.split(" ", 1)[1]
        import base64, json
        # decode JWT payload (ไม่ verify signature — แค่อ่าน claim)
        payload_part = token.split(".")[1]
        # เติม padding ให้ครบ
        padding = 4 - len(payload_part) % 4
        if padding != 4:
            payload_part += "=" * padding
        payload = json.loads(base64.urlsafe_b64decode(payload_part))
        return payload.get("sub") or payload.get("username") or "unknown"
    except Exception:
        return "anonymous"


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000

        # ใช้เวลาจริงจากเครื่อง server
        created_at = datetime.now(timezone.utc)

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
                # ดึง username จาก token
                username = _extract_username_from_request(request)

                message = (
                    f"{request.method} {path} "
                    f"-> {response.status_code} ({duration_ms:.1f}ms)"
                )
                detail = (
                    f"client={request.client.host if request.client else '-'} "
                    f"query={request.url.query or '-'} "
                    f"user={username}"  # ← เพิ่ม username ใน detail ด้วย
                )
                external_key = f"admin:{request.method}:{path}:{int(created_at.timestamp() * 1000)}"
                source_file  = this_file

                _RECENT_REQUEST_LOGS.append({
                    "level":       level,
                    "source":      "admin-console",
                    "source_file": source_file,
                    "username":    username,
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
                        username     = username,   # ← บันทึก username ลง DB
                        external_key = external_key,
                        created_at   = created_at,
                    ))
                    await db.commit()
        except Exception as e:
            logger.warning("Failed to persist system log: %s", e)

        response.headers["X-Process-Time-Ms"] = f"{duration_ms:.1f}"
        return response