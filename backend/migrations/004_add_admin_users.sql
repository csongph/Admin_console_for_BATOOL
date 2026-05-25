-- Migration: 004_add_admin_users.sql
-- สร้างตาราง admin_users สำหรับจัดการผู้ใช้งานระบบ Admin Console

CREATE TABLE IF NOT EXISTS admin_users (
    id           SERIAL          PRIMARY KEY,
    username     VARCHAR(128)    NOT NULL UNIQUE,
    hashed_pw    VARCHAR(256)    NOT NULL,
    role         VARCHAR(32)     NOT NULL DEFAULT 'viewer',  -- admin | editor | viewer
    display_name VARCHAR(128)    NOT NULL DEFAULT '',
    is_active    BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    last_login   TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS ix_admin_user_username ON admin_users (username);

COMMENT ON TABLE  admin_users            IS 'ผู้ใช้งาน Admin Console — จัดการโดย admin';
COMMENT ON COLUMN admin_users.role       IS 'admin | editor | viewer';
COMMENT ON COLUMN admin_users.hashed_pw IS 'bcrypt hashed password';

-- หมายเหตุ: superadmin จาก .env ยังใช้งานได้เสมอ (fallback)
-- ไม่จำเป็นต้อง insert admin ลงตารางนี้ แต่ insert ได้ถ้าต้องการ last_login tracking
