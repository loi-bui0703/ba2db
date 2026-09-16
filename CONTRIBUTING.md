# Contributing to ba2db

Thanks for considering a contribution. This project is mostly **prose**, not
code — the skill's quality lives in how precisely it instructs an agent. That
makes contributions easier to write and harder to verify, so please read this.

## Ways to contribute

| Kind | Where | Difficulty |
|---|---|---|
| Fix a wrong or unclear instruction | `skill/skills/*/SKILL.md` | easy |
| Improve modeling knowledge | `skill/references/*.md` | medium |
| Add a DBMS dialect | `skill/references/dbms-notes.md` | medium |
| Add a host (agent platform) | `src/hosts.mjs` + `docs/hosts/` | medium |
| Add a worked example | `examples/` | high — see below |
| Report a bad design the skill produced | Issues → *Skill quality* | easy, very valuable |

## Getting started

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cd ba2db
node test/run.mjs        # no install step — zero dependencies
node bin/ba2db.mjs doctor
```

There is nothing to build. Node ≥ 18 is the only requirement.

## Rules for changing the skill

These are what keep the skill trustworthy. A PR that breaks one will be asked
to change:

1. **No content duplication.** Host rule files and docs must *point at*
   `SKILL.md`, never copy from it. One source of truth.
2. **Stage skills stay self-contained and short.** An agent loads one stage at
   a time; a stage that grows past ~150 lines should move detail into
   `references/`.
3. **Never weaken the "no invented business facts" rule.** It is the reason the
   output is trustworthy.
4. **Identifiers in English.** Table names, column names and SQL are English
   `snake_case`. Prose may be English or Vietnamese.
5. **Every reference you cite must exist.** A test enforces this.

## Adding a host

1. Add an entry to `HOSTS` in `src/hosts.mjs` — detection paths, target paths,
   and install kind (`copy`, `rule`, or `manual`).
2. If it is a `rule` host, add its snippet to `src/rules.mjs`.
3. Add `docs/hosts/<id>.md` describing manual installation too.
4. Add the host id to the `install-matrix` job in `.github/workflows/ci.yml`.
5. Run `node test/run.mjs`.

No other file should need changing. If it does, the abstraction is wrong —
say so in the PR and we will fix it together.

## Adding an example

Examples are the strongest teaching tool in this repo and the easiest to get
wrong. An example must:

- be based on a BA scenario you describe in the example's own README;
- contain **real filled-in artifacts**, not placeholders;
- show at least one `OPEN QUESTION` left unanswered and one `Confidence: low`
  entry — an example where everything is clean teaches the wrong lesson;
- not contain real client data. Anonymise or invent.

## Reporting bad output

The most useful issue you can file. Include: the BA input (anonymised), which
stage went wrong, what the agent produced, what it should have produced, and
which model/host you used. Model matters — behaviour differs.

## Commit and PR conventions

- Conventional commits (`feat:`, `fix:`, `docs:`, `test:`, `chore:`).
- One logical change per PR.
- `node test/run.mjs` must pass. CI runs it on Node 18/20/22 across Linux,
  macOS and Windows.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
