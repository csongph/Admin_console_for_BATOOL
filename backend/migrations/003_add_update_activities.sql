-- Migration: 003_add_update_activities.sql
-- สร้างตาราง update_activities สำหรับบันทึกการเปลี่ยนแปลงข้อมูลโดยผู้ใช้

CREATE TABLE IF NOT EXISTS update_activities (
    id          SERIAL          PRIMARY KEY,
    username    VARCHAR(128)    NOT NULL,
    action      VARCHAR(32)     NOT NULL,           -- create | update | delete | bulk_import
    target_type VARCHAR(64)     NOT NULL DEFAULT 'mapping',
    target_id   VARCHAR(64),
    summary     VARCHAR(256)    NOT NULL DEFAULT '',
    detail      TEXT,                               -- JSON snapshot (before/after)
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_activity_user       ON update_activities (username);
CREATE INDEX IF NOT EXISTS ix_activity_action     ON update_activities (action);
CREATE INDEX IF NOT EXISTS ix_activity_created_at ON update_activities (created_at DESC);

COMMENT ON TABLE  update_activities               IS 'บันทึกทุกการเปลี่ยนแปลงข้อมูลของผู้ใช้งาน';
COMMENT ON COLUMN update_activities.action        IS 'create | update | delete | bulk_import';
COMMENT ON COLUMN update_activities.detail        IS 'JSON {before, after, changes} snapshot';
