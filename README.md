# Admin Console — BA_TOOL

หน้าจัดการระบบสำหรับ BA_TOOL ใช้ควบคุม mapping, users, maintenance mode และดู activity log

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla JS / HTML / CSS — deploy บน **Vercel** |
| Backend | Python 3.13 · **FastAPI** · SQLAlchemy (async) — deploy บน **Render** |
| Database | **PostgreSQL** (shared กับ BA_TOOL) |

---

## โครงสร้างโปรเจค

```
Admin_console_for_BATOOL/
├── Frontend/
│   ├── index.html
│   ├── app.js
│   └── styles.css
│
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py       # settings จาก environment variables
│   │   │   └── security.py     # JWT auth
│   │   ├── db/
│   │   │   ├── database.py     # SQLAlchemy async engine
│   │   │   └── models.py       # ORM models
│   │   ├── middleware/
│   │   │   ├── logging_middleware.py
│   │   │   ├── maintenance_middleware.py
│   │   │   └── rate_limit_middleware.py
│   │   ├── routers/            # API endpoints แยกตาม feature
│   │   ├── schemas/
│   │   ├── services/
│   │   └── sync_engine.py      # sync mapping กับ BA_TOOL DB
│   ├── migrations/             # SQL migration scripts
│   └── requirements.txt
│
├── render.yaml
└── runtime.txt
```

---

## การติดตั้ง (Local Development)

### 1. Clone และติดตั้ง dependencies

```bash
git clone <repo-url>
cd Admin_console_for_BATOOL/backend
pip install -r requirements.txt
```

### 2. ตั้งค่า Environment Variables

```bash
cp .env.example .env
```

ดูรายละเอียด key ที่ต้องตั้งค่าใน `.env.example`

### 3. รัน Backend

```bash
uvicorn app.main:app --reload --port 8000
```

### 4. เปิด Frontend

เปิด `Frontend/index.html` ผ่าน Live Server (VS Code) ที่ port 5500

---

## API Endpoints

### Auth

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `POST` | `/login` | เข้าสู่ระบบ รับ JWT token |
| `POST` | `/refresh` | refresh token |
| `GET` | `/me` | ดูข้อมูล user ปัจจุบัน |
| `POST` | `/logout` | ออกจากระบบ |

### Mappings

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `GET` | `/mappings` | ดึง mapping ทั้งหมด |
| `POST` | `/mappings` | เพิ่ม mapping ใหม่ |
| `PUT` | `/mappings/{id}` | แก้ไข mapping |
| `DELETE` | `/mappings/{id}` | ลบ mapping |
| `POST` | `/mappings/bulk-import` | import mapping จาก Excel |
| `GET` | `/datatype-standard/list` | ดึงรายการ standard type |

### Databases

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `GET` | `/databases` | ดึงรายการ database engine |
| `POST` | `/databases` | เพิ่ม database engine |
| `PUT` | `/databases/{id}` | แก้ไข database engine |
| `DELETE` | `/databases/{id}` | ลบ database engine |

### Users

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `GET` | `/users` | ดึงรายการ admin users |
| `POST` | `/users` | สร้าง user ใหม่ |
| `PUT` | `/users/{id}` | แก้ไข user |
| `POST` | `/users/{id}/reset-password` | reset password |
| `DELETE` | `/users/{id}` | ลบ user |

### System / Maintenance

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `GET` | `/status` | ดูสถานะระบบ |
| `POST` | `/start` | เปิดระบบ |
| `POST` | `/stop` | ปิดระบบ |
| `GET` | `/maintenance` | ดู maintenance state |
| `POST` | `/maintenance` | เปิด/ปิด maintenance mode |
| `GET` | `/settings` | ดู system settings |
| `PUT` | `/settings` | แก้ไข system settings |

### Sync

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `GET` | `/sync/status` | ดูสถานะ sync |
| `POST` | `/sync/run` | trigger sync mapping ไปยัง BA_TOOL DB |
### Presence

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `WS` | `/ws/presence` | รับการเชื่อมต่อสถานะผู้ใช้งานฝั่ง BA Tool |
| `WS` | `/ws/presence/admin` | ส่งข้อมูลสรุปผู้ใช้งานออนไลน์ทั้งหมดให้ Admin Console Dashboard (ต้องมี JWT) |
| `GET` | `/api/presence` | ดึงข้อมูล snapshot ผู้ใช้งานที่ออนไลน์อยู่ ณ ปัจจุบัน |

---

## Features & Integrations (ระบบที่เพิ่มเติมเข้ามา)

### 1. ระบบควบคุมประวัติผู้ใช้งานและความเคลื่อนไหว (Session Monitor & Presence Tracker)
- หน้าต่างตรวจสอบ **Online Users** ในรูปแบบ Real-time ผ่านการเชื่อมต่อ WebSocket
- แสดงรายละเอียดที่สำคัญ: Client ID (UUID), ชื่อผู้ใช้งาน (Username), หน้าเว็บที่กำลังทำงานอยู่ (Page), เวลาเริ่มเชื่อมต่อ และสถานะความเคลี่อนไหว (Idle state)
- ตัดสิทธิ์การแสดงตัวตนอัตโนมัติหากผู้ใช้งานปิดหน้าจอเว็บหรือขาดการเชื่อมต่อ (Evict stale session) เป็นเวลานานกว่า 90 วินาที

### 2. ระบบลงทะเบียนประวัติแปลงไฟล์และจัดเก็บ (Admin Logs Attribution)
- รับข้อมูลประวัติการทำงาน (Logs) ที่ส่งมาจากระบบแปลงไฟล์ (BA Tool) ผ่านการดึง log แบบสตรีม
- ระบบตรวจสอบข้อมูลว่ามี `username` ทำการส่งคำขอแปลงไฟล์หรือไม่ และแปลง JSON payload ไปเก็บลงฐานข้อมูล PostgreSQL ตาราง `batool_logs` ร่วมกับข้อมูลรายละเอียดการดำเนินการ (เช่น จำนวนไฟล์ที่ทำการแปลง, ชื่อเซสชันที่จัดการ เป็นต้น)
- แสดงชื่อผู้ใช้ผู้ส่งดำเนินการในคอลัมน์ "User" ของตารางล็อกฝั่งแอดมิน เพื่อความโปร่งใสและการเก็บประวัติการทำงานย้อนหลัง (Audit logs)

---

## Maintenance Mode

เมื่อ admin กด toggle maintenance ใน UI:
1. ระบบเขียน `maintenance_mode = true` ลง `system_settings` ใน PostgreSQL
2. BA_TOOL frontend จะ poll `/system/maintenance` และแสดง overlay อัตโนมัติ
3. เรียก `POST /system/maintenance/refresh` บน BA_TOOL backend เพื่อ clear cache ทันที

---

## Deployment → Render

1. Push code ขึ้น GitHub
2. สร้าง Web Service ใน Render เลือก repo นี้ rootDir: `backend`
3. ตั้งค่า environment variables ใน Render dashboard ตาม `render.yaml`

---

*MFEC Internship Project*
