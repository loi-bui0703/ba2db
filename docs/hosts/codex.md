# Codex / any AGENTS.md agent

> `npx ba2db install --host codex` does all of this for you.

## Install

```bash
npx ba2db install --host codex --project
```

Creates `.ba2db/` and appends a delimited block to `AGENTS.md`:

```markdown
<!-- ba2db:begin -->
## Database design from BA documents (ba2db)

When the user asks to design a database, extract data requirements from
business/BA documents, build an ERD, normalize a schema, or generate DDL:
read `.ba2db/SKILL.md` first and follow its six-stage workflow.
...
<!-- ba2db:end -->
```

Your existing `AGENTS.md` content is preserved, and `npx ba2db uninstall` removes
exactly that block and nothing else.

## Use

```
Following AGENTS.md, run the database design workflow on docs/ba/. Start at Stage 0.
```

## Notes

- This host is project-scoped only — `AGENTS.md` lives in a repository.
- Any agent that reads `AGENTS.md` works here, not just Codex.
- Re-installing does not duplicate the block; it replaces it in place.
