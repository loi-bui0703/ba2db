# Installation

## Requirements

| Path | Needs |
|---|---|
| `npx ba2db` | Node ≥ 18 |
| `install.sh` | bash, git (only if not running from a clone) |
| Manual | nothing |

No database, no network access, no account.

## npx (recommended)

```bash
npx ba2db install
```

Interactive: detects hosts, asks which one and what scope, installs. To script it:

```bash
npx ba2db install --host claude-code --global --yes
```

| Flag | Meaning |
|---|---|
| `--host <id>` | `claude-code`, `cursor`, `codex`, `copilot`, `opencode`, `generic` |
| `--global` | Install for the current user (where the host supports it) |
| `--project` | Install into the current repository |
| `--force` | Overwrite an existing install |
| `-y, --yes` | Accept detected defaults, never prompt |

## Shell installer

For machines without Node:

```bash
curl -fsSL https://raw.githubusercontent.com/loi-bui0703/ba2db/main/install.sh | bash
```

> Piping a script from the internet into bash deserves a look first:
> `curl -fsSL <url> | less`. The script only copies files and appends a marked
> block to rule files — it makes no network calls beyond its own `git clone`.

From a clone:

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cd ba2db
./install.sh --host cursor --project
```

## Manual

Any agent that can read files:

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cp -r ba2db/skill ./.ba2db
npx ba2db prompt          # or copy the prompt from docs/hosts/generic.md
```

For agents with no file access at all (web chat interfaces), paste the contents
of `skill/SKILL.md` plus the stage file you are currently on. Each stage is
under 150 lines, so one stage fits comfortably in any context window.

## What gets written where

| Host | Files created |
|---|---|
| Claude Code | `~/.claude/skills/ba2db/` *or* `.claude/skills/ba2db/` |
| Cursor | `.ba2db/` + `.cursor/rules/ba2db.mdc` |
| Codex | `.ba2db/` + a marked block appended to `AGENTS.md` |
| Copilot | `.ba2db/` + a marked block in `.github/copilot-instructions.md` |
| OpenCode | `.ba2db/` + `.opencode/rules/ba2db.md` |
| Generic | `.ba2db/` |

Blocks appended to shared files are delimited:

```markdown
<!-- ba2db:begin -->
...
<!-- ba2db:end -->
```

Uninstall removes exactly that block and nothing else. Your own rules in the
same file are never touched — there is a test for this.

## Verify

```bash
npx ba2db doctor
```

```
Package
  ✓ skill/ directory present
  ✓ 23 skill files intact

Installations
  ✓ Claude Code (global)  /Users/you/.claude/skills/ba2db

All checks passed.
```

## Uninstall

```bash
npx ba2db uninstall                              # shows what is installed
npx ba2db uninstall --host claude-code --global  # removes one
```

## Updating

```bash
npx ba2db@latest install --force
```

`--force` is required — an install that would overwrite an existing one fails
loudly rather than silently replacing work you may have customised.

## Troubleshooting

**`No known agent host detected`** — you are outside your project directory, or
your agent stores config somewhere ba2db does not know yet. Use
`--host generic`, or [file a host request](https://github.com/loi-bui0703/ba2db/issues/new?template=host-request.yml).

**The agent ignores the skill** — check it was installed in the right scope
(`npx ba2db list`). For Claude Code, a global skill applies everywhere; for the
rule-based hosts, the rule is per-repository. Some hosts need a restart to pick
up a new rule file.

**`Target already exists`** — you already have it installed. Use `--force`, or
`uninstall` first.

**Windows** — the CLI is tested on Windows in CI. `install.sh` is not; use
`npx ba2db install` there.
