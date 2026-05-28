import time
import logging
from collections import deque
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from datetime import datetime, timezone

from app.db.database import AsyncSessionLocal
from app.db.models import SystemLog

logger = logging.getLogger(__name__)
_RECENT_REQUEST_LOGS = deque(maxlen=500)


def get_recent_request_logs(limit: int = 200) -> list[dict]:
    items = list(_RECENT_REQUEST_LOGS)
    return items[-limit:]


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000

        logger.info(
            f"{request.method} {request.url.path} "
            f"→ {response.status_code} ({duration_ms:.1f}ms)"
        )

        # Persist admin-backend request logs for /api/admin-logs page.
        # Keep this best-effort to avoid impacting request flow.
        try:
            path = request.url.path or ""
            if not path.startswith("/api/admin-logs"):
                level = "ERROR" if response.status_code >= 500 else "WARN" if response.status_code >= 400 else "INFO"
                message = f"{request.method} {path} -> {response.status_code} ({duration_ms:.1f}ms)"
                detail = f"client={request.client.host if request.client else '-'} query={request.url.query or '-'}"
                created_at = datetime.now(timezone.utc)
                _RECENT_REQUEST_LOGS.append({
                    "level": level,
                    "source": "admin-backend",
                    "message": message,
                    "detail": detail,
                    "created_at": created_at.isoformat(),
                })
                async with AsyncSessionLocal() as db:
                    db.add(SystemLog(
                        level=level,
                        source="admin-backend",
                        message=message,
                        detail=detail,
                        created_at=created_at,
                    ))
                    await db.commit()
        except Exception as e:
            logger.warning("Failed to persist system log: %s", e)

        # Expose timing in response header
        response.headers["X-Process-Time-Ms"] = f"{duration_ms:.1f}"
        return response
