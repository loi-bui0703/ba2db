# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because this package is mostly instructions rather than code, we version it by
**behavioural impact on generated designs**:

- **MAJOR** — the workflow changes shape (stages added/removed/reordered), or
  existing workspaces are no longer compatible.
- **MINOR** — new references, templates, hosts, or CLI commands; output gets
  richer but existing artifacts stay valid.
- **PATCH** — wording, fixes, documentation.

## [1.1.2] — 2026-09-18

### Fixed

- **`check-design.sh` was looser than the rule it enforces.** Stage 3 documents
  the double-encoded-lifecycle scan as "status column + **≥2** milestone
  timestamps with no `CHECK` tying them together"
  (`skills/03-logical-design/SKILL.md`, step 6), but the script gated on
  `nts >= 3`. A table with exactly two nullable milestone timestamps violated
  the written rule and still passed the mechanical check — the tool failed open
  on the defect class it exists to catch. The script now gates on `>= 2`.

### Added

- A regression test that reads the threshold out of **both** the skill and the
  script and asserts they are equal, rather than hardcoding a third copy of the
  number. The two can no longer drift apart silently.

## [1.1.1] — 2026-09-18

### Changed

- Packaging metadata only (npm `files`, keywords, repository, trusted
  publishing). No change to the skill or to generated designs.

## [1.1.0] — 2026-09-18

Driven by the field trial on a `go-kit`-generated service (`notificationb2b`,
30 tables). The run produced a deployable schema, but reviewing the artifacts
afterwards exposed gaps that were in the *skill*, not in the run.

### Changed — there is no default DBMS any more

- **New Stage 1B — DBMS decision**, between requirements extraction and the
  conceptual model. It reasons from the extracted `VP-*`/`BR-*`/`NF-*`, compares
  real candidates, eliminates on must-haves, and **counts the rules each
  candidate cannot enforce**. Deliberately not a weighted score.
- `PostgreSQL 16 (default)` removed from `SKILL.md`, Stage 0, the intake
  template, the DDL template header, `init-workspace.sh`, the host rule
  snippets and the copy-paste prompt. A fresh workspace starts
  `dbms: undecided`, and a run that cannot decide records `provisional` with an
  owner instead of pretending it was settled.
- Stage 0 now collects **platform constraints** (what ops runs, cloud, licence,
  ORM) rather than picking an engine before there is anything to reason from.

### Added

- `references/dbms-selection.md` — drivers traced to requirement ids, a
  capability matrix across PostgreSQL 16 / MySQL 8 / SQL Server 2022 / Oracle,
  and the four classic ways engine selection goes wrong.
- `references/storage-topology.md` — queue in the database vs a broker (and the
  four things a queue-in-database *must* have), view vs materialized view vs
  real table, enum type vs lookup table, archive tiers, read/write split.
- **Portability budget** in `dbms-notes.md` and `04-migration-notes.md`: which
  engine-exclusive features the design leans on and which `BR-*` depend on each.
  Three or more, and the engine assumption is High risk, not Medium.
- **Write path & concurrency** in `indexing-and-performance.md`: UPDATE budget
  and HOT updates, hot-row counters, queue claim (`FOR UPDATE SKIP LOCKED` /
  lease columns), connection pooling. A queue table with no claim mechanism is
  incorrect, not unoptimised.
- **Operational job register** in the migration-notes template — each job with
  what breaks if it does not run, whether that is *recoverable*, and how anyone
  would notice.
- `scripts/check-design.sh` — mechanical pass over a workspace: id namespace
  collisions, ids referenced but never defined, self-reported vs counted totals,
  Stage 3/4 drift, double-encoded lifecycles, per-table constraint density,
  missing app-enforced register. Exits non-zero on findings.
- `validate-ddl.sh --assert <file>` with **exit code 3** for a passing DDL whose
  constraints do not enforce what they claim, plus `--report` for per-table
  constraint density and foreign keys with no index on the child side.
- `templates/05-review/05-assertions.sql` — both-directions assertion harness
  (`assert_rejects` + `assert_accepts`), so constraint testing is a reusable
  artifact instead of an ad-hoc session.
- `templates/05-review/05-app-enforced-rules.md` — a handoff register for every
  rule the database does not stop, with the reason classified L1–L4. L4 means
  *our own* choice removed the enforcement point, and must appear in findings.
- **Checklist group 9 — adversarial pass**: at least three ways to write wrong
  data the schema still accepts, with the `INSERT` written out. Guidance in
  `agents/README.md` for running it as a separate agent with the rationale
  documents withheld.
- **Cross-cutting principle step** in Stage 2 — *what does this system have to
  prove?* — so a repeated move is named once instead of rediscovered three times.
- `docs/evaluation.md` — how to test the skill: the control arm, independent
  inputs, case-type coverage, machine-verified vs self-reported numbers.

### Fixed

- **Stage 4 now back-propagates.** Enforcement claims are written
  `DB (planned)` at Stage 3 and resolved by Stage 4 against a real engine;
  corrections are applied to the Stage 3 artifact and logged under
  `## Amendments` in `STATE.md`. Two artifacts saying different things is a
  false claim handed to the next reader.
