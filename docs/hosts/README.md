# Host setup notes

`npx ba2db install` handles all of these automatically. These pages document
what it does, for anyone who prefers to wire it up by hand or needs to debug.

| Host | Page |
|---|---|
| Claude Code | [claude-code.md](./claude-code.md) |
| Cursor | [cursor.md](./cursor.md) |
| Codex / AGENTS.md | [codex.md](./codex.md) |
| GitHub Copilot | [copilot.md](./copilot.md) |
| OpenCode | [opencode.md](./opencode.md) |
| Anything else | [generic.md](./generic.md) |

## The rule that goes in every host

Whatever the format, the content is the same pointer — never a copy of the
skill:

```
When the user asks to design a database, extract data requirements from
business/BA documents, build an ERD, normalize a schema, or generate DDL:
read `<skill-path>/SKILL.md` first and follow its seven-stage workflow.

Rules that matter:
- Do not jump straight to DDL. Each stage produces its own artifact.
- Load only the SKILL.md of the stage you are working on.
- Every entity, attribute and rule must cite its source in the BA documents.
  Missing information becomes an OPEN QUESTION — never invent business facts.
- Stop at the gate at the end of each stage and ask the user to confirm.
- Table and column names are English snake_case; prose may be EN/VI.
```

`npx ba2db prompt` prints this with the path filled in.

## Adding a host

One entry in `src/hosts.mjs`, one snippet in `src/rules.mjs`, one page here.
See [CONTRIBUTING.md](../../CONTRIBUTING.md#adding-a-host).
