/**
 * Rule snippets injected into each host's config file.
 *
 * These deliberately contain NO skill content — only a pointer to SKILL.md.
 * One source of truth; a rule can never drift out of sync with the skill.
 */
import { SIDECAR_DIR } from './hosts.mjs';

export const MARKER = 'ba2db';

const CORE = (skillPath) => `When the user asks to design a database, extract data requirements from
business/BA documents, build an ERD, normalize a schema, or generate DDL:
read \`${skillPath}/SKILL.md\` first and follow its seven-stage workflow
(0 intake, 1 requirements, 1B DBMS decision, 2 conceptual, 3 logical,
4 physical, 5 review).

Rules that matter:
- Do not jump straight to DDL. Each stage produces its own artifact.
- Load only the SKILL.md of the stage you are working on, not all of them.
- Every entity, attribute and rule must cite its source in the BA documents.
  Missing information becomes an OPEN QUESTION — never invent business facts.
- There is NO default DBMS. Stage 1B chooses one by reasoning from the extracted
  requirements and records an ADR with the rejected candidates and why.
- A later stage may prove an earlier one wrong. When it does, fix the earlier
  artifact — never leave two artifacts saying different things.
- Stop at the gate at the end of each stage and ask the user to confirm.
- Table and column names are English snake_case; prose may be EN/VI.`;

export const RULES = {
  cursor: (skillPath) => `---
description: Database design from BA documents (ba2db)
globs: ["**/*.md", "**/*.sql"]
alwaysApply: false
---

${CORE(skillPath)}
`,

  codex: (skillPath) => `## Database design from BA documents (ba2db)

${CORE(skillPath)}`,

  copilot: (skillPath) => `## Database design from BA documents (ba2db)

${CORE(skillPath)}`,

  opencode: (skillPath) => `# ba2db — database design from BA documents

${CORE(skillPath)}
`,
};

export const PROMPT = (skillPath = SIDECAR_DIR) => `You are a Data Architect. Read ${skillPath}/SKILL.md and follow its seven-stage
workflow to design a database from my BA documents.

- BA documents: <path>
- Target DBMS: <leave blank — Stage 1B decides it and writes an ADR>
- Platform constraints: <what ops already runs, cloud, licence, ORM — or "unknown">
- Project slug: <slug>

Start at Stage 0. Stop at the end of each stage, summarise, and ask me before
continuing. Never invent business facts — put gaps in OPEN QUESTIONS.
Do not assume a DBMS: choose one at Stage 1B from the requirements, compare real
candidates, and say which you rejected and why.`;
