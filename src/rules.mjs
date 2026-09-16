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
read \`${skillPath}/SKILL.md\` first and follow its six-stage workflow.

Rules that matter:
- Do not jump straight to DDL. Each stage produces its own artifact.
- Load only the SKILL.md of the stage you are working on, not all of them.
- Every entity, attribute and rule must cite its source in the BA documents.
  Missing information becomes an OPEN QUESTION — never invent business facts.
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

export const PROMPT = (skillPath = SIDECAR_DIR) => `You are a Data Architect. Read ${skillPath}/SKILL.md and follow its six-stage
workflow to design a database from my BA documents.

- BA documents: <path>
- Target DBMS: PostgreSQL 16
- Project slug: <slug>

Start at Stage 0. Stop at the end of each stage, summarise, and ask me before
continuing. Never invent business facts — put gaps in OPEN QUESTIONS.`;
