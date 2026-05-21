-- ============================================================
-- Migration 002: Ensure sync target tables exist with
--                correct constraints for idempotent upsert
-- Safe to run multiple times (IF NOT EXISTS / idempotent)
-- ============================================================

-- 1. datatype_raw_mapping — ฝั่ง source
--    unique: (db_id, raw_type) เพื่อให้ ON CONFLICT DO UPDATE ทำงานได้
CREATE TABLE IF NOT EXISTS datatype_raw_mapping (
    id           SERIAL PRIMARY KEY,
    db_id        INTEGER      NOT NULL,
    source_type  VARCHAR(128) NOT NULL DEFAULT '',
    raw_type     VARCHAR(128) NOT NULL,
    logical_type VARCHAR(128) NOT NULL DEFAULT '',
    standard_id  INTEGER      REFERENCES datatype_standard(id) ON DELETE SET NULL,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_raw_mapping UNIQUE (db_id, raw_type)
);

CREATE INDEX IF NOT EXISTS ix_raw_mapping_db_id      ON datatype_raw_mapping (db_id);
CREATE INDEX IF NOT EXISTS ix_raw_mapping_standard_id ON datatype_raw_mapping (standard_id);

-- 2. datatype_mapping — ฝั่ง dest
--    unique: (db_id, standard_id) เพื่อให้ ON CONFLICT DO UPDATE ทำงานได้
CREATE TABLE IF NOT EXISTS datatype_mapping (
    id          SERIAL PRIMARY KEY,
    db_id       INTEGER      NOT NULL,
    standard_id INTEGER      NOT NULL REFERENCES datatype_standard(id) ON DELETE CASCADE,
    final_type  VARCHAR(128) NOT NULL DEFAULT '',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_datatype_mapping UNIQUE (db_id, standard_id)
);

CREATE INDEX IF NOT EXISTS ix_datatype_mapping_db_id ON datatype_mapping (db_id);

-- 3. trigger อัปเดต updated_at อัตโนมัติ (optional แต่ดีมากใน production)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_raw_mapping_updated_at ON datatype_raw_mapping;
CREATE TRIGGER trg_raw_mapping_updated_at
    BEFORE UPDATE ON datatype_raw_mapping
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_datatype_mapping_updated_at ON datatype_mapping;
CREATE TRIGGER trg_datatype_mapping_updated_at
    BEFORE UPDATE ON datatype_mapping
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
