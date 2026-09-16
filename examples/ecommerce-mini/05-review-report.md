# 05 — Design Review Report · Báo cáo nghiệm thu thiết kế

Project: `ecommerce-mini` · Date: 2026-09-16 · DBMS: PostgreSQL 16

## 1. Summary

| Metric | Value |
|---|---|
| Tables | 4 |
| Requirements extracted | 24 |
| Coverage (forward) | 23/24 — 96% |
| Unjustified objects | 0 |
| Open questions | 3 |
| Conflicts unresolved | 1 |
| Blockers | 0 |

**Key decisions:** `order_line.unit_price` as a business snapshot (BR-002);
`order.total_amount` stored and trigger-maintained (VP-010); no
`customer_address` entity, because no requirement asks for one (Q-01).

## 2. Checklist results

| Group | PASS | FAIL | N/A | Notes |
|---|---|---|---|---|
| 1. Completeness & traceability | 4 | 1 | 0 | Q-01 unresolved |
| 2. Model correctness | 5 | 0 | 0 | |
| 3. Integrity | 3 | 0 | 1 | BR-003 app-enforced, documented |
| 4. Normalization | 3 | 0 | 0 | Both exceptions documented |
| 5. Performance | 3 | 0 | 0 | Partitioning deferred with a trigger condition |
| 6. Security & compliance | 2 | 1 | 1 | PII marked; encryption approach not specified by BA |
| 7. Operations | 2 | 1 | 0 | **DDL not executed — see §6** |
| 8. Naming & documentation | 4 | 0 | 0 | |

## 3. Use case walkthrough

| PR | Use case | Tables joined | Verdict |
|---|---|---|---|
| Create order with lines | order, order_line, product | 3 | OK — trigger sets total |
| Confirm then pay an order | order | 1 | OK |
| Cancel a paid order | order | 1 | Correctly rejected by BR-001 |
| Daily revenue report | order | 1 | OK — index scan, no aggregation |
| Find a customer's orders | order, customer | 2 | OK |

No use case requires more than three tables.

## 4. Findings

### Major

| # | Finding | Impact | Proposed fix |
|---|---|---|---|
| M-01 | **C-01 is unresolved**: §3.4 and §6.4 contradict each other on whether a paid order can be cancelled. The trigger implements §3.4. | If the BA rules for §6.4, `trg_order_status_transition` must change and any orders rejected in the meantime were wrongly rejected. | BA decision required before go-live. Marked in the DDL itself. |
| M-02 | NF-002 requires protecting personal data, but BA-01 never says how — encryption at rest, column-level, or access control. | PII columns are marked but unprotected. | Ask the BA / security owner; default to column-level encryption for `email`. |

### Minor

| # | Finding | Impact | Proposed fix |
|---|---|---|---|
| m-01 | `order_status` may be incomplete (XX-001) — BA-04 refunds are out of scope but will likely add states. | A future enum migration. | None now; the enum is extensible and this is recorded. |
| m-02 | VP-002 rests on assumption A-01 (3 lines/order), which nothing in BA-01 supports. | Sizing estimate only; no design decision depends on it. | Confirm with the BA, or measure after launch. |
| m-03 | No price history exists (XX-002). | "What was this product's price last March" is unanswerable. | Out of scope today; raise if merchandising ever asks. |

## 5. Open questions for BA

| # | Question | Blocks | Current assumption |
|---|---|---|---|
| Q-01 | Can a customer have more than one delivery address? | A `customer_address` entity | Address stored on the order only |
| Q-02 | Is customer email unique? | `uq_customer_email` | Assumed unique — **constraint is already in the DDL**, so a "no" requires a migration |
| Q-03 | What happens to a paid order the customer wants to return? | Completeness of `order_status` | Out of scope per §3.4 |
| C-01 | §3.4 vs §6.4 — when can an order be cancelled? | BR-001 implementation | §3.4 implemented (more specific) |

## 6. Validation status

- [ ] DDL executed against a scratch database — **NOT DONE**

The local PostgreSQL instance required interactive authentication, so
`04-schema.sql` has **not** been run. It is syntactically reviewed only. Before
relying on it, run:

```bash
bash skill/scripts/validate-ddl.sh examples/ecommerce-mini/04-schema.sql postgres
```

This is recorded rather than glossed over because Stage 4 requires it: an
untested script must never be presented as a tested one.

## 7. Next steps

- [ ] BA answers Q-01, Q-02, Q-03 and rules on C-01
- [ ] Security owner specifies the NF-002 mechanism
- [ ] Run `validate-ddl.sh` in an environment with database access
- [ ] Add the nightly `total_amount` reconciliation query from the migration notes
