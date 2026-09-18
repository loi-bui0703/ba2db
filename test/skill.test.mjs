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

test('all seven stages exist and are numbered in order', () => {
  const dirs = readdirSync(join(SKILL, 'skills')).sort();
  assert.deepEqual(dirs, [
    '00-intake',
    '01-requirements-extraction',
    '01b-dbms-selection',
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

// --- regression guards for the defects found by the go-kit trial run --------

test('MANIFEST is the single source of truth and every entry exists', () => {
  const manifestPath = join(SKILL, 'MANIFEST');
  assert.ok(existsSync(manifestPath), 'skill/MANIFEST must exist — doctor and check-structure both read it');

  const entries = readFileSync(manifestPath, 'utf8')
    .split('\n')
    .map((l) => l.replace(/#.*$/, '').trim())
    .filter(Boolean);

  assert.ok(entries.length > 20, 'MANIFEST looks truncated');
  for (const e of entries) {
    assert.ok(existsSync(join(SKILL, e)), `MANIFEST lists a file the skill does not ship: ${e}`);
  }
});

test('every file the skill references in prose is actually shipped', () => {
  // SKILL.md pointed readers at agents/README.md for eight months before the
  // file existed. A broken pointer is a broken skill.
  const body = readFileSync(join(SKILL, 'SKILL.md'), 'utf8');
  for (const m of body.matchAll(/`((?:agents|references|templates|scripts|skills)\/[^`]+?\.(?:md|sql|sh))`/g)) {
    assert.ok(existsSync(join(SKILL, m[1])), `SKILL.md references a missing file: ${m[1]}`);
  }
});

test('doctor and check-structure.sh cannot disagree about completeness', async () => {
  const { spawnSync } = await import('node:child_process');

  const sh = spawnSync('bash', [join(SKILL, 'scripts', 'check-structure.sh')], { encoding: 'utf8' });
  assert.equal(sh.status, 0, `check-structure failed: ${sh.stdout}${sh.stderr}`);

  const doctor = spawnSync('node', [join(ROOT, 'bin', 'ba2db.mjs'), 'doctor'], { encoding: 'utf8' });
  assert.match(doctor.stdout, /skill files intact/);

  // Both must report the same file count, because both read MANIFEST.
  const shCount = Number(sh.stdout.match(/\((\d+) files\)/)?.[1]);
  const drCount = Number(doctor.stdout.match(/(\d+) skill files intact/)?.[1]);
  assert.ok(shCount > 0 && drCount > 0, 'both tools must report a file count');
  assert.equal(shCount, drCount, 'check-structure and doctor disagree on the required file list');
});

test('validate-ddl.sh prefers docker and documents its exit codes', () => {
  const s = readFileSync(join(SKILL, 'scripts', 'validate-ddl.sh'), 'utf8');
  assert.match(s, /docker run/, 'must be able to spin up a clean database in docker');
  assert.match(s, /docker_usable/, 'must detect whether docker is actually running, not just installed');
  // Exit 2 means "not verified" — the agent must never report it as a pass.
  assert.match(s, /exit 2/, 'must have a distinct exit code for "no environment"');
  assert.match(s, /CHƯA ĐƯỢC CHẠY THỬ/, 'the no-environment path must say the DDL was not tested');
});

test('stage 4 tells the agent to run the DDL and test the constraints', () => {
  const s = readFileSync(join(SKILL, 'skills/04-physical-design/SKILL.md'), 'utf8');
  assert.match(s, /validate-ddl\.sh/);
  assert.match(s, /exit/i, 'stage 4 must explain what each exit code obliges the agent to do');
  assert.match(s, /hợp lệ nhưng gần giống/, 'stage 4 must require testing the near-miss ACCEPT case, not only the reject case');
});

// --- regression guards for the DBMS-selection stage and the cross-stage loop ---

test('the skill has no default DBMS anywhere', () => {
  // A default is a conclusion without premises: nobody can review it and
  // nobody knows when to revisit it. Stage 1B must earn the choice instead.
  const files = [
    'SKILL.md',
    'skills/00-intake/SKILL.md',
    'references/dbms-notes.md',
    'templates/01-requirements/00-intake-report.md',
    'scripts/init-workspace.sh',
  ];
  for (const f of files) {
    const body = readFileSync(join(SKILL, f), 'utf8');
    assert.doesNotMatch(body, /mặc định PostgreSQL|PostgreSQL 16 \*\(default\)\*|postgresql-16/i,
      `${f} still carries a default DBMS`);
  }
});

test('stage 1B sits between requirements extraction and the conceptual model', () => {
  const root = readFileSync(join(SKILL, 'SKILL.md'), 'utf8');
  const iReq = root.indexOf('01-requirements-extraction/SKILL.md');
  const iDbms = root.indexOf('01b-dbms-selection/SKILL.md');
  const iConc = root.indexOf('02-conceptual-model/SKILL.md');
  assert.ok(iReq > 0 && iDbms > 0 && iConc > 0, 'all three stages must be listed');
  assert.ok(iReq < iDbms && iDbms < iConc,
    'DBMS selection must come after extraction (needs VP-*/BR-*) and before modeling');

  // Stage 1 must actually hand off to it, or the stage is unreachable.
  const s1 = readFileSync(join(SKILL, 'skills/01-requirements-extraction/SKILL.md'), 'utf8');
  assert.match(s1, /01b-dbms-selection/, 'stage 1 gate must hand off to stage 1B');
});

test('stage 1B compares candidates and forbids a scored-total shortcut', () => {
  const s = readFileSync(join(SKILL, 'skills/01b-dbms-selection/SKILL.md'), 'utf8');
  assert.match(s, /Must-have/, 'must eliminate on must-haves, not rank on preferences');
  assert.match(s, /BR-\*/, 'must count the rules each candidate cannot enforce');
  assert.match(s, /provisional/, 'must define what happens when the user cannot decide');
  assert.match(s, /Không dùng điểm tổng có trọng số/,
    'weighted totals manufacture false objectivity from self-invented weights');
});

test('denormalization IDs are DN-*, never D-* (Stage 2 owns D-*)', () => {
  // The go-kit trial shipped D-01 meaning two different things in one artifact
  // set: a Stage-2 modelling decision and a Stage-3 denormalization. Every
  // cross-reference, including DDL comments, became ambiguous.
  const norm = readFileSync(join(SKILL, 'references/normalization.md'), 'utf8');
  assert.match(norm, /DN-01/, 'normalization reference must use the DN-* namespace');
  assert.doesNotMatch(norm, /Denormalization D-01/, 'D-* collides with Stage 2 decisions');

  const tpl = readFileSync(join(SKILL, 'templates/03-logical/03-logical-schema.md'), 'utf8');
  assert.match(tpl, /DN-01/, 'logical template must use DN-*');
});

test('stage 4 must back-propagate what it disproves', () => {
  const s4 = readFileSync(join(SKILL, 'skills/04-physical-design/SKILL.md'), 'utf8');
  assert.match(s4, /[Bb]ack-propagate/, 'stage 4 must have an explicit back-propagation step');
  assert.match(s4, /DB \(planned\)/, 'it must resolve the provisional enforcement claims');
  assert.match(s4, /Amendments/, 'amendments must be recorded, not applied silently');

  const s3 = readFileSync(join(SKILL, 'skills/03-logical-design/SKILL.md'), 'utf8');
  assert.match(s3, /DB \(planned\)/, 'stage 3 claims must be marked provisional in the first place');

  const tpl = readFileSync(join(SKILL, 'templates/03-logical/03-logical-schema.md'), 'utf8');
  assert.match(tpl, /Amendments/, 'the logical template needs somewhere to record the correction');
});

test('stage 3 guards against encoding a lifecycle twice without a constraint', () => {
  // The trial design allowed status='DELIVERED' with sent_at IS NULL on the
  // hottest table in the system, and the self-review did not catch it.
  const s3 = readFileSync(join(SKILL, 'skills/03-logical-design/SKILL.md'), 'utf8');
  assert.match(s3, /hai lần/, 'stage 3 must warn about double-encoded lifecycles');
  assert.match(s3, /CHECK/, 'and require a CHECK that ties the representations together');
});

test('write-path and queue-claim guidance exists', () => {
  const idx = readFileSync(join(SKILL, 'references/indexing-and-performance.md'), 'utf8');
  assert.match(idx, /SKIP LOCKED/, 'a queue table without a claim mechanism is incorrect, not unoptimised');
  assert.match(idx, /UPDATE/, 'the write-path cost must be budgeted, not just read paths');

  const topo = readFileSync(join(SKILL, 'references/storage-topology.md'), 'utf8');
  assert.match(topo, /SKIP LOCKED/, 'topology reference must state the claim requirement');
  assert.match(topo, /enum/i, 'must give criteria for enum type vs lookup table');
});

test('stage 5 counts by machine before it grades itself', () => {
  const s5 = readFileSync(join(SKILL, 'skills/05-review-handoff/SKILL.md'), 'utf8');
  assert.match(s5, /check-design\.sh/, 'stage 5 must run the mechanical checker first');
  assert.match(s5, /05-app-enforced-rules\.md/, 'app-enforced rules need a handoff artifact');

  const chk = readFileSync(join(SKILL, 'references/review-checklist.md'), 'utf8');
  assert.match(chk, /## 9\./, 'the checklist needs the adversarial group that finds new defects');
  assert.match(chk, /đối kháng/, 'group 9 is the adversarial pass');
});

test('check-design.sh detects the defect classes the trial found by hand', () => {
  const s = readFileSync(join(SKILL, 'scripts', 'check-design.sh'), 'utf8');
  assert.match(s, /DN-/, 'must detect the D-*/DN-* namespace collision');
  assert.match(s, /DB \(planned\)/, 'must detect un-verified enforcement claims');
  assert.match(s, /timestamp/, 'must detect double-encoded lifecycles');
  assert.match(s, /05-app-enforced-rules/, 'must detect a missing app-enforced register');
  assert.match(s, /exit 1/, 'findings must be able to fail a gate');
});

test('validate-ddl.sh can prove constraints, not only syntax', () => {
  const s = readFileSync(join(SKILL, 'scripts', 'validate-ddl.sh'), 'utf8');
  assert.match(s, /--assert/, 'must be able to run business-rule assertions');
  assert.match(s, /exit 3/, 'a failing assertion needs its own exit code — it is worse than a syntax error');
  assert.match(s, /--report/, 'must be able to report constraint density and unindexed FKs');
  // A readiness probe that passes on initdb's temporary server makes an
  // infrastructure race look like a DDL defect.
  assert.match(s, /-d ddlcheck -c 'SELECT 1'/, 'readiness must probe the target database, not just the server');
});

test('the assertions template demands both directions', () => {
  const s = readFileSync(join(SKILL, 'templates/05-review/05-assertions.sql'), 'utf8');
  assert.match(s, /assert_rejects/, 'the violating case must be rejected');
  assert.match(s, /assert_accepts/, 'the legitimate near-miss must be accepted — this is the half that finds over-broad constraints');
});
