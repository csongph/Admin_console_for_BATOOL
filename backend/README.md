# BA Tool — Admin Console Backend

FastAPI backend สำหรับ Admin Console ของ BA_TOOL ใช้จัดการ mapping, users, maintenance mode และ sync ข้อมูลไปยัง BA_TOOL

Deploy บน [Render](https://render.com) ผ่าน `render.yaml` ได้ทันที

---

## Project Structure

```
backend/
├── app/
│   ├── main.py                     # entry point, middleware, routers
│   ├── core/
│   │   ├── config.py               # settings จาก environment variables
│   │   └── security.py             # JWT + password hashing
│   ├── db/
│   │   ├── database.py             # SQLAlchemy async engine + session
│   │   └── models.py               # ORM models
│   ├── routers/
│   │   ├── auth.py                 # login, refresh, me, logout
│   │   ├── mappings.py             # CRUD mapping + bulk import
│   │   ├── databases.py            # CRUD database engine records
│   │   ├── users.py                # CRUD admin users
│   │   ├── sessions.py             # session management
│   │   ├── system.py               # system control + maintenance mode
│   │   ├── sync.py                 # sync engine trigger
│   │   ├── presence.py             # WebSocket user tracking
│   │   ├── activity.py             # activity log
│   │   ├── logs.py                 # BA_TOOL backend logs
│   │   └── admin_logs.py           # admin action logs
│   ├── services/                   # business logic
│   ├── schemas/                    # Pydantic request/response models
│   ├── middleware/
│   │   ├── logging_middleware.py
│   │   ├── maintenance_middleware.py
│   │   └── rate_limit_middleware.py
│   ├── sync_engine.py              # sync scheduler
│   └── log_retention_scheduler.py  # log cleanup scheduler
├── migrations/                     # SQL migration scripts
├── requirements.txt
├── .env.example
└── render.yaml
```

---

## Local Setup

**1. เข้าโฟลเดอร์ backend**

```bash
cd backend
```

**2. สร้าง virtual environment**

```bash
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
```

**3. ติดตั้ง dependencies**

```bash
pip install -r requirements.txt
```

**4. ตั้งค่า environment**

```bash
cp .env.example .env
# แก้ไขค่าใน .env ดู .env.example เป็นต้นแบบ
```

**5. รัน server**

```bash
uvicorn app.main:app --reload
```

API: `http://localhost:8000`
Interactive docs (dev only): `http://localhost:8000/docs`

---

## Deploy บน Render

1. Push repo ขึ้น GitHub
2. ไปที่ [render.com](https://render.com) → **New** → **Blueprint**
3. เชื่อม repo — Render จะ detect `render.yaml` อัตโนมัติ
4. ตั้งค่า environment variables ใน Render dashboard:

| Key | หมายเหตุ |
|-----|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY` | auto-generate ได้ใน Render |
| `ADMIN_PASSWORD` | password ของ superadmin |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | default `60` |
| `ENVIRONMENT` | `production` |
| `ADMIN_USERNAME` | default `admin` |

> `/docs` และ `/redoc` จะถูกปิดอัตโนมัติเมื่อ `ENVIRONMENT=production`

---

## API Reference

### Auth

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `POST` | `/api/auth/login` | — | เข้าสู่ระบบ รับ JWT token |
| `POST` | `/api/auth/refresh` | token | refresh token |
| `GET` | `/api/auth/me` | token | ดูข้อมูล user ปัจจุบัน |
| `POST` | `/api/auth/logout` | token | ออกจากระบบ |

### Mappings

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/mappings` | token | ดึง mapping ทั้งหมด |
| `POST` | `/api/mappings` | token | เพิ่ม mapping |
| `PUT` | `/api/mappings/{id}` | token | แก้ไข mapping |
| `DELETE` | `/api/mappings/{id}` | token | ลบ mapping |
| `POST` | `/api/mappings/bulk-import` | token | import จาก Excel |
| `GET` | `/api/datatype-standard/list` | token | ดึงรายการ standard type |

### Databases

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/databases` | token | ดึงรายการ database engine |
| `POST` | `/api/databases` | token | เพิ่ม database engine |
| `PUT` | `/api/databases/{id}` | token | แก้ไข |
| `DELETE` | `/api/databases/{id}` | token | ลบ |
| `GET` | `/api/database-records/enabled` | token | ดึงเฉพาะที่เปิดใช้งาน |

### Users

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/users` | admin | ดึงรายการ admin users |
| `POST` | `/api/users` | admin | สร้าง user ใหม่ |
| `PUT` | `/api/users/{id}` | admin | แก้ไข user |
| `POST` | `/api/users/{id}/reset-password` | admin | reset password |
| `DELETE` | `/api/users/{id}` | admin | ลบ user |

### System

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/system/status` | token | ดูสถานะระบบ |
| `POST` | `/api/system/start` | token | เปิดระบบ |
| `POST` | `/api/system/stop` | token | ปิดระบบ |
| `GET` | `/api/system/settings/public` | — | public settings (ใช้ใน login page) |
| `GET` | `/api/system/settings` | token | ดู system settings ทั้งหมด |
| `PUT` | `/api/system/settings` | admin | แก้ไข system settings |
| `GET` | `/api/system/maintenance` | — | ดู maintenance state (public) |
| `POST` | `/api/system/maintenance` | admin | เปิด/ปิด maintenance mode |
| `GET` | `/api/system/maintenance/reason` | — | ดึง maintenance reason (public) |

### Sync

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/sync/status` | token | ดู sync status + metrics |
| `POST` | `/api/sync/run` | token | trigger manual sync ทันที |

### Sessions

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/sessions` | token | ดู active sessions |
| `POST` | `/api/sessions` | token | สร้าง session |
| `DELETE` | `/api/sessions/all` | token | ลบ session ทั้งหมด |
| `DELETE` | `/api/sessions/{id}` | token | ลบ session เดียว |

### Activity & Logs

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/activities` | token | ดู activity log |
| `GET` | `/api/activities/{id}` | token | ดู activity detail |
| `DELETE` | `/api/activities/clear` | admin | clear activity log |
| `GET` | `/api/activities/retention` | token | ดู retention policy |
| `PUT` | `/api/activities/retention` | admin | แก้ไข retention policy |
| `GET` | `/api/logs` | token | ดู BA_TOOL backend logs |
| `DELETE` | `/api/logs` | token | clear logs |
| `GET` | `/api/logs/new` | token | ดึง logs ใหม่ (polling) |
| `GET` | `/api/admin-logs` | admin | ดู admin action logs |
| `DELETE` | `/api/admin-logs/clear` | admin | clear admin logs |
| `GET` | `/api/admin-logs/retention` | admin | ดู retention policy |
| `PUT` | `/api/admin-logs/retention` | admin | แก้ไข retention policy |
| `POST` | `/api/admin-logs/retention/run` | admin | run retention ทันที |

### Presence (WebSocket)

| Endpoint | Auth | คำอธิบาย |
|----------|------|----------|
| `ws://.../ws/presence` | — | user pages เชื่อมที่นี่ |
| `ws://.../ws/presence/admin?token=` | JWT | admin console ดู active users |
| `GET /api/presence` | token | ดึง active users snapshot |

### Health

| Method | Endpoint | Auth | คำอธิบาย |
|--------|----------|------|----------|
| `GET` | `/api/health` | — | ตรวจสอบสถานะ API |

---

## Maintenance Mode

เมื่อ admin เรียก `POST /api/system/maintenance` ด้วย `{ "enabled": true, "reason": "..." }`:
- ค่า `maintenance_mode` ถูกบันทึกลง `system_settings` ใน PostgreSQL
- BA_TOOL frontend จะ poll `/api/system/maintenance` แล้วแสดง overlay อัตโนมัติ

---

## Connecting from Frontend

```javascript
const BASE = "https://your-api.onrender.com";

// login
const { data } = await fetch(`${BASE}/api/auth/login`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "..." }),
}).then(r => r.json());

const token = data.access_token;

// authenticated request
const res = await fetch(`${BASE}/api/mappings`, {
  headers: { Authorization: `Bearer ${token}` },
}).then(r => r.json());
```

---

## Adding CORS Origins

ใน `app/core/config.py` เพิ่ม URL ของ frontend ใน `ALLOWED_ORIGINS`:

```python
ALLOWED_ORIGINS: List[str] = [
    "http://localhost:5500",
    "https://your-frontend.vercel.app",   # ← BA_TOOL frontend
    "https://your-admin-console.vercel.app",  # ← Admin Console
]
```

---

*MFEC Internship Project*
