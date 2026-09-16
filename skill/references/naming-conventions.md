# Naming Conventions & Standard Types

Áp dụng cho Stage 3–4. Code/tên luôn tiếng Anh.

## Đặt tên

| Đối tượng | Quy ước | Ví dụ |
|---|---|---|
| Bảng | `snake_case`, danh từ **số ít**, không viết tắt khó hiểu | `customer_address` |
| Bảng liên kết | `<a>_<b>` theo thứ tự chữ cái, hoặc tên nghiệp vụ nếu có | `order_promotion`, `enrollment` |
| Cột | `snake_case` | `created_at`, `total_amount` |
| Khóa ngoại | `<referenced_table>_id` | `customer_id` |
| Boolean | `is_` / `has_` | `is_active`, `has_invoice` |
| Thời điểm | `_at` (timestamp), `_date` (date) | `paid_at`, `due_date` |
| Tiền | `_amount` + cột `currency_code` | `total_amount` |
| PK constraint | `pk_<table>` | `pk_order` |
| FK constraint | `fk_<child>_<parent>` | `fk_order_customer` |
| Unique | `uq_<table>_<cols>` | `uq_order_code` |
| Check | `ck_<table>_<rule>` | `ck_order_total_nonneg` |
| Index | `ix_<table>_<cols>` | `ix_order_customer_id_created_at` |
| Enum type | `<domain>_status` | `order_status` |

Cấm: tên có dấu tiếng Việt, tên dùng từ khóa SQL (`order`, `user`, `group` →
`purchase_order`, `app_user`, `user_group`), viết tắt tùy hứng, `tbl_`/`col_` prefix.

## Kiểu dữ liệu chuẩn

| Loại dữ liệu | PostgreSQL | MySQL 8 | SQL Server |
|---|---|---|---|
| Surrogate PK | `bigint GENERATED ALWAYS AS IDENTITY` | `BIGINT AUTO_INCREMENT` | `BIGINT IDENTITY` |
| ID phân tán | `uuid` (v7 nếu được) | `BINARY(16)` | `UNIQUEIDENTIFIER` |
| Tiền | `numeric(19,4)` | `DECIMAL(19,4)` | `DECIMAL(19,4)` |
| Tỷ lệ % | `numeric(7,4)` | `DECIMAL(7,4)` | `DECIMAL(7,4)` |
| Mốc thời gian | `timestamptz` | `DATETIME(6)` (lưu UTC) | `DATETIMEOFFSET` |
| Ngày nghiệp vụ | `date` | `DATE` | `DATE` |
| Chuỗi ngắn có giới hạn | `varchar(n)` | `VARCHAR(n)` | `NVARCHAR(n)` |
| Chuỗi tự do | `text` | `TEXT` | `NVARCHAR(MAX)` |
| Boolean | `boolean` | `TINYINT(1)` | `BIT` |
| JSON | `jsonb` | `JSON` | `NVARCHAR(MAX)` + CHECK |
| Mã tiền tệ | `char(3)` (ISO 4217) | `CHAR(3)` | `CHAR(3)` |
| Quốc gia | `char(2)` (ISO 3166-1) | `CHAR(2)` | `CHAR(2)` |

**Không bao giờ** dùng `float/double` cho tiền hay số lượng cần chính xác.

## Cột chuẩn của mọi bảng nghiệp vụ

```sql
created_at  timestamptz NOT NULL DEFAULT now(),
created_by  bigint      NULL REFERENCES app_user(id),
updated_at  timestamptz NOT NULL DEFAULT now(),
updated_by  bigint      NULL REFERENCES app_user(id)
-- deleted_at timestamptz NULL   -- chỉ khi đã quyết định dùng soft delete
-- tenant_id  bigint NOT NULL    -- chỉ khi hệ thống multi-tenant
```
