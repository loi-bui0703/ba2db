# Cursor

> `npx ba2db install --host cursor` does all of this for you.

## Install

```bash
npx ba2db install --host cursor --project
```

Creates:

```
.ba2db/                      the skill itself
.cursor/rules/ba2db.mdc      a rule pointing at it
```

## The rule file

```markdown
---
description: Database design from BA documents (ba2db)
globs: ["**/*.md", "**/*.sql"]
alwaysApply: false
---

When the user asks to design a database, extract data requirements from
business/BA documents, build an ERD, normalize a schema, or generate DDL:
read `.ba2db/SKILL.md` first and follow its seven-stage workflow.
...
```

`alwaysApply: false` keeps it out of context until it is relevant — the skill is
loaded on demand, and only the stage in use.

## Notes

- Cursor may need a restart, or a new chat, to pick up a newly added rule file.
- If you install globally (`--global`), the rule lands in `~/.cursor/rules/` and
  the skill in `~/.ba2db` — check that your Cursor version reads global rules.
