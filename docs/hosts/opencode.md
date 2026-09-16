# OpenCode

> `npx ba2db install --host opencode` does all of this for you.

## Install

```bash
npx ba2db install --host opencode --project
```

Creates `.ba2db/` and `.opencode/rules/ba2db.md`.

## Alternative: load it always

In `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [".ba2db/SKILL.md"]
}
```

This keeps the router skill in context permanently. The stage files are still
loaded on demand, so the cost is small — but the rule-file approach is leaner.

## Notes

- Project-scoped only.
- `.ba2db/` is safe to commit if you want the whole team on the same version;
  add it to `.gitignore` if you would rather each developer install their own.
