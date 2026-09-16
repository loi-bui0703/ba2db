# GitHub Copilot

> `npx ba2db install --host copilot` does all of this for you.

## Install

```bash
npx ba2db install --host copilot --project
```

Creates `.ba2db/` and appends a delimited block to
`.github/copilot-instructions.md`.

## Use

In Copilot Chat, reference the skill explicitly for best results:

```
#file:.ba2db/SKILL.md

Design a database from the BA documents in docs/ba/. Start at Stage 0.
```

## Notes

- Copilot's instruction file is repository-scoped; there is no global install.
- Copilot follows long instruction chains less reliably than agent-first hosts.
  If it starts skipping stages, drive the stages one at a time:
  `#file:.ba2db/skills/03-logical-design/SKILL.md`.
