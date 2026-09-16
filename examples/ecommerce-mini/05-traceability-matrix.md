# 05 — Traceability Matrix · Ma trận truy vết

## A. Forward — requirement → design

| ID | Statement (short) | Implemented by | Status |
|---|---|---|---|
| EN-001 | customer | table `customer` | covered |
| EN-002 | product | table `product` | covered |
| EN-003 | order | table `"order"` | covered |
| EN-004 | order_line | table `order_line` | covered |
| AT-001 | customer_code | `customer.customer_code` + `uq_customer_code` | covered |
| AT-003 | email | `customer.email` + `uq_customer_email` (per Q-02) | covered |
| AT-010 | product price | `product.unit_price numeric(19,4)` | covered |
| AT-021 | order total | `"order".total_amount` + `trg_order_line_total` | covered |
| AT-022 | delivery address | `"order".delivery_address` | covered |
| AT-031 | line price | `order_line.unit_price` | covered |
| RL-001 | customer places order | `fk_order_customer` | covered |
| RL-002 | order contains lines | `fk_order_line_order` (CASCADE) | covered |
| RL-003 | product in line | `fk_order_line_product` (RESTRICT) | covered |
| BR-001 | no cancel after paid | `trg_order_status_transition` | covered *(disputed — C-01)* |
| BR-002 | historical price | `order_line.unit_price`, never joined | covered |
| BR-003 | ≥1 line per order | application service layer | **covered outside the DB** |
| BR-004 | status flow | `order_status` enum + trigger | covered |
| BR-005 | total = sum of lines | `trg_order_line_total` | covered |
| VP-001 | 5,000 orders/day | sizing in `04-index-plan.md §Sizing` | covered |
| VP-010 | daily revenue report | `ix_order_paid_created_at` + stored total | covered |
| NF-001 | audit who and when | `created_at/by`, `updated_at/by` on all tables | covered |
| NF-002 | protect personal data | PII marked — **mechanism unspecified** | **PARTIAL** (M-02) |
| XX-001 | refund states may follow | enum left extensible; recorded | acknowledged |
| XX-002 | no price history | recorded as out of scope | acknowledged |

## B. Backward — design → requirement

| Object | Justified by | Status |
|---|---|---|
| `customer.*` | EN-001, AT-001..003, NF-001 | ok |
| `product.*` | EN-002, AT-010, AT-011 | ok |
| `"order".*` | EN-003, AT-020..022, BR-004, BR-005 | ok |
| `order_line.*` | EN-004, AT-030, AT-031, BR-002 | ok |
| `uq_customer_email` | Q-02 (**assumption, not a stated requirement**) | ⚠ assumption-backed |
| `ix_order_paid_created_at` | VP-010 | ok |
| `ix_order_customer_id` | RL-001 | ok |
| `ix_order_line_product_id` | RL-003 | ok |
| `trg_order_status_transition` | BR-001, BR-004 | ok |
| `trg_order_line_total` | BR-005, VP-010 | ok |

No unjustified objects. One object (`uq_customer_email`) rests on an assumption
rather than a stated requirement — flagged here so a reviewer can challenge it
instead of discovering it later.

## C. Coverage summary

| Section | Total | Covered | Partial | % |
|---|---|---|---|---|
| S2 entities | 4 | 4 | 0 | 100% |
| S3 attributes | 10 | 10 | 0 | 100% |
| S4 relationships | 3 | 3 | 0 | 100% |
| S5 rules | 5 | 5 | 0 | 100% |
| S7 volume/perf | 3 | 3 | 0 | 100% |
| S8 non-functional | 2 | 1 | 1 | 50% |
| S9 unclassified | 2 | — | 2 | acknowledged, not implemented |
