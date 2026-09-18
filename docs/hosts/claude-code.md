# Claude Code

> `npx ba2db install --host claude-code` does all of this for you.
> This page is for manual setup and debugging.

## Install

```bash
npx ba2db install --host claude-code --global    # ~/.claude/skills/ba2db
npx ba2db install --host claude-code --project   # .claude/skills/ba2db
```

Claude Code reads the `name` and `description` frontmatter in `SKILL.md` and
activates the skill on its own when you say something like *"design a database
from the BA docs in docs/ba/"*. You can also invoke it explicitly:

```
/ba2db design a database from the documents in docs/ba/
```

## Manual install

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cp -r ba2db/skill ~/.claude/skills/ba2db
```

Or, without copying anything, add to your project's `CLAUDE.md`:

```markdown
## Database design
When designing a database from BA documents, read `path/to/ba2db/skill/SKILL.md`
and follow its seven-stage workflow. Load only the current stage's SKILL.md.
```

## Notes

- **Large document sets**: the `Explore` subagent is good for the Stage 0
  inventory, but do the Stage 1 extraction in the main session — it needs
  precise citations, not a summary.
- **Plan mode** pairs well with Stages 2–3 if you want to approve modeling
  decisions before files are written.
- A global install applies in every project; a project install only in that
  repository. `npx ba2db list` shows which you have.
