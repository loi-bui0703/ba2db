# 03 — Logical Schema · Lược đồ logic

Project: `<slug>` · Tables: `<n>` · Target DBMS: `<dbms>`

## 1. Table list

| # | Table | Purpose (EN) | Mục đích (VI) | Kind | Est. rows | From |
|---|---|---|---|---|---|---|
| 1 | customer | | | master | 100k | EN-001 |

Kind: `master` · `transaction` · `line` · `associative` · `reference` · `history` · `audit`

## 2. Table definitions

### `customer`

| Column | Type | Null | Default | Constraint | Description (EN) | Mô tả (VI) | From |
|---|---|---|---|---|---|---|---|
| id | bigint | NO | identity | PK | surrogate key | khóa thay thế | — |
| customer_code | varchar(20) | NO | | UQ | mã khách hàng | | AT-002 |

**Keys:** PK `pk_customer(id)` · UQ `uq_customer_code(customer_code)`
**FKs:** —
**Checks:** `ck_customer_email_format`
**Indexes:** xem `04-index-plan.md`

## 3. Relationship implementation

| Conceptual (R-*) | Implementation | ON DELETE | ON UPDATE |
|---|---|---|---|
| R-01 | `order.customer_id → customer.id` | RESTRICT | CASCADE |

## 4. Normalization notes

| Table | Normal form | Note |
|---|---|---|

### Denormalizations

ID dùng `DN-*` (`D-*` thuộc quyết định mô hình Stage 2 — không dùng lại).

```
DN-01
What:
Why (VP-*):
Sync mechanism:
Risk accepted:
```

## 5. Derived columns

| Table.column | Formula | Strategy (computed / stored+trigger / view) | From |
|---|---|---|---|

## 6. Business rules mapping

Cột `Where` ở stage này là **dự kiến** (`DB (planned)`), chưa phải sự thật: chỉ
Stage 4 chạy DDL thật mới biết database có ép được hay không. Stage 4 có nghĩa
vụ quay lại sửa cột này — xem `Verified by` và §8.

| BR-* | Enforced by | Where | Verified by Stage 4 |
|---|---|---|---|
| BR-001 | CHECK `ck_order_total_nonneg` | DB (planned) | ☐ |
| BR-007 | application logic | app — **không ép được ở DB** | n/a |

**Rules không ép được ở tầng database (tổng hợp):** `BR-xxx`, … → phải xuất hiện
đầy đủ trong `05-app-enforced-rules.md` ở Stage 5.

## 8. Amendments from later stages · Sửa từ stage sau

Stage 4/5 chứng minh một khẳng định ở trên là sai thì **sửa tại chỗ** và ghi một
dòng ở đây. Để trống nếu chưa có.

| Ngày | Mục bị sửa | Khẳng định cũ | Sự thật đã kiểm chứng | Nguồn |
|---|---|---|---|---|

## 7. Patterns applied

| Pattern | Tables affected | Why |
|---|---|---|
