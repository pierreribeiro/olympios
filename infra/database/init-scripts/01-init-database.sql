-- =============================================================================
--  01-init-database.sql — Perseus PG18 initial database setup
-- =============================================================================
--  Reused from the original Docker-based setup. Changes from the heritage:
--    - ✨ pgtap extension added (Critério #2e)
--    - perseus_admin → perseus_owner (v1.1 naming alignment)
--  Runs against perseus_dev as perseus_owner.
--  Idempotent (CREATE IF NOT EXISTS, CREATE OR REPLACE).
-- =============================================================================

\set ON_ERROR_STOP on

-- =============================================================================
-- 1. Enable Required Extensions
-- =============================================================================
-- Note: extensions are owned by perseus_owner (the role running this script);
-- pg_stat_statements is preloaded via shared_preload_libraries in postgresql.conf.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp"          SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "btree_gist"         SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pg_trgm"            SCHEMA public;
CREATE EXTENSION IF NOT EXISTS  citext              SCHEMA public;

-- ✨ pgTAP for unit testing (TDD per Perseus standards)
CREATE EXTENSION IF NOT EXISTS  pgtap               SCHEMA public;

-- =============================================================================
-- 2. Create Schemas (owned by perseus_owner, the script's session user)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS perseus      AUTHORIZATION perseus_owner;
CREATE SCHEMA IF NOT EXISTS perseus_test AUTHORIZATION perseus_owner;
CREATE SCHEMA IF NOT EXISTS fixtures     AUTHORIZATION perseus_owner;

-- =============================================================================
-- 3. Set Search Path
-- =============================================================================

ALTER ROLE perseus_owner SET search_path TO perseus, public;

-- =============================================================================
-- 4. Grant Permissions
-- =============================================================================

GRANT USAGE ON SCHEMA perseus      TO PUBLIC;
GRANT USAGE ON SCHEMA perseus_test TO PUBLIC;
GRANT USAGE ON SCHEMA fixtures     TO PUBLIC;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO perseus_owner;

-- =============================================================================
-- 5. Configure Database Settings
-- =============================================================================

-- (Timezone is set globally via postgresql.conf — applied per-DB anyway for safety)
ALTER DATABASE perseus_dev SET timezone TO 'America/Sao_Paulo';
ALTER DATABASE perseus_dev SET log_statement TO 'ddl';
ALTER DATABASE perseus_dev SET max_parallel_workers_per_gather TO 4;

-- =============================================================================
-- 6. Create Audit Tables
-- =============================================================================

CREATE TABLE IF NOT EXISTS perseus.migration_log (
    id                   SERIAL PRIMARY KEY,
    migration_phase      VARCHAR(100) NOT NULL,
    object_type          VARCHAR(50)  NOT NULL,
    object_name          VARCHAR(255) NOT NULL,
    status               VARCHAR(20)  NOT NULL CHECK (status IN ('started','completed','failed','rolled_back')),
    quality_score        NUMERIC(4,2),
    performance_delta    NUMERIC(6,2),
    error_message        TEXT,
    executed_by          VARCHAR(100) DEFAULT CURRENT_USER,
    executed_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_duration_ms INTEGER
);

CREATE INDEX IF NOT EXISTS idx_migration_log_object      ON perseus.migration_log(object_type, object_name);
CREATE INDEX IF NOT EXISTS idx_migration_log_status      ON perseus.migration_log(status);
CREATE INDEX IF NOT EXISTS idx_migration_log_executed_at ON perseus.migration_log(executed_at DESC);

-- =============================================================================
-- 7. Create Helper Functions
-- =============================================================================

CREATE OR REPLACE FUNCTION perseus.object_exists(
    p_schema_name TEXT,
    p_object_name TEXT,
    p_object_type TEXT DEFAULT 'table'
) RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    CASE LOWER(p_object_type)
        WHEN 'table' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_schema = p_schema_name AND table_name = p_object_name
            ) INTO v_exists;
        WHEN 'view' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.views
                WHERE table_schema = p_schema_name AND table_name = p_object_name
            ) INTO v_exists;
        WHEN 'function' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.routines
                WHERE routine_schema = p_schema_name AND routine_name = p_object_name AND routine_type = 'FUNCTION'
            ) INTO v_exists;
        WHEN 'procedure' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.routines
                WHERE routine_schema = p_schema_name AND routine_name = p_object_name AND routine_type = 'PROCEDURE'
            ) INTO v_exists;
        ELSE
            RAISE EXCEPTION 'Unsupported object type: %', p_object_type;
    END CASE;
    RETURN v_exists;
END;
$$;

-- =============================================================================
-- 8. Verify Setup
-- =============================================================================

DO $$
DECLARE
    v_version  TEXT;
    v_encoding TEXT;
    v_user     TEXT;
    v_ext      TEXT;
BEGIN
    SELECT version() INTO v_version;
    SELECT current_user INTO v_user;
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'PostgreSQL Version: %', v_version;
    RAISE NOTICE 'Running as user:    %', v_user;

    SELECT pg_encoding_to_char(encoding) INTO v_encoding
    FROM pg_database WHERE datname = current_database();
    RAISE NOTICE 'Database Encoding:  %', v_encoding;

    IF v_encoding != 'UTF8' THEN
        RAISE WARNING 'Database encoding is not UTF-8 (got %)', v_encoding;
    ELSE
        RAISE NOTICE 'UTF-8 encoding verified ✓';
    END IF;

    RAISE NOTICE 'Installed extensions:';
    FOR v_ext IN
        SELECT extname || ' ' || extversion FROM pg_extension ORDER BY extname
    LOOP
        RAISE NOTICE '  - %', v_ext;
    END LOOP;

    RAISE NOTICE 'Perseus PG18 development environment ready ✓';
    RAISE NOTICE '=================================================================';
END;
$$;
