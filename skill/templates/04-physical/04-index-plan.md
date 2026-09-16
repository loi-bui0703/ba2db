# 04 — Index & Performance Plan

Project: `<slug>` · DBMS: `<dbms>`

## 1. Index justification

| # | Index | Table (cols) | Type | Serves query | From (VP-*) | Write cost |
|---|---|---|---|---|---|---|
| 1 | `ix_order_customer_id_created_at` | order (customer_id, created_at DESC) | btree | "đơn hàng của một khách, mới nhất trước" | VP-010 | medium |

## 2. Hot query walkthrough

```sql
-- VP-010: list a customer's recent orders
SELECT ... FROM "order" WHERE customer_id = $1 ORDER BY created_at DESC LIMIT 20;
-- Expected access path: ix_order_customer_id_created_at (index scan, no sort)
```

## 3. Sizing estimate

| Table | Rows/day | Row size | 1 year | Retention | Total |
|---|---|---|---|---|---|

## 4. Partitioning

| Table | Strategy | Key | Interval | Purge method | Rationale |
|---|---|---|---|---|---|

Nếu không partition bảng nào: ghi rõ "Không cần partition ở quy mô hiện tại (VP-*)".

## 5. Trade-offs & risks

| # | Decision | Benefit | Cost |
|---|---|---|---|
