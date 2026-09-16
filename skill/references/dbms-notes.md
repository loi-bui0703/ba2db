# DBMS Notes — khác biệt cần lưu ý khi sinh DDL

## PostgreSQL (mặc định của bộ skill này)
- PK: `bigint GENERATED ALWAYS AS IDENTITY`; UUID dùng `uuid` (v7 nếu có extension).
- `timestamptz` cho mốc thời gian; `jsonb` cho JSON; `text` không tốn hơn `varchar`.
- Enum: `CREATE TYPE ... AS ENUM` (khó bỏ giá trị) hoặc bảng danh mục (linh hoạt hơn).
- Partial index, `INCLUDE`, expression index, RLS (`ROW LEVEL SECURITY`) — dùng được.
- `COMMENT ON TABLE/COLUMN` để đưa data dictionary vào DB.
- Extension hay cần: `pg_trgm`, `citext`, `uuid-ossp`/`pgcrypto`, `btree_gist`.

## MySQL 8
- `BIGINT AUTO_INCREMENT`; UUID nên lưu `BINARY(16)` đã sắp xếp.
- **Không có** partial index, không có `INCLUDE`; CHECK có hiệu lực từ 8.0.16.
- `DATETIME(6)` lưu UTC + xử lý timezone ở tầng ứng dụng (`TIMESTAMP` giới hạn 2038).
- InnoDB: PK là clustered index → PK ngắn, tăng dần; UUID ngẫu nhiên làm phân mảnh.
- Charset `utf8mb4` + collation `utf8mb4_0900_ai_ci` (hoặc `_bin` khi cần phân biệt hoa thường).

## SQL Server
- `BIGINT IDENTITY(1,1)`; `NEWSEQUENTIALID()` nếu buộc dùng GUID làm clustered PK.
- `NVARCHAR` cho tiếng Việt; `DATETIMEOFFSET` cho mốc thời gian có timezone.
- Filtered index (`WHERE`) ≈ partial index; `INCLUDE` có sẵn.
- Phân biệt clustered vs nonclustered index — chọn clustered theo cách đọc chính.

## Oracle
- `GENERATED ALWAYS AS IDENTITY` (12c+); trước đó dùng sequence + trigger.
- `VARCHAR2`, `NUMBER(19,4)`, `TIMESTAMP WITH TIME ZONE`.
- Chuỗi rỗng `''` bị coi là NULL — ảnh hưởng ràng buộc `NOT NULL`.
- Tên định danh ≤128 ký tự (12.2+), trước đó 30 — kiểm tra tên constraint dài.

## Chung
Khi người dùng chưa chọn DBMS: mặc định PostgreSQL 16, **nói rõ** là mặc định
và DDL sẽ cần điều chỉnh nếu đổi nền tảng.
