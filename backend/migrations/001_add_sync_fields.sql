-- ============================================================
-- Migration 001: Add sync/audit fields to mapping_rules
-- Safe to run multiple times (IF NOT EXISTS / idempotent)
-- ============================================================

-- 1. error_message — เก็บ error code จาก sync engine
ALTER TABLE mapping_rules
  ADD COLUMN IF NOT EXISTS error_message VARCHAR(256) DEFAULT NULL;

-- 2. synced_at — timestamp ที่ sync สำเร็จ
ALTER TABLE mapping_rules
  ADD COLUMN IF NOT EXISTS synced_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 3. retry_count — นับจำนวนครั้งที่ retry
ALTER TABLE mapping_rules
  ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0;

-- 4. source_type — เพิ่มถ้ายังไม่มี (migrate_mappings.py เพิ่มไว้แล้ว)
ALTER TABLE mapping_rules
  ADD COLUMN IF NOT EXISTS source_type VARCHAR(128) DEFAULT '';

-- 5. Unique index ป้องกัน duplicate (ถ้ายังไม่มี)
CREATE UNIQUE INDEX IF NOT EXISTS uq_mapping_rule
  ON mapping_rules (src_db, raw_type, dest_db);

-- 6. Index เพื่อ sync engine query เร็ว
CREATE INDEX IF NOT EXISTS ix_mapping_status
  ON mapping_rules (status);

CREATE INDEX IF NOT EXISTS ix_mapping_synced_at
  ON mapping_rules (synced_at)
  WHERE synced_at IS NOT NULL;

-- 7. Unique index บน database_records.key (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS uq_db_record_key_lower
  ON database_records (LOWER(key));

-- 8. datatype_standard table — สร้างถ้ายังไม่มี
CREATE TABLE IF NOT EXISTS datatype_standard (
  id            SERIAL PRIMARY KEY,
  standard_type VARCHAR(64) NOT NULL UNIQUE,
  description   VARCHAR(256) DEFAULT ''
);

-- seed ค่าเริ่มต้น (idempotent)
INSERT INTO datatype_standard (standard_type, description) VALUES
  ('INTEGER',          'Whole number 32-bit'),
  ('BIGINT',           'Whole number 64-bit'),
  ('DECIMAL',          'Fixed-point decimal'),
  ('FLOAT',            'Single precision float'),
  ('DOUBLE PRECISION', 'Double precision float'),
  ('BOOLEAN',          'True/false'),
  ('CHAR',             'Fixed-length string'),
  ('VARCHAR',          'Variable-length string'),
  ('TEXT',             'Unlimited text'),
  ('DATE',             'Calendar date'),
  ('TIME',             'Time of day'),
  ('TIMESTAMP',        'Date and time'),
  ('BINARY',           'Raw binary data'),
  ('UUID',             'Universally unique identifier'),
  ('JSON',             'JSON document'),
  ('XML',              'XML document'),
  ('TINYINT',          'Tiny integer'),
  ('SMALLINT',         'Small integer'),
  ('NVARCHAR',         'Unicode variable string'),
  ('NCHAR',            'Unicode fixed string'),
  ('NTEXT',            'Unicode text'),
  ('DATETIME',         'Legacy datetime'),
  ('DATETIME2',        'High precision datetime'),
  ('SMALLDATETIME',    'Small datetime'),
  ('DATETIMEOFFSET',   'Datetime with timezone'),
  ('GEOMETRY',         'Spatial geometry'),
  ('INTERVAL',         'Time interval'),
  ('NETWORK',          'Network address type'),
  ('ENUM',             'Enumeration type')
ON CONFLICT (standard_type) DO NOTHING;
