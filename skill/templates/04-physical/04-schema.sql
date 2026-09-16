-- =============================================================================
-- <PROJECT NAME> — Physical schema
-- DBMS      : PostgreSQL 16
-- Generated : <YYYY-MM-DD>  (stage 4, db-design-from-ba)
-- Source    : 03-logical-schema.md, 03-data-dictionary.md
-- NOTE      : identifiers are English snake_case; comments may be EN/VI.
-- =============================================================================

-- 1) Schema & extensions -------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS app;
SET search_path TO app, public;

-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE EXTENSION IF NOT EXISTS citext;

-- 2) Enums & reference types ---------------------------------------------------
DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('draft','confirmed','paid','shipped','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3) Tables (in FK dependency order) -------------------------------------------

CREATE TABLE IF NOT EXISTS customer (
    id            bigint GENERATED ALWAYS AS IDENTITY,
    customer_code varchar(20)  NOT NULL,
    full_name     varchar(255) NOT NULL,
    email         varchar(255),
    created_at    timestamptz  NOT NULL DEFAULT now(),
    created_by    bigint,
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    updated_by    bigint,
    CONSTRAINT pk_customer PRIMARY KEY (id),
    CONSTRAINT uq_customer_code UNIQUE (customer_code),
    CONSTRAINT ck_customer_email_format CHECK (email IS NULL OR email LIKE '%_@_%.__%')
);

COMMENT ON TABLE  customer               IS 'Khách hàng / Customer master (EN-001)';
COMMENT ON COLUMN customer.customer_code IS 'Mã khách hàng / business code (AT-002)';

-- 4) Additional constraints ----------------------------------------------------

-- 5) Indexes (justified in 04-index-plan.md) -----------------------------------
-- CREATE INDEX IF NOT EXISTS ix_order_customer_id_created_at
--     ON "order" (customer_id, created_at DESC);

-- 6) Views ---------------------------------------------------------------------

-- 7) Triggers & functions ------------------------------------------------------
-- CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
-- BEGIN NEW.updated_at := now(); RETURN NEW; END $$ LANGUAGE plpgsql;

-- 8) Seed / reference data -----------------------------------------------------

-- =============================================================================
-- END
-- =============================================================================
