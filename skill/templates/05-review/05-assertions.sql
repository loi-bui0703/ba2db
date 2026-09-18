-- =====================================================================
-- 05-assertions.sql — chứng minh RÀNG BUỘC ép đúng, không chỉ chứng minh
-- DDL chạy được.
--
-- Chạy cùng schema:
--   bash scripts/validate-ddl.sh 04-schema.sql <engine> --assert 05-assertions.sql
--
-- Exit 3 = DDL chạy được nhưng có khẳng định thất bại.
--
-- QUY TẮC VÀNG — mỗi BR-* cần HAI khẳng định:
--   (1) một thao tác VI PHẠM  → phải bị TỪ CHỐI
--   (2) một thao tác HỢP LỆ NHƯNG GẦN GIỐNG → phải được CHẤP NHẬN
--
-- Vế (2) mới là vế bắt được lỗi thật. Một UNIQUE quá rộng vẫn từ chối đúng cái
-- sai — nó chỉ từ chối thêm cả những cái đúng. Chỉ thử vế (1) thì ràng buộc quá
-- rộng sẽ "đạt" mọi lần.
-- =====================================================================

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- Helper: khẳng định một câu lệnh PHẢI thất bại.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION assert_rejects(p_rule text, p_sql text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'PASS  % — rejected as required (%)', p_rule, SQLERRM;
    RETURN;
  END;
  RAISE EXCEPTION 'ASSERTION FAILED: % — the violating statement was ACCEPTED', p_rule;
END $$;

-- ---------------------------------------------------------------------
-- Helper: khẳng định một câu lệnh PHẢI thành công (vế gần giống).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION assert_accepts(p_rule text, p_sql text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RAISE NOTICE 'PASS  % — legitimate neighbouring case accepted', p_rule;
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'ASSERTION FAILED: % — a LEGITIMATE statement was rejected: %',
    p_rule, SQLERRM;
END $$;

-- ---------------------------------------------------------------------
-- 1. Fixture — dữ liệu tối thiểu để thử
-- ---------------------------------------------------------------------
BEGIN;
-- INSERT INTO ... (dữ liệu gốc dùng cho các khẳng định bên dưới)
COMMIT;

-- ---------------------------------------------------------------------
-- 2. Assertions — một block cho mỗi BR-* ghi là "DB-enforced"
-- ---------------------------------------------------------------------

-- BR-0xx <tên quy tắc>
-- SELECT assert_rejects('BR-0xx', $sql$
--   INSERT INTO ... ;            -- vi phạm rule
-- $sql$);
-- SELECT assert_accepts('BR-0xx', $sql$
--   INSERT INTO ... ;            -- hợp lệ nhưng GẦN GIỐNG cái trên
-- $sql$);

-- Ràng buộc liên dòng (deferred): phải thử TRONG một transaction, vì nó chỉ nổ
-- lúc COMMIT — một CHECK theo dòng sẽ cho qua.
-- DO $$ BEGIN
--   BEGIN
--     -- nhiều INSERT/UPDATE cùng nhau làm tổng sai
--     RAISE EXCEPTION 'unreachable';
--   EXCEPTION WHEN others THEN NULL; END;
-- END $$;

-- ---------------------------------------------------------------------
-- 3. Rule chưa thử được — ghi ra, đừng bỏ im lặng
-- ---------------------------------------------------------------------
-- BR-0xx: app-enforced (xem 05-app-enforced-rules.md) — không thử ở đây.

DO $$ BEGIN
  RAISE NOTICE '--- all assertions passed ---';
END $$;
