"""
app/routers/presence.py
───────────────────────
Real-time online user tracking via FastAPI WebSocket.

  ws://host/ws/presence              ← user pages connect here
  ws://host/ws/presence/admin?token= ← admin console (requires JWT)
"""

import json
import uuid
import asyncio
from datetime import datetime, timezone
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, HTTPException
from jose import JWTError, jwt

from app.core.config import settings

ALGORITHM = "HS256"

router = APIRouter(tags=["Presence"])

online_users: dict[str, dict] = {}
admin_connections: set[WebSocket] = set()

HEARTBEAT_INTERVAL = 30
HEARTBEAT_TIMEOUT  = 90


# ── Auth helper ───────────────────────────────────────────────────────────────

def _verify_token(token: str) -> str:
    """ตรวจ JWT แล้วคืน username หรือ raise ถ้า invalid"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if not username:
            raise ValueError("no sub")
        return username
    except (JWTError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# ── Helpers ───────────────────────────────────────────────────────────────────

def _serialize_users() -> list[dict]:
    now = datetime.now(timezone.utc).timestamp()
    return [
        {**u, "idle_seconds": int(now - u["last_ping"])}
        for u in online_users.values()
    ]


async def _broadcast_to_admins(event: str, payload: dict) -> None:
    dead: set[WebSocket] = set()
    message = json.dumps({"event": event, **payload})
    for ws in admin_connections:
        try:
            await ws.send_text(message)
        except Exception:
            dead.add(ws)
    admin_connections.difference_update(dead)


async def _evict_stale() -> None:
    """Background task: ลบ users ที่ไม่ ping มาเกิน timeout"""
    while True:
        await asyncio.sleep(HEARTBEAT_INTERVAL)
        now   = datetime.now(timezone.utc).timestamp()
        stale = [
            cid for cid, u in online_users.items()
            if now - u["last_ping"] > HEARTBEAT_TIMEOUT
        ]
        for cid in stale:
            online_users.pop(cid, None)
        if stale:
            await _broadcast_to_admins(
                "update_online_users",
                {"users": _serialize_users(), "total": len(online_users)},
            )


# ── User WebSocket ────────────────────────────────────────────────────────────

@router.websocket("/ws/presence")
async def user_presence(ws: WebSocket):
    await ws.accept()
    client_id = str(uuid.uuid4())
    try:
        raw  = await asyncio.wait_for(ws.receive_text(), timeout=10)
        data = json.loads(raw)
        if data.get("event") != "user_online":
            await ws.close(code=4000)
            return

        now = datetime.now(timezone.utc)
        online_users[client_id] = {
            "client_id":    client_id,
            "user_id":      data.get("user_id"),
            "page":         data.get("page", "/"),
            "user_agent":   data.get("user_agent", ""),
            "connected_at": now.isoformat(),
            "last_ping":    now.timestamp(),
        }
        await _broadcast_to_admins(
            "update_online_users",
            {"users": _serialize_users(), "total": len(online_users)},
        )

        while True:
            raw = await ws.receive_text()
            msg = json.loads(raw)
            event = msg.get("event")
            if event == "ping":
                online_users[client_id]["last_ping"] = datetime.now(timezone.utc).timestamp()
                await ws.send_text(json.dumps({"event": "pong"}))
            elif event == "page_change":
                online_users[client_id]["page"]      = msg.get("page", "/")
                online_users[client_id]["last_ping"]  = datetime.now(timezone.utc).timestamp()
                await _broadcast_to_admins(
                    "update_online_users",
                    {"users": _serialize_users(), "total": len(online_users)},
                )
    except (WebSocketDisconnect, asyncio.TimeoutError, Exception):
        pass
    finally:
        online_users.pop(client_id, None)
        await _broadcast_to_admins(
            "update_online_users",
            {"users": _serialize_users(), "total": len(online_users)},
        )


# ── Admin WebSocket — ต้องมี JWT token ───────────────────────────────────────

@router.websocket("/ws/presence/admin")
async def admin_presence(
    ws:    WebSocket,
    token: str = Query(..., description="JWT access token"),
):
    # ตรวจ token ก่อน accept — ถ้า invalid ปิดทันที
    try:
        username = _verify_token(token)
    except HTTPException:
        await ws.close(code=4001)
        return

    await ws.accept()
    admin_connections.add(ws)
    client_id = f"admin-{uuid.uuid4()}"
    now = datetime.now(timezone.utc)
    online_users[client_id] = {
        "client_id":    client_id,
        "user_id":      username,
        "page":         "admin-console",
        "user_agent":   "Admin Console",
        "connected_at": now.isoformat(),
        "last_ping":    now.timestamp(),
    }

    # ส่ง snapshot ปัจจุบันทันทีหลัง connect
    await ws.send_text(json.dumps({
        "event": "update_online_users",
        "users": _serialize_users(),
        "total": len(online_users),
    }))

    try:
        while True:
            raw = await ws.receive_text()
            if json.loads(raw).get("event") == "ping":
                online_users[client_id]["last_ping"] = datetime.now(timezone.utc).timestamp()
                await ws.send_text(json.dumps({"event": "pong"}))
    except (WebSocketDisconnect, Exception):
        pass
    finally:
        online_users.pop(client_id, None)
        admin_connections.discard(ws)
        await _broadcast_to_admins(
            "update_online_users",
            {"users": _serialize_users(), "total": len(online_users)},
        )


# ── REST snapshot ─────────────────────────────────────────────────────────────

@router.get("/api/presence")
async def get_presence():
    return {
        "success": True,
        "total":   len(online_users),
        "users":   _serialize_users(),
    }
