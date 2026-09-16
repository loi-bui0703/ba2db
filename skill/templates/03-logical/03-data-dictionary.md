# 03 — Data Dictionary · Từ điển dữ liệu

Project: `<slug>` · Generated at stage 3, kept in sync through stage 4.

| # | Table | Column | Type | Null | Default | Key | Constraint | PII | Description (EN) | Mô tả (VI) | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | customer | id | bigint | NO | identity | PK | | no | Surrogate key | Khóa thay thế | — |
| 2 | customer | customer_code | varchar(20) | NO | | UQ | `^[A-Z]{2}\d{6}$` | no | Business code | Mã khách hàng | AT-002 |
| 3 | customer | email | varchar(255) | YES | | | format check | **yes** | Contact email | Email liên hệ | AT-003 |

## Enumerations

| Enum / reference table | Values | Meaning (EN / VI) | Source |
|---|---|---|---|
| order_status | draft, confirmed, paid, shipped, cancelled | | BR-004 |

## PII register

| Table.column | Category | Handling (encrypt / mask / restrict) | NF-* |
|---|---|---|---|
