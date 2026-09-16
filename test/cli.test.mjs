/** CLI behaviour — installs write real files, so every test uses a temp dir. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, existsSync, readFileSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CLI = join(ROOT, 'bin', 'ba2db.mjs');
const SKILL_SRC = join(ROOT, 'skill');

const cli = (args, cwd) => spawnSync('node', [CLI, ...args], { cwd, encoding: 'utf8' });
const tmp = () => mkdtempSync(join(tmpdir(), 'ba2db-test-'));

test('--help exits cleanly and lists every command', () => {
  const r = cli(['--help']);
  assert.equal(r.status, 0);
  for (const c of ['install', 'uninstall', 'list', 'doctor', 'init', 'prompt', 'hosts']) {
    assert.match(r.stdout, new RegExp(`\\b${c}\\b`), `help is missing "${c}"`);
  }
});

test('--version prints a semver string', () => {
  const r = cli(['--version']);
  assert.equal(r.status, 0);
  assert.match(r.stdout.trim(), /^\d+\.\d+\.\d+$/);
});

test('unknown command exits non-zero', () => {
  const r = cli(['definitely-not-a-command']);
  assert.equal(r.status, 1);
  assert.match(r.stderr, /Unknown command/);
});

test('unknown option exits non-zero rather than silently ignoring it', () => {
  const r = cli(['install', '--nope']);
  assert.equal(r.status, 1);
  assert.match(r.stderr, /Unknown option/);
});

test('doctor passes on a clean package', () => {
  const r = cli(['doctor']);
  assert.equal(r.status, 0);
  assert.match(r.stdout, /All checks passed/);
});

test('project install into a copy-host writes the whole skill', async () => {
  const dir = tmp();
  try {
    const { install } = await import('../src/install.mjs');
    install({ hostId: 'claude-code', scope: 'project', skillSrc: SKILL_SRC, cwd: dir });
    const dest = join(dir, '.claude', 'skills', 'ba2db');
    assert.ok(existsSync(join(dest, 'SKILL.md')));
    assert.ok(existsSync(join(dest, 'references', 'anti-patterns.md')));
    assert.ok(existsSync(join(dest, 'skills', '03-logical-design', 'SKILL.md')));
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('installing twice fails loudly instead of clobbering', async () => {
  const dir = tmp();
  try {
    const { install } = await import('../src/install.mjs');
    install({ hostId: 'claude-code', scope: 'project', skillSrc: SKILL_SRC, cwd: dir });
    assert.throws(
      () => install({ hostId: 'claude-code', scope: 'project', skillSrc: SKILL_SRC, cwd: dir }),
      (e) => e.code === 'EEXISTS_TARGET'
    );
    // ...but --force is allowed to replace it.
    install({ hostId: 'claude-code', scope: 'project', skillSrc: SKILL_SRC, cwd: dir, force: true });
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('append-style install preserves the user existing AGENTS.md content', async () => {
  const dir = tmp();
  try {
    const { install } = await import('../src/install.mjs');
    const { writeFileSync } = await import('node:fs');
    const agents = join(dir, 'AGENTS.md');
    writeFileSync(agents, '# My rules\n\nDo not break my build.\n');
    install({ hostId: 'codex', scope: 'project', skillSrc: SKILL_SRC, cwd: dir });
    const content = readFileSync(agents, 'utf8');
    assert.match(content, /Do not break my build/, 'user content was destroyed');
    assert.match(content, /ba2db:begin/, 'marker block missing');
    assert.match(content, /SKILL\.md/, 'rule does not point at the skill');
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('uninstall removes only our block, never the user own rules', async () => {
  const dir = tmp();
  try {
    const { install, uninstall } = await import('../src/install.mjs');
    const { writeFileSync } = await import('node:fs');
    const agents = join(dir, 'AGENTS.md');
    writeFileSync(agents, '# My rules\n\nDo not break my build.\n');
    install({ hostId: 'codex', scope: 'project', skillSrc: SKILL_SRC, cwd: dir });
    uninstall({ hostId: 'codex', scope: 'project', cwd: dir });
    const content = readFileSync(agents, 'utf8');
    assert.match(content, /Do not break my build/, 'user content was removed');
    assert.doesNotMatch(content, /ba2db:begin/, 'our block survived uninstall');
    assert.ok(!existsSync(join(dir, '.ba2db')), 'sidecar skill dir survived uninstall');
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('reinstalling an append host does not duplicate the block', async () => {
  const dir = tmp();
  try {
    const { install } = await import('../src/install.mjs');
    install({ hostId: 'codex', scope: 'project', skillSrc: SKILL_SRC, cwd: dir, force: true });
    install({ hostId: 'codex', scope: 'project', skillSrc: SKILL_SRC, cwd: dir, force: true });
    const content = readFileSync(join(dir, 'AGENTS.md'), 'utf8');
    assert.equal(content.match(/ba2db:begin/g).length, 1, 'block was duplicated');
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('global-only scope is rejected with a helpful message for project-only hosts', async () => {
  const { install } = await import('../src/install.mjs');
  assert.throws(
    () => install({ hostId: 'codex', scope: 'global', skillSrc: SKILL_SRC, cwd: tmp() }),
    /--project/
  );
});

test('init scaffolds a workspace and refuses a bad slug', () => {
  const dir = tmp();
  try {
    mkdirSync(join(dir, 'skill'), { recursive: true });
    const bad = cli(['init', 'Bad Slug!'], dir);
    assert.equal(bad.status, 1);
    assert.match(bad.stderr, /Invalid slug/);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('prompt output is self-contained and mentions the gate rule', () => {
  const r = cli(['prompt']);
  assert.equal(r.status, 0);
  assert.match(r.stdout, /SKILL\.md/);
  assert.match(r.stdout, /Stage 0/);
});
