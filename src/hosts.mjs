/**
 * Host registry — where each agent platform expects a skill to live,
 * and how it is told to load it.
 *
 * Adding a host = adding one entry here. Nothing else in the CLI changes.
 */
import { homedir } from 'node:os';
import { join } from 'node:path';

export const SKILL_NAME = 'ba2db';

/** @typedef {'copy'|'rule'|'manual'} InstallKind */

export const HOSTS = [
  {
    id: 'claude-code',
    label: 'Claude Code',
    kind: 'copy',
    // Detected when this directory exists.
    detect: [join(homedir(), '.claude')],
    target: {
      global: join(homedir(), '.claude', 'skills', SKILL_NAME),
      project: join('.claude', 'skills', SKILL_NAME),
    },
    verify: 'Ask: "thiết kế database từ tài liệu BA trong docs/ba/"',
  },
  {
    id: 'cursor',
    label: 'Cursor',
    kind: 'rule',
    detect: [join(homedir(), '.cursor'), '.cursor'],
    target: {
      global: join(homedir(), '.cursor', 'rules', `${SKILL_NAME}.mdc`),
      project: join('.cursor', 'rules', `${SKILL_NAME}.mdc`),
    },
    // The rule points at the copied skill rather than duplicating it.
    copyAlongside: true,
    verify: 'Open Cursor chat and ask for a database design from your BA docs.',
  },
  {
    id: 'codex',
    label: 'Codex / AGENTS.md',
    kind: 'rule',
    detect: ['AGENTS.md', join(homedir(), '.codex')],
    target: { global: null, project: 'AGENTS.md' },
    append: true,
    copyAlongside: true,
    verify: 'Ask your agent to follow AGENTS.md and start Stage 0.',
  },
  {
    id: 'copilot',
    label: 'GitHub Copilot',
    kind: 'rule',
    detect: ['.github'],
    target: { global: null, project: join('.github', 'copilot-instructions.md') },
    append: true,
    copyAlongside: true,
    verify: 'In Copilot Chat: #file:.ba2db/SKILL.md',
  },
  {
    id: 'opencode',
    label: 'OpenCode',
    kind: 'rule',
    detect: ['opencode.json', join(homedir(), '.config', 'opencode')],
    target: { global: null, project: join('.opencode', 'rules', `${SKILL_NAME}.md`) },
    copyAlongside: true,
    verify: 'Ask OpenCode to read the rule and start Stage 0.',
  },
  {
    id: 'generic',
    label: 'Other / manual',
    kind: 'manual',
    detect: [],
    target: { global: null, project: `.${SKILL_NAME}` },
    verify: 'Paste the prompt printed by `ba2db prompt` into your agent.',
  },
];

export const getHost = (id) => HOSTS.find((h) => h.id === id);

/** Where the skill body is copied for rule-based hosts. */
export const SIDECAR_DIR = `.${SKILL_NAME}`;
