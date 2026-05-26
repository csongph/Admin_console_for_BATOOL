-- Migration: 005_add_maintenance_settings.sql
-- เพิ่ม default rows ใน system_settings สำหรับ maintenance mode
-- Safe to run multiple times (ON CONFLICT DO NOTHING)

-- ตรวจว่าตาราง system_settings มีอยู่แล้ว (SQLAlchemy init_db สร้างให้)
-- เพียงแค่ seed ค่าเริ่มต้นถ้ายังไม่มี

INSERT INTO system_settings (key, value)
VALUES
  ('maintenance_mode',   'false'),
  ('maintenance_reason', '')
ON CONFLICT (key) DO NOTHING;

COMMENT ON TABLE system_settings IS 'Key-value store สำหรับ system configuration';