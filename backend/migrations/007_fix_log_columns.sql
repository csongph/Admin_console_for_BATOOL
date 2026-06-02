-- Migration: 007_fix_log_columns.sql
-- Ensure existing log tables match the SQLAlchemy models.

ALTER TABLE batool_logs
    ADD COLUMN IF NOT EXISTS source_file VARCHAR(128) DEFAULT NULL;

ALTER TABLE batool_logs
    ADD COLUMN IF NOT EXISTS username VARCHAR(128) DEFAULT NULL;

ALTER TABLE batool_logs
    ADD COLUMN IF NOT EXISTS external_key VARCHAR(256) DEFAULT NULL;

ALTER TABLE admin_console_logs
    ADD COLUMN IF NOT EXISTS source_file VARCHAR(128) DEFAULT NULL;

ALTER TABLE admin_console_logs
    ADD COLUMN IF NOT EXISTS username VARCHAR(128) DEFAULT NULL;

ALTER TABLE admin_console_logs
    ADD COLUMN IF NOT EXISTS external_key VARCHAR(256) DEFAULT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ix_batool_log_external_key
    ON batool_logs (external_key)
    WHERE external_key IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ix_admin_log_external_key
    ON admin_console_logs (external_key)
    WHERE external_key IS NOT NULL;
