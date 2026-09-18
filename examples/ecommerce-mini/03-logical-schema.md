# 03 — Logical Schema · Lược đồ logic

Project: `ecommerce-mini` · Tables: 4 · Target DBMS: PostgreSQL 16

## Table list

| # | Table | Purpose | Kind | Est. rows (7y) | From |
|---|---|---|---|---|---|
| 1 | customer | Customer master | master | ~500k | EN-001 |
| 2 | product | Product catalog | master | ~50k | EN-002 |
| 3 | order | Purchase orders | transaction | ~12.8M | EN-003 / VP-001 |
| 4 | order_line | Lines within an order | line | ~38M | EN-004 / VP-002 |

## Keys

| Table | PK | Business key (UNIQUE) | FKs |
|---|---|---|---|
| customer | `id` bigint identity | `customer_code`; `email` (per Q-02) | — |
| product | `id` bigint identity | `product_code` | — |
| order | `id` bigint identity | `order_code` | `customer_id` → customer (RESTRICT) |
| order_line | `(order_id, line_no)` composite | — | `order_id` → order (**CASCADE**), `product_id` → product (RESTRICT) |

`order_line` cascades because a line cannot exist without its order (D-03).
Everything else restricts: deleting a customer who has orders must fail loudly.

## Normalization notes

All four tables are in 3NF. Two deliberate exceptions, which are **not the same
kind of thing** — the distinction matters:

```
Business snapshot (not a denormalization)
What: order_line.unit_price duplicates product.unit_price at insert time
Why:  BR-002 — the historical price IS the business fact, not a cached copy
Sync: none, by design. It must never be refreshed from product.
Risk: none; refreshing it would be the bug
```

```
DN-01 — performance denormalization
What: order.total_amount duplicates SUM(order_line.quantity * unit_price)
Why:  VP-010 daily revenue report over ~12.8M orders; §3.6 also requires the
      total to be visible immediately while lines are being added
Sync: trigger on order_line INSERT/UPDATE/DELETE
Risk: totals drift if the trigger is ever disabled. Mitigation: a nightly
      reconciliation query, documented in 04-migration-notes.md
```

## Business rules mapping

| BR-* | Enforced by | Where |
|---|---|---|
| BR-001 | `trg_order_status_transition` | DB (trigger — needs the prior status) |
| BR-002 | column design: `order_line.unit_price` is written once, never joined | DB (by construction) |
| BR-003 | **application** — a CHECK cannot count rows in a child table | app service layer |
| BR-004 | `order_status` enum + `trg_order_status_transition` | DB |
| BR-005 | `trg_order_line_total` maintaining `order.total_amount` | DB |

BR-003 being app-enforced is written down rather than hidden. It is the one rule
the database cannot defend, so a reviewer needs to know it exists.

## Patterns applied

| Pattern | Tables | Why |
|---|---|---|
| Audit columns | all | NF-001 |
| Snapshot | order_line.unit_price, order.delivery_address | BR-002, AT-022 |
| Native enum | order.status | BR-004, fixed value set — but see XX-001 |
| PII register | customer.full_name, customer.email | NF-002 |

No soft delete: nothing in BA-01 asks for recoverable deletion, and adding it
would complicate every query for a requirement that does not exist.
