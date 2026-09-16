# Any other agent

No installation required.

## If your agent can read local files

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cp -r ba2db/skill ./.ba2db
npx ba2db prompt          # prints the prompt below with paths filled in
```

Then paste:

```
You are a Data Architect. Read .ba2db/SKILL.md and follow its six-stage
workflow to design a database from my BA documents.

- BA documents: <path>
- Target DBMS: PostgreSQL 16
- Project slug: <slug>

Start at Stage 0. Stop at the end of each stage, summarise, and ask me before
continuing. Never invent business facts — put gaps in OPEN QUESTIONS.
```

## If your agent cannot read local files

Web chat interfaces, internal assistants, and anything sandboxed away from your
filesystem: paste the skill text directly.

1. Paste `skill/SKILL.md` (87 lines) — this is the router.
2. Paste the stage you are running, e.g. `skill/skills/01-requirements-extraction/SKILL.md`.
3. Paste any reference that stage names, if the agent asks for it.
4. Paste the matching template from `skill/templates/`.

Every stage file is under 150 lines, so one stage plus its template fits in any
modern context window. Work one stage per conversation and carry the artifact
forward by pasting it into the next.

## Running a single stage

You do not have to run the whole workflow:

```
Read .ba2db/skills/01-requirements-extraction/SKILL.md and only extract the data
requirements from docs/ba/. Do not design a schema yet.
```

## Minimum requirements

- Can read a long document carefully
- Can write structured Markdown
- That is all — no tools, no MCP, no network
