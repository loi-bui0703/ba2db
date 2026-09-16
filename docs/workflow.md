# The six-stage workflow

Each stage has one `SKILL.md`, one set of outputs, and a gate. The agent loads
only the stage it is working on.

---

## Stage 0 — Intake & scoping

**Reads:** whatever you hand it · **Writes:** `00-intake-report.md`, `STATE.md`

Inventories the documents *without reading them deeply* — id, type, coverage,
quality — then settles the things that change everything downstream: which
subsystems are in scope, target DBMS, workload shape, expected volume, and the
non-functional flags (multi-tenant? audit? PII? i18n?).

Questions you do not answer become assumptions **with the assumption written
down**, not silent defaults. That is the difference between a design you can
review and one you have to reverse-engineer.

---

## Stage 1 — Requirements extraction

**Writes:** `01-data-requirements.md`, `01-glossary.md`

The stage that determines the ceiling on everything else. Three passes:

1. **Sweep** — read everything with the checklist *closed*. Let the document
   speak before the template does.
2. **Classify** — assign each finding an ID and a section, cite `BA-xx §section`,
   then sweep again against the 12 signal groups to catch what pass 1 missed.
3. **Challenge** — re-read and ask what the document says about data that the
   nine sections still cannot hold. Anything found goes to `S9`.

Nine sections, each with a stable ID prefix:

| Section | Prefix | Consumed by |
|---|---|---|
| Business context | `BC-` | orientation |
| Candidate entities | `EN-` | Stage 2 |
| Attributes | `AT-` | Stage 3 |
| Relationships | `RL-` | Stage 2 |
| Business rules | `BR-` | Stage 3 |
| Process / lifecycle | `PR-` | Stage 5 |
| Volume & performance | `VP-` | Stage 4 |
| Non-functional | `NF-` | Stage 4 |
| **Unclassified / insight** | `XX-` | wherever it lands |

Also produced: `CONFLICTS` (contradictions between documents, both sides kept),
`OPEN QUESTIONS`, and `ASSUMPTIONS`.

---

## Stage 2 — Conceptual model

**Writes:** `02-conceptual-erd.md`

Decides what each candidate really is — independent entity, weak entity,
attribute of something else, reference data, or out of scope — and pins down
every relationship's cardinality *and* optionality, readable in both directions.

Ends with a check that every use case in `PR-*` can actually be walked through
the model. Ones that cannot go into `GAPS`.

This is the gate a business reader should review. An error caught here costs a
paragraph; the same error caught after Stage 4 costs a migration.

---

## Stage 3 — Logical design

**Writes:** `03-logical-schema.md`, `03-data-dictionary.md`

Maps entities to tables, chooses keys (surrogate PK **plus** a unique business
key), normalizes to 3NF/BCNF, assigns types, and turns every `BR-*` into a
`CHECK`, `UNIQUE`, FK, trigger — or an explicit note that it can only be
enforced in the application. That note is a feature: unenforced rules that
nobody wrote down are how data rots.

Denormalization requires four written answers: what is duplicated, which `VP-*`
justifies it, how it stays in sync, and what risk is accepted.

---

## Stage 4 — Physical design

**Writes:** `04-schema.sql`, `04-index-plan.md`, `04-migration-notes.md`

Runnable DDL in the target dialect, in FK dependency order, with named
constraints and column comments drawn from the data dictionary.

Every index must name the query it serves. Partitioning is proposed only when
`VP-*` shows the table will actually get large. If a local database is
available, the DDL is executed against a scratch database; if not, the agent is
required to **say it was not tested** rather than imply it was.

---

## Stage 5 — Review & handoff

**Writes:** `05-review-report.md`, `05-traceability-matrix.md`

Looks for errors in its own work:

- **Forward trace** — every `DR-*` to the object implementing it. Unmapped =
  missing design.
- **Backward trace** — every table and column to the requirement that demanded
  it. Unmapped = invented.
- **Checklist** — 8 groups, marked `PASS`/`FAIL`/`N-A`, no PASS for anything not
  actually checked.
- **Use case walkthrough** — real queries for the 5–8 most important use cases.
  Needing a six-table join for a common operation is a modeling smell.

Findings are ranked Blocker / Major / Minor. Remaining open questions are a
**legitimate deliverable**, not a failure — they are the questions your BA
still has to answer.

---

## Resuming

`STATE.md` records the last completed stage. Point the agent at an existing
workspace and it continues rather than starting over.
