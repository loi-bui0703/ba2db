# 05 — Traceability Matrix · Ma trận truy vết

## A. Forward — requirement → design

| DR / ID | Section | Statement (short) | Implemented by | Status |
|---|---|---|---|---|
| EN-001 | S2 | customer | table `customer` | covered |
| BR-001 | S5 | | `ck_order_total_nonneg` | covered |
| VP-010 | S7 | | `ix_order_customer_id_created_at` | covered |
| NF-003 | S8 | | — | **NOT COVERED** |

## B. Backward — design → requirement

| Table.column / constraint | Justified by | Status |
|---|---|---|
| customer.customer_code | AT-002 | ok |
| customer.loyalty_tier | — | **UNJUSTIFIED** |

## C. Coverage summary

| Section | Total | Covered | Not covered | % |
|---|---|---|---|---|
| S2 entities | | | | |
| S3 attributes | | | | |
| S4 relationships | | | | |
| S5 rules | | | | |
| S7 volume/perf | | | | |
| S8 non-functional | | | | |