- **Denormalization ids are `DN-*`.** `D-*` already belongs to Stage 2
  modelling decisions; the trial shipped `D-01` meaning two different things in
  one artifact set, which made every cross-reference ambiguous — including the
  DDL comments.
- **Double-encoded lifecycles** (status column + nullable per-milestone
  timestamps with nothing tying them together) are now a Stage 3 rule, a
  checklist item, and a `check-design.sh` detection. The trial design allowed
  `status = 'DELIVERED'` with `sent_at IS NULL` on its hottest table, and the
  self-review did not catch it.
- **`validate-ddl.sh` readiness race**: it probed `pg_isready`, which succeeds
  against the temporary server `initdb` starts, so the DDL could run before the
  target database existed and the resulting "database does not exist" looked
  like a DDL defect. It now probes the target database itself.
- Duplicated "Đọc hai lượt / Đọc ba lượt" heading in Stage 1.


## [Unreleased]

Found by running the skill end-to-end against a real service scaffolded from
`go-kit` (a B2B notification platform: 3 BA documents, 30 tables, 26 business
rules). Every item below is a defect the trial run surfaced.

### Fixed

- **`init` wrote the workspace into the package, not the project.**
  `init-workspace.sh` derived its destination from the script's own location, so
  `npx ba2db init my-project` created `workspace/my-project/` inside
  `node_modules/ba2db/skill/` — or inside `~/.claude/skills/ba2db/` for an
  installed skill. The artifacts landed outside the repository and were never
  committed. Templates are still read from the skill directory; the workspace is
  now created in the current working directory, overridable with
  `BA2DB_WORKSPACE_ROOT`. The script also validates the slug itself now, instead
  of trusting the CLI to have done it.
- **`check-structure.sh` failed on a clean install.** It required
  `agents/README.md`, which the package has never shipped — while `SKILL.md`
  pointed readers at that same missing file.
- **`doctor` and `check-structure.sh` disagreed about what "complete" means.**
  Each carried its own hand-maintained list; doctor's omitted `agents/README.md`
  and three templates, so it reported "All checks passed" on a package the other
  tool rejected. Both now read `skill/MANIFEST`, and a test asserts they report
  the same count.

### Added

- `skill/agents/README.md` — per-host install instructions, manual install, and
  how to add a host. Referenced by `SKILL.md` since 1.0.0; now it exists.
- `skill/MANIFEST` — the single source of truth for package completeness.
- **`validate-ddl.sh` now prefers Docker.** Previously it needed `psql` *and* a
  running server on the host, and exited 2 otherwise — which in practice meant
  Stage 4 skipped validation on most machines. It now spins up a throwaway
  `postgres:16` (or `mysql:8`) container, applies the DDL, and reports how many
  tables, partitions, indexes, constraints, triggers and views were actually
  created — because "no errors" is not the same as "something got built". Falls
  back to a local client only when Docker is unavailable, and says so, since the
  local client is usually a different version from the design target.
  New flags: `--version`, `--engine docker|local|auto`, `--keep`, `--psql`.
  Exit codes are now contractual: 0 clean, 1 failed (fix it), 2 not verified
  (**say so**).
- **Stage 4 gained a constraint-testing step (5b).** Running the DDL proves the
  syntax; it does not prove the business rules are enforced. The stage now
  requires two assertions per DB-enforced rule — one violation that must be
  rejected, and one *near-miss that must be accepted*. The second catches
  over-broad constraints, which the first cannot: a `UNIQUE` that is too wide
  rejects the wrong thing happily.
- Eight regression tests covering all of the above (28 → 36).

## [1.0.0] — 2026-09-16

First public release.

### Added

- Six-stage workflow: intake → requirements extraction → conceptual model →
  logical design → physical design → review & handoff, each with its own
  `SKILL.md` and a confirmation gate.
- Nine extraction sections (`BC/EN/AT/RL/BR/PR/VP/NF/XX`) with stable IDs, plus
  a three-pass reading method (open sweep → checklist classify → challenge).
- Two-way traceability matrix: uncovered requirements and unjustified schema
  objects are both reported as defects.
- Eight reference documents: extraction checklist, naming conventions,
  normalization, modeling patterns, anti-patterns, indexing and performance,
  DBMS dialect notes, review checklist.
- Eleven bilingual (EN/VI) artifact templates.
- Zero-dependency CLI: `install`, `uninstall`, `list`, `doctor`, `init`,
  `prompt`, `hosts`.
- Host support: Claude Code, Cursor, Codex/AGENTS.md, GitHub Copilot, OpenCode,
  and a manual mode for any other agent.
- `install.sh` for users without Node.
- Test suite (21 tests) covering skill integrity, frontmatter validity,
  dangling references, and non-destructive install/uninstall.
- CI across Node 18/20/22 on Linux, macOS and Windows.

[Unreleased]: https://github.com/loi-bui0703/ba2db/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/loi-bui0703/ba2db/releases/tag/v1.0.0
