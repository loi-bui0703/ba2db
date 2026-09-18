# Example — `ecommerce-mini`

A complete run of the seven-stage workflow on a small BA document, showing what
each artifact looks like **when it is done properly**.

This is a reference for quality, not a schema to copy.

## What to look at

| File | What it demonstrates |
|---|---|
| [`ba-docs/BA-01-sales.md`](./ba-docs/BA-01-sales.md) | The input — deliberately imperfect, like real BA documents |
| [`01-data-requirements.md`](./01-data-requirements.md) | Citations, confidence levels, an `S9` finding, conflicts, open questions |
| [`01b-dbms-decision.md`](./01b-dbms-decision.md) | An engine chosen by reasoning, not by default — including a comparison that comes out **even**, and a decision left `provisional` because the deciding constraint was never answered |
| [`02-conceptual-erd.md`](./02-conceptual-erd.md) | Cardinality read in both directions; a candidate rejected with a reason |
| [`03-logical-schema.md`](./03-logical-schema.md) | A business snapshot distinguished from a performance denormalization |
| [`04-schema.sql`](./04-schema.sql) | Runnable DDL, named constraints, comments carrying the requirement IDs |
| [`05-review-report.md`](./05-review-report.md) | Findings against its *own* design, and open questions left visibly open |
| [`05-app-enforced-rules.md`](./05-app-enforced-rules.md) | The one rule the database cannot stop — why, where it is enforced instead, and the test that is still missing |

## The lesson this example teaches

The input document never says whether a customer can have more than one delivery
address. A careless run invents a `customer_address` table and moves on. This
run:

- records the gap as `Q-01` in Stage 1,
- states the assumption it proceeded under,
- carries it into `02-conceptual-erd.md` as a `GAP`,
- and reports it in Stage 5 as an **unresolved open question**, not as done.

The design is still delivered. The uncertainty is still visible. That is the
whole point of the workflow.
