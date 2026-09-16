-- =============================================================================
-- ecommerce-mini — Physical schema
-- DBMS      : PostgreSQL 16
-- Generated : 2026-09-16  (stage 4, ba2db)
-- Source    : 03-logical-schema.md, 03-data-dictionary.md
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS app;
SET search_path TO app, public;

-- 2) Enums ---------------------------------------------------------------------
-- Extensible on purpose: XX-001 flags that refund states may arrive with BA-04.
DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('draft','confirmed','paid','shipped','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3) Tables (FK dependency order) ----------------------------------------------

CREATE TABLE IF NOT EXISTS customer (
    id            bigint GENERATED ALWAYS AS IDENTITY,
    customer_code varchar(20)  NOT NULL,
    full_name     varchar(255) NOT NULL,
    email         varchar(255) NOT NULL,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    created_by    bigint,
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    updated_by    bigint,
    CONSTRAINT pk_customer        PRIMARY KEY (id),
    CONSTRAINT uq_customer_code   UNIQUE (customer_code),
    CONSTRAINT uq_customer_email  UNIQUE (email),          -- Q-02: assumed unique
    CONSTRAINT ck_customer_email  CHECK (email LIKE '%_@_%.__%')
);

COMMENT ON TABLE  customer       IS 'Khách hàng / Customer master (EN-001)';
COMMENT ON COLUMN customer.email IS 'PII (NF-002). Uniqueness assumed — see Q-02';

CREATE TABLE IF NOT EXISTS product (
    id           bigint GENERATED ALWAYS AS IDENTITY,
    product_code varchar(20)   NOT NULL,
    name         varchar(255)  NOT NULL,
    unit_price   numeric(19,4) NOT NULL,
    uom          varchar(10)   NOT NULL,
    created_at   timestamptz   NOT NULL DEFAULT now(),
    created_by   bigint,
    updated_at   timestamptz   NOT NULL DEFAULT now(),
    updated_by   bigint,
    CONSTRAINT pk_product          PRIMARY KEY (id),
    CONSTRAINT uq_product_code     UNIQUE (product_code),
    CONSTRAINT ck_product_price_nonneg CHECK (unit_price >= 0)
);

COMMENT ON COLUMN product.unit_price IS 'Giá hiện hành / current price (AT-010). Historical prices live on order_line (BR-002)';

CREATE TABLE IF NOT EXISTS "order" (
    id               bigint GENERATED ALWAYS AS IDENTITY,
    order_code       varchar(20)   NOT NULL,
    customer_id      bigint        NOT NULL,
    status           order_status  NOT NULL DEFAULT 'draft',
    total_amount     numeric(19,4) NOT NULL DEFAULT 0,
    delivery_address text          NOT NULL,
    created_at       timestamptz   NOT NULL DEFAULT now(),
    created_by       bigint,
    updated_at       timestamptz   NOT NULL DEFAULT now(),
    updated_by       bigint,
    CONSTRAINT pk_order              PRIMARY KEY (id),
    CONSTRAINT uq_order_code         UNIQUE (order_code),
    CONSTRAINT fk_order_customer     FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE RESTRICT,
    CONSTRAINT ck_order_total_nonneg CHECK (total_amount >= 0)
);

COMMENT ON COLUMN "order".total_amount     IS 'Maintained by trg_order_line_total (BR-005, D-01)';
COMMENT ON COLUMN "order".delivery_address IS 'Snapshot at order time (AT-022). See Q-01';

CREATE TABLE IF NOT EXISTS order_line (
    order_id   bigint        NOT NULL,
    line_no    smallint      NOT NULL,
    product_id bigint        NOT NULL,
    quantity   numeric(12,3) NOT NULL,
    unit_price numeric(19,4) NOT NULL,
    CONSTRAINT pk_order_line          PRIMARY KEY (order_id, line_no),
    CONSTRAINT fk_order_line_order    FOREIGN KEY (order_id)   REFERENCES "order"(id)  ON DELETE CASCADE,
    CONSTRAINT fk_order_line_product  FOREIGN KEY (product_id) REFERENCES product(id)  ON DELETE RESTRICT,
    CONSTRAINT ck_order_line_qty_pos  CHECK (quantity > 0),
    CONSTRAINT ck_order_line_price_nonneg CHECK (unit_price >= 0)
);

COMMENT ON COLUMN order_line.unit_price IS 'BR-002: price at order time. NEVER refresh from product.unit_price';

-- 5) Indexes -------------------------------------------------------------------

-- FK on the child side: needed for joins and for RESTRICT checks on delete.
CREATE INDEX IF NOT EXISTS ix_order_customer_id ON "order" (customer_id);
CREATE INDEX IF NOT EXISTS ix_order_line_product_id ON order_line (product_id);

-- VP-010: daily revenue. Partial, because paid orders are a minority of rows
-- and the report never looks at any other status.
CREATE INDEX IF NOT EXISTS ix_order_paid_created_at
    ON "order" (created_at) WHERE status = 'paid';

-- 7) Triggers ------------------------------------------------------------------

-- BR-001 + BR-004: legal status transitions.
CREATE OR REPLACE FUNCTION trg_order_status_transition() RETURNS trigger AS $$
BEGIN
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    -- BR-001: a paid order cannot be cancelled.
    -- NOTE: BA-01 §6.4 contradicts this (see CONFLICTS C-01). §3.4 is the more
    -- specific statement and is implemented here, pending a BA decision.
    IF OLD.status = 'paid' AND NEW.status = 'cancelled' THEN
        RAISE EXCEPTION 'A paid order cannot be cancelled (BR-001)';
    END IF;

    IF NOT (
        (OLD.status = 'draft'     AND NEW.status IN ('confirmed','cancelled')) OR
        (OLD.status = 'confirmed' AND NEW.status IN ('paid','cancelled'))      OR
        (OLD.status = 'paid'      AND NEW.status =  'shipped')
    ) THEN
        RAISE EXCEPTION 'Illegal status transition % -> % (BR-004)', OLD.status, NEW.status;
    END IF;

    RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_status_transition ON "order";
CREATE TRIGGER order_status_transition
    BEFORE UPDATE OF status ON "order"
    FOR EACH ROW EXECUTE FUNCTION trg_order_status_transition();

-- BR-005 / D-01: keep order.total_amount in step with its lines.
CREATE OR REPLACE FUNCTION trg_order_line_total() RETURNS trigger AS $$
DECLARE target_order bigint;
BEGIN
    target_order := COALESCE(NEW.order_id, OLD.order_id);
    UPDATE "order" o
       SET total_amount = COALESCE((
             SELECT SUM(l.quantity * l.unit_price) FROM order_line l WHERE l.order_id = target_order
           ), 0),
           updated_at = now()
     WHERE o.id = target_order;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_line_total ON order_line;
CREATE TRIGGER order_line_total
    AFTER INSERT OR UPDATE OR DELETE ON order_line
    FOR EACH ROW EXECUTE FUNCTION trg_order_line_total();

-- =============================================================================
-- NOT ENFORCED HERE (by design, see 03-logical-schema.md):
--   BR-003 "an order must contain at least one line" — a CHECK cannot span
--   child rows. Enforced in the application service layer.
-- =============================================================================
