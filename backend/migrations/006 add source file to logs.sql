-- Migration: 006_add_source_file_to_logs.sql
-- เพิ่มคอลัมน์ source_file เพื่อ track ว่า log มาจากไฟล์ใด
-- หมายเหตุ: ตาราง batool_logs / admin_console_logs ถูกสร้างโดย SQLAlchemy init_db()
--           รัน migration นี้หลังจาก backend startup ครั้งแรกแล้วเท่านั้น

-- สร้างตารางก่อนถ้ายังไม่มี (safety net กรณีรัน migration ก่อน startup)
CREATE TABLE IF NOT EXISTS batool_logs (
    id           SERIAL          PRIMARY KEY,
    level        VARCHAR(16)     NOT NULL DEFAULT 'INFO',
    message      TEXT            NOT NULL DEFAULT '',
    detail       TEXT,
    source_file  VARCHAR(128),
    external_key VARCHAR(256)    UNIQUE,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_console_logs (
    id           SERIAL          PRIMARY KEY,
    level        VARCHAR(16)     NOT NULL DEFAULT 'INFO',
    message      TEXT            NOT NULL DEFAULT '',
    detail       TEXT,
    source_file  VARCHAR(128),
    external_key VARCHAR(256)    UNIQUE,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- เพิ่มคอลัมน์ source_file ถ้ายังไม่มี (idempotent)
ALTER TABLE batool_logs
    ADD COLUMN IF NOT EXISTS source_file VARCHAR(128) DEFAULT NULL;

ALTER TABLE admin_console_logs
    ADD COLUMN IF NOT EXISTS source_file VARCHAR(128) DEFAULT NULL;

-- Index สำหรับ query ตาม level และ created_at
CREATE INDEX IF NOT EXISTS ix_batool_log_level       ON batool_logs (level);
CREATE INDEX IF NOT EXISTS ix_batool_log_created_at  ON batool_logs (created_at);
CREATE UNIQUE INDEX IF NOT EXISTS ix_batool_log_external_key ON batool_logs (external_key);

CREATE INDEX IF NOT EXISTS ix_admin_log_level        ON admin_console_logs (level);
CREATE INDEX IF NOT EXISTS ix_admin_log_created_at   ON admin_console_logs (created_at);
CREATE UNIQUE INDEX IF NOT EXISTS ix_admin_log_external_key ON admin_console_logs (external_key);

COMMENT ON COLUMN batool_logs.source_file        IS 'ชื่อไฟล์ที่ emit log เช่น api/main.py:329';
COMMENT ON COLUMN admin_console_logs.source_file IS 'ชื่อไฟล์ที่ emit log เช่น middleware/logging_middleware.py:45';