# 04 — Index & Performance Plan

Project: `ecommerce-mini` · DBMS: PostgreSQL 16

## Index justification

| # | Index | Table (cols) | Type | Serves | From | Write cost |
|---|---|---|---|---|---|---|
| 1 | `ix_order_customer_id` | order (customer_id) | btree | joins; RESTRICT check on customer delete | RL-001 | low |
| 2 | `ix_order_line_product_id` | order_line (product_id) | btree | RESTRICT check on product delete | RL-003 | low |
| 3 | `ix_order_paid_created_at` | order (created_at) WHERE status='paid' | **partial** | VP-010 daily revenue | VP-010 | low — only paid rows are indexed |

Three indexes for four tables. Nothing was added "to be safe": `order_line` is
the write-heaviest table (~15k rows/day) and carries only the one index its FK
needs, plus its PK.

## Hot query walkthrough

```sql
-- VP-010: daily revenue over a date range
SELECT date_trunc('day', created_at) AS day, SUM(total_amount)
FROM   app."order"
WHERE  status = 'paid' AND created_at >= $1 AND created_at < $2
GROUP  BY 1 ORDER BY 1;
-- Expected path: index scan on ix_order_paid_created_at.
-- total_amount is read straight from the row (D-01), so no join to order_line.
```

That second sentence is the whole reason `order.total_amount` is stored. Without
it this report joins and aggregates ~38M `order_line` rows.

## Sizing estimate

| Table | Rows/day | Row size | 7 years | Note |
|---|---|---|---|---|
| order | 5,000 | ~250 B | ~12.8M rows / ~3.2 GB | VP-001 |
| order_line | ~15,000 | ~60 B | ~38M rows / ~2.3 GB | VP-002, **confidence low** (A-01) |

## Partitioning

**Not proposed.** At ~12.8M rows over the full 7-year retention, `order` stays
well under the threshold where partitioning pays for itself, and the partial
index handles the only reported hot query.

Revisit if: volume estimates rise materially, or a requirement to purge data at
the 7-year boundary appears — partitioning by year would turn that purge into a
`DROP PARTITION` instead of a mass `DELETE`.

## Trade-offs

| # | Decision | Benefit | Cost |
|---|---|---|---|
| T-01 | Store `order.total_amount` | VP-010 needs no aggregation; §3.6 satisfied | Trigger on every line write; drift risk if disabled (see reconciliation query in migration notes) |
| T-02 | Partial rather than full index on `created_at` | Smaller index, cheaper writes | Useless for reports over non-paid statuses — none are currently requested |
