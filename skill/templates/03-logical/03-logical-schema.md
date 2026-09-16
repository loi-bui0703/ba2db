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

```
D-01
What:
Why (VP-*):
Sync mechanism:
Risk accepted:
```

## 5. Derived columns

| Table.column | Formula | Strategy (computed / stored+trigger / view) | From |
|---|---|---|---|

## 6. Business rules mapping

| BR-* | Enforced by | Where |
|---|---|---|
| BR-001 | CHECK `ck_order_total_nonneg` | DB |
| BR-007 | application logic | service layer — **không ép được ở DB** |

## 7. Patterns applied

| Pattern | Tables affected | Why |
|---|---|---|
