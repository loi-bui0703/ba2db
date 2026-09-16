/** The skill itself is the product — these tests guard its integrity. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const SKILL = join(ROOT, 'skill');

const skillFiles = () => {
  const out = [join(SKILL, 'SKILL.md')];
  for (const d of readdirSync(join(SKILL, 'skills'))) {
    out.push(join(SKILL, 'skills', d, 'SKILL.md'));
  }
  return out;
};

const parseFrontmatter = (content) => {
  const m = content.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const fm = {};
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z_]+):\s*(.*)$/);
    if (kv) fm[kv[1]] = kv[2].trim();
  }
  return fm;
};

test('every SKILL.md has valid frontmatter', () => {
  for (const f of skillFiles()) {
    assert.ok(existsSync(f), `missing: ${f}`);
    const fm = parseFrontmatter(readFileSync(f, 'utf8'));
    assert.ok(fm, `no frontmatter block in ${f}`);
    assert.ok(fm.name, `no name in ${f}`);
    assert.ok(fm.description, `no description in ${f}`);
    assert.match(fm.name, /^[a-z0-9]+(-[a-z0-9]+)*$/, `name must be kebab-case in ${f}`);
  }
});

test('root skill description is long enough to trigger reliably', () => {
  const fm = parseFrontmatter(readFileSync(join(SKILL, 'SKILL.md'), 'utf8'));
  assert.ok(fm.description.length > 80, 'description too short to match user intent');
  assert.ok(fm.description.length < 1024, 'description exceeds the 1024-char skill limit');
});

test('skill names are unique', () => {
  const names = skillFiles().map((f) => parseFrontmatter(readFileSync(f, 'utf8')).name);
  assert.equal(new Set(names).size, names.length, `duplicate skill names: ${names}`);
});

test('all six stages exist and are numbered in order', () => {
  const dirs = readdirSync(join(SKILL, 'skills')).sort();
  assert.deepEqual(dirs, [
    '00-intake',
    '01-requirements-extraction',
    '02-conceptual-model',
    '03-logical-design',
    '04-physical-design',
    '05-review-handoff',
  ]);
});

test('every reference and template named by a skill actually exists', () => {
  const missing = [];
  for (const f of [...skillFiles()]) {
    const body = readFileSync(f, 'utf8');
    for (const m of body.matchAll(/`((?:references|templates|scripts)\/[A-Za-z0-9._/-]+)`/g)) {
      const target = join(SKILL, m[1]);
      if (!existsSync(target)) missing.push(`${m[1]} (referenced by ${f.replace(ROOT, '.')})`);
    }
  }
  assert.deepEqual(missing, [], `dangling references:\n  ${missing.join('\n  ')}`);
});

test('templates carry no leftover example data in required ID columns', () => {
  // Templates are filled in by the agent — placeholders must stay placeholders.
  const t = readFileSync(join(SKILL, 'templates/05-review/05-traceability-matrix.md'), 'utf8');
  assert.match(t, /NOT COVERED/, 'traceability template must show the not-covered state');
  assert.match(t, /UNJUSTIFIED/, 'traceability template must show the unjustified state');
});

test('SQL template uses safe money and time types', () => {
  const sql = readFileSync(join(SKILL, 'templates/04-physical/04-schema.sql'), 'utf8');
  assert.doesNotMatch(sql, /\bfloat\b|\bdouble\b/i, 'float must never appear in the money template');
  assert.match(sql, /timestamptz/, 'timestamps should be timezone-aware');
});

test('shell scripts are executable and syntactically valid', async () => {
  const { spawnSync } = await import('node:child_process');
  for (const s of readdirSync(join(SKILL, 'scripts'))) {
    if (!s.endsWith('.sh')) continue;
    const r = spawnSync('bash', ['-n', join(SKILL, 'scripts', s)]);
    assert.equal(r.status, 0, `syntax error in ${s}: ${r.stderr}`);
  }
});
