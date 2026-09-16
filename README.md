<div align="center">

# ba2db

**Turn Business Analysis documents into a complete, traceable database design.**

[![CI](https://github.com/loi-bui0703/ba2db/actions/workflows/ci.yml/badge.svg)](https://github.com/loi-bui0703/ba2db/actions/workflows/ci.yml)
[![npm](https://img.shields.io/npm/v/ba2db?color=blue)](https://www.npmjs.com/package/ba2db)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen)](https://nodejs.org)
[![Zero dependencies](https://img.shields.io/badge/dependencies-0-success)](./package.json)

An agent skill — not a service. Works with Claude Code, Cursor, Codex, Copilot,
OpenCode, or any agent that can read a file.

[English](./README.md) · [Tiếng Việt](./README.vi.md)

</div>

---

## The problem

Ask an AI agent to "design a database for these requirements" and it will hand
you DDL in thirty seconds. The tables will look plausible. Some of them will
describe a business that does not exist, and you will not find out which ones
until integration testing.

The failure is not the model's knowledge. It is that nothing forced the agent to
**read before designing**, to **say where each table came from**, or to **admit
what the documents never specified**.

## What ba2db does

It replaces one big leap with six gated stages, each producing an artifact that
the next stage consumes:

```
BA documents
    │
    ├─ 0  Intake & scoping          → what we have, what we are designing for
    ├─ 1  Requirements extraction   → 9 sections, numbered IDs, every one cited
    ├─ 2  Conceptual model          → ERD a business reader can validate
    ├─ 3  Logical design            → tables, keys, types, data dictionary
    ├─ 4  Physical design           → runnable DDL, index plan, migration notes
    └─ 5  Review & handoff          → traceability matrix, findings, open questions
                                       │
                                       ▼
                          A design you can defend line by line
```

Three rules make the output trustworthy:

| Rule | Effect |
|---|---|
| **Never invent business facts** | Every entity, attribute and rule cites `BA-xx §section`. Gaps become `OPEN QUESTIONS`, not guesses. |
| **Two-way traceability** | A requirement with no table is *missing work*. A table with no requirement is *invented*. Both are reported as defects. |
| **A gate at every stage** | The agent stops, summarises, and waits. Mistakes get caught at the ERD, not in the DDL. |

## Install

```bash
npx ba2db install
```

It detects your agent, asks where to put the skill, and installs it:

```
Detected:
  ✓ Claude Code  /Users/you/.claude
  ✓ Cursor       /Users/you/.cursor

Which host do you want to install into?
  ● 1) Claude Code
    2) Cursor

Install scope?
  ● 1) Global — available in every project
    2) Project — this repository only

✓ Installed ba2db for Claude Code (global)
  skill → /Users/you/.claude/skills/ba2db
```

<details>
<summary><b>Other ways to install</b></summary>

**Non-interactive**

```bash
npx ba2db install --host claude-code --global --yes
```

**Without Node**

```bash
curl -fsSL https://raw.githubusercontent.com/loi-bui0703/ba2db/main/install.sh | bash
```

**From a clone**

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cd ba2db && ./install.sh --host cursor --project
```

**Manually, for any other agent**

```bash
npx ba2db prompt     # prints a copy-paste prompt
```

</details>

### Supported hosts

| Host | How it installs | Scope |
|---|---|---|
| Claude Code | skill directory | global · project |
| Cursor | `.cursor/rules/ba2db.mdc` → skill | global · project |
| Codex / AGENTS.md | block appended to `AGENTS.md` | project |
| GitHub Copilot | block appended to `copilot-instructions.md` | project |
| OpenCode | `.opencode/rules/ba2db.md` | project |
| Anything else | copy-paste prompt | — |

Rule files always **point at** the skill; they never copy it. One source of
truth, so a host can never drift out of sync.

Missing yours? [Open a host request](https://github.com/loi-bui0703/ba2db/issues/new?template=host-request.yml)
— adding one is a single entry in `src/hosts.mjs`.

## Use

```bash
npx ba2db init my-project          # scaffold a workspace
cp ~/Downloads/*.docx workspace/my-project/ba-docs/
```

Then, in your agent:

```
Design a database from the BA documents in workspace/my-project/ba-docs/.
Target: PostgreSQL 16.
```

The agent loads the skill, runs Stage 0, and stops for your confirmation.
You get eleven artifacts:

```
workspace/my-project/
├── 00-intake-report.md              scope, assumptions, open questions
├── 01-data-requirements.md          9 sections, every item cited
├── 01-glossary.md                   terms, synonyms, ambiguities
├── 02-conceptual-erd.md             Mermaid ERD + entity catalog
├── 03-logical-schema.md             tables, keys, normalization decisions
├── 03-data-dictionary.md            every column, typed and sourced
├── 04-schema.sql                    runnable DDL
├── 04-index-plan.md                 each index justified by a real query
├── 04-migration-notes.md            deployment, roles, backup, PII
├── 05-review-report.md              findings by severity, open questions
└── 05-traceability-matrix.md        requirements ⇄ schema, both directions
```

See [`examples/ecommerce-mini/`](./examples/ecommerce-mini/) for a filled-in run.

## What it knows

The skill carries eight reference documents it loads only when relevant —
so a stage costs context only for what it actually needs:

| Reference | Covers |
|---|---|
| `extraction-checklist.md` | 12 signal groups to sweep BA documents for; how to tell an entity from an attribute |
| `naming-conventions.md` | Naming rules, standard types per DBMS, mandatory audit columns |
| `normalization.md` | 1NF→BCNF, and the four things you must write down before denormalizing |
| `modeling-patterns.md` | SCD/versioning, multi-tenancy, party model, hierarchies, i18n, state machines |
| `anti-patterns.md` | EAV, polymorphic FK, god tables, float money, comma-separated values, 16 total |
| `indexing-and-performance.md` | Index selection, composite column order, partitioning, sizing |
| `dbms-notes.md` | PostgreSQL · MySQL 8 · SQL Server · Oracle dialect differences |
| `review-checklist.md` | 8 groups of acceptance checks for the final review |

## CLI

```
npx ba2db <command>

  install        Install into a detected agent host
  uninstall      Remove it again — leaves your own rules untouched
  list           Show where ba2db is installed
  doctor         Verify the installation is complete and intact
  init <slug>    Create a design workspace
  prompt         Print the copy-paste prompt
  hosts          List supported hosts, marking the ones detected here
```

## Design decisions

<details>
<summary><b>Why no server, no MCP, no dependencies?</b></summary>

The problem being solved is the agent's *discipline*, not its *memory* or
*tooling*. Discipline is prose. Adding a runtime would buy nothing and cost
portability, install friction, and supply-chain surface.

So: Markdown and shell, zero npm dependencies, no network calls, no telemetry.
It works offline, on any model, and you can audit all of it in an afternoon.
</details>

<details>
<summary><b>Why nine extraction sections — doesn't a fixed taxonomy narrow the agent?</b></summary>

It would, if the list were closed. Three things keep it open:

- **`S9 — Unclassified / insight`** catches anything that does not fit S1–S8.
  An empty `S9` on a real BA document is treated as *suspicious*, not clean.
- **Three reading passes**: an open sweep with the checklist closed, then
  classification, then a deliberate *challenge* pass that asks what the sections
  still cannot hold.
- **The checklist is a safety net, not a thinking frame** — it ships with a
  section listing five signs it is doing harm (every entity having exactly 4–5
  attributes, no `Confidence: low` entries anywhere, and so on).

Structure does narrow the agent. That is the deliberate trade: a finding filed
in the wrong section is recoverable; a confidently invented table is not.
</details>

<details>
<summary><b>Why does prose stay bilingual but code stay English?</b></summary>

Vietnamese identifiers break tooling, ORMs, and every downstream developer's
autocomplete. Vietnamese *explanation* is what lets a Vietnamese BA actually
validate the model. So documents are EN/VI; `snake_case` identifiers and all
SQL are English, always.
</details>

## Contributing

Issues about **bad designs the skill produced** are the most valuable thing you
can file — that is the product failing, and it is fixable. See
[CONTRIBUTING.md](./CONTRIBUTING.md).

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cd ba2db && node test/run.mjs     # zero deps, nothing to build
```

## License

[MIT](./LICENSE) © loi-bui0703
