# The seven-stage workflow

Each stage has one `SKILL.md`, one set of outputs, and a gate. The agent loads
only the stage it is working on.

| # | Stage | Decides |
|---|---|---|
| 0 | Intake & scoping | what is in the box, what is in scope |
| 1 | Requirements extraction | what the documents actually say about data |
| **1B** | **DBMS decision** | **which engine, and what that costs** |
| 2 | Conceptual model | what the things are |
| 3 | Logical design | what the tables are |
| 4 | Physical design | what runs, and what the engine will not enforce |
| 5 | Review & handoff | what is wrong with all of the above |

---

## Stage 0 — Intake & scoping

**Reads:** whatever you hand it · **Writes:** `00-intake-report.md`, `STATE.md`

Inventories the documents *without reading them deeply* — id, type, coverage,
quality — then settles the things that change everything downstream: which
subsystems are in scope, workload shape, expected volume, and the non-functional
flags (multi-tenant? audit? PII? i18n?).

It also collects **platform constraints** — what ops already runs, cloud,
licence, ORM — but deliberately does **not** pick a DBMS. That is Stage 1B's job,
and at Stage 0 there is nothing yet to reason from.

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

## Stage 1B — DBMS decision

**Writes:** `01b-dbms-decision.md`

**There is no default engine.** A default is a conclusion without premises:
nobody can review it, and nobody knows when to revisit it. This stage earns the
choice instead, and it sits here for a reason — at Stage 0 there was no volume
and no rule to reason from; by Stage 4 an unchosen engine has already shaped the
whole logical model.

1. **Drivers from requirements** — every driver must point at a real `VP-*`,
   `BR-*` or `NF-*` id. A driver with no id is a preference, and preferences go
   in the constraints section where a reviewer can strike them.
2. **Context constraints, kept separate** — what ops already runs, licence cost,
   cloud, ORM. These are legitimate and often decisive, but they are recorded as
   constraints, never disguised as technical reasoning.
3. **Eliminate on must-haves** — a candidate missing one is out, not
   marked down.
4. **Count the rules each candidate cannot enforce** — the single most useful
   number this stage produces. It turns "a different dialect" into "this many
   guarantees moved from the database into application code you have to
   remember to write."
5. **Portability budget** — which engine-exclusive features the design will lean
   on, and which `BR-*` depend on each. Three or more, and the risk of being
   wrong about the engine is High, not Medium.

Deliberately **not** a weighted score: a total manufactured from
self-invented weights looks objective and is not.

If nobody can decide, the decision is recorded as `provisional` with an owner —
and Stage 4 says so in the DDL header rather than letting a reader assume it was
settled.

---

## Stage 2 — Conceptual model

**Writes:** `02-conceptual-erd.md`

Decides what each candidate really is — independent entity, weak entity,
attribute of something else, reference data, or out of scope — and pins down
every relationship's cardinality *and* optionality, readable in both directions.

Then one question that pays for itself: **what does this system actually have to
prove?** Copying the unit price *as it was at the time of the transaction*,
recording the URL *actually called*, pinning *the exact content version used* —
these look like three unrelated decisions and are one move repeated. Naming the
principle here is worth more than rediscovering it three times in Stage 3, and it
makes the fourth omission visible.

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
justifies it, how it stays in sync, and what risk is accepted. Its ids are
`DN-*`; `D-*` already belongs to Stage 2's modelling decisions, and one id with
two meanings makes every cross-reference — including DDL comments — ambiguous.

Two claims this stage is **not** allowed to make as facts:

- **"Enforced in the database"** is written `DB (planned)` and left unticked.
  Only Stage 4, running the DDL, finds out whether the engine can enforce it.
- **A lifecycle encoded twice** — a status column plus a row of nullable
  per-milestone timestamps — needs a `CHECK` tying them together. Without one,
  `status = 'DELIVERED'` with `sent_at IS NULL` is a valid row, and every job
  reading that timestamp is quietly wrong.

---

## Stage 4 — Physical design

**Writes:** `04-schema.sql`, `04-index-plan.md`, `04-migration-notes.md`

Runnable DDL in the target dialect, in FK dependency order, with named
constraints and column comments drawn from the data dictionary.

Every index must name the query it serves. Partitioning is proposed only when
`VP-*` shows the table will actually get large — and its three costs are written
down, not left to be discovered: global uniqueness stops being enforceable,
extra columns get denormalized to keep pruning, and a predicate written in the
wrong timezone silently scans two partitions.

The DDL is executed against a scratch database (docker preferred, for the right
version); if there is no environment, the agent is required to **say it was not
tested** rather than imply it was. Running is only half of it: `--assert` runs
`05-assertions.sql`, which proves each rule both **rejects the violation** and
**accepts the legitimate near-miss** — the second half is what catches a
constraint that is too broad.

Also produced here, because the design is incorrect without them: the **register
of operational jobs** the schema depends on, each with what breaks if it does not
run, whether that is recoverable, and how anyone would notice.

**Then Stage 4 goes back and fixes Stage 3.** It is the first stage to meet a
real engine, so it routinely disproves an earlier claim. Every `DB (planned)`
becomes `DB` or `app`, new denormalizations are added to Stage 3 rather than
living in a SQL comment, a drifted ERD is regenerated, and each correction is
logged under `## Amendments`. Two artifacts saying different things is how a
false claim gets handed to whoever reads this next.

---

## Stage 5 — Review & handoff

**Writes:** `05-review-report.md`, `05-traceability-matrix.md`

Looks for errors in its own work — and starts by **not trusting its own
arithmetic**. `check-design.sh` counts the artifacts mechanically, because two
failure modes get past self-review systematically: a self-reported total that
does not match the content, and two stages contradicting each other about the
same rule.

- **Machine pass first** — `check-design.sh` (id namespaces, undefined ids,
  self-reported vs counted totals, Stage 3/4 drift, double-encoded lifecycles,
  per-table constraint density) and `validate-ddl.sh --report` (density and
  foreign keys with no index on the child side).
- **Forward trace** — every `DR-*` to the object implementing it. Unmapped =
  missing design.
- **Backward trace** — every table and column to the requirement that demanded
  it. Unmapped = invented.
- **Checklist** — 9 groups, marked `PASS`/`FAIL`/`N-A`, no PASS for anything not
  actually checked.
- **Use case walkthrough** — real queries for the 5–8 most important use cases.
  Needing a six-table join for a common operation is a modeling smell.
- **Adversarial pass (group 9)** — the only group that produces *new* findings:
  at least three ways to write wrong data that the schema still accepts, with
  the actual `INSERT` written out. Best run by a **separate agent** given only
  the schema and the requirements, with the rationale documents withheld —
  losing the justification is exactly what lets it see the hole.
- **App-enforced register** — every rule the database does **not** stop, with
  why, where it is enforced in code, and the test that proves it. Rules that
  live only as scattered notes are the ones that disappear on the way to code,
  and they disappear silently because nothing fails.

Findings are ranked Blocker / Major / Minor. Remaining open questions are a
**legitimate deliverable**, not a failure — they are the questions your BA
still has to answer.

---

## Resuming

`STATE.md` records the last completed stage, the chosen engine and its status
(`undecided` / `provisional` / `decided`), and the `## Amendments` log of what a
later stage corrected in an earlier one. Point the agent at an existing workspace
and it continues rather than starting over.

See [evaluation.md](./evaluation.md) for how to *test* this workflow — including
the control arm that a single clean run does not give you.
