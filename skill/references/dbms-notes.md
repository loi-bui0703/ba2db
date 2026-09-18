# DBMS Notes — khác biệt cần lưu ý khi sinh DDL

Dùng ở **Stage 4** để sinh DDL đúng phương ngữ của engine **đã được chọn ở
Stage 1B**. Bộ skill này không có engine mặc định — tiêu chí chọn nằm ở
`references/dbms-selection.md`.

## PostgreSQL
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

Khi người dùng chưa chốt DBMS: **đừng tự chọn một mặc định**. Chạy Stage 1B
(`skills/01b-dbms-selection/SKILL.md`), ra quyết định `provisional` kèm chủ sở
hữu, và ghi trạng thái đó vào header của `04-schema.sql`.

## Portability budget — cái giá thật của việc đổi nền tảng

"Chỉ khác cú pháp" là cách đánh giá thấp phổ biến nhất. Cái mất thật là **chỗ ép
ràng buộc**: một `BR-*` đang do database bảo đảm biến thành một `BR-*` do ứng
dụng "nhớ phải làm".

Stage 4 phải xuất một bảng như sau vào `04-migration-notes.md` — cụ thể cho
schema của mình, không phải bảng mẫu:

| Tính năng độc quyền đang dùng | `BR-*` phụ thuộc | Nếu đổi sang engine khác |
|---|---|---|
| `EXCLUDE USING gist` (chống chồng lấn khoảng) | BR-0xx | Không engine nào khác có → thành trigger + lock, hoặc mất chỗ ép |
| Partial / filtered unique index | BR-0xx | MySQL 8 không có → cột sinh + UNIQUE, hoặc app-enforced |
| Deferred constraint trigger (ràng buộc liên dòng) | BR-0xx | MySQL 8 không có → chỉ còn kiểm ở tầng ứng dụng |
| `jsonb` + GIN | VP-0xx | JSON của MySQL không index trực tiếp được như vậy |
| Partition khai báo + `DROP PARTITION` | VP-0xx | Có ở cả 4 engine nhưng cú pháp và giới hạn unique khác nhau |
| Enum kiểu dữ liệu | — | SQL Server/Oracle không có → `CHECK` + bảng danh mục |
| Row-level security | NF-0xx | MySQL không có → tách schema hoặc lọc ở tầng ứng dụng |

**Quy tắc đọc bảng này:** ≥3 `BR-*` phụ thuộc tính năng độc quyền ⇒ rủi ro của
assumption "engine đã chọn" là **High**, và phải ghi là High ở Stage 5, không
phải Medium.

## Một cảnh báo về partition ở mọi engine

Unique index trên bảng có partition **buộc phải chứa khoá phân mảnh**. Nghĩa là
mọi ràng buộc "duy nhất toàn cục" trên bảng đã partition sẽ **mất chỗ ép ở tầng
database**. Đây không phải chi tiết kỹ thuật nhỏ — nó là một quyết định lưu trữ
vật lý âm thầm gỡ bỏ một bảo đảm về tính đúng đắn, và **phải được ghi ra** ở
`04-index-plan.md` cùng với cách ép thay thế.
