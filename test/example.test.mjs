/** The example is documentation that rots silently. These tests keep it honest. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const EX = join(dirname(fileURLToPath(import.meta.url)), '..', 'examples', 'ecommerce-mini');
const read = (f) => readFileSync(join(EX, f), 'utf8');

test('example contains every artifact the workflow promises', () => {
  for (const f of [
    'README.md',
    'ba-docs/BA-01-sales.md',
    '01-data-requirements.md',
    '02-conceptual-erd.md',
    '03-logical-schema.md',
    '04-schema.sql',
    '04-index-plan.md',
    '05-review-report.md',
    '05-traceability-matrix.md',
  ]) {
    assert.ok(existsSync(join(EX, f)), `missing example artifact: ${f}`);
  }
});

test('example is filled in, not a copy of the blank templates', () => {
  const req = read('01-data-requirements.md');
  assert.doesNotMatch(req, /<project-slug>|<slug>/, 'placeholders left in the example');
  assert.match(req, /BA-01 §/, 'example must show real source citations');
});

test('example demonstrates uncertainty rather than hiding it', () => {
  const req = read('01-data-requirements.md');
  assert.match(req, /OPEN QUESTIONS/, 'must show open questions');
  assert.match(req, /CONFLICTS/, 'must show a conflict between documents');
  assert.match(req, /Confidence: (low|medium)|\*\*medium\*\*|\*\*low\*\*/, 'must show a non-high confidence entry');
  assert.match(req, /XX-00/, 'must show an S9 unclassified finding');
});

test('example review reports its own validation status truthfully', () => {
  const review = read('05-review-report.md');
  assert.match(review, /NOT DONE|not been run/, 'must state whether the DDL was actually executed');
});

test('example traceability covers both directions', () => {
  const tm = read('05-traceability-matrix.md');
  assert.match(tm, /Forward/, 'forward trace missing');
  assert.match(tm, /Backward/, 'backward trace missing');
});

test('example DDL obeys the rules the skill enforces', () => {
  const sql = read('04-schema.sql');
  assert.doesNotMatch(sql, /\b(float|double precision|real)\b/i, 'money must never be float');
  assert.match(sql, /numeric\(19,4\)/, 'money should be numeric(19,4)');
  assert.match(sql, /timestamptz/, 'timestamps must be timezone-aware');
  assert.doesNotMatch(sql, /[àáâãèéêìíòóôõùúăđĩũơưăạảấầẩẫậắằẳẵặẹẻẽềềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹý]\w*\s+(varchar|bigint|numeric|text)/i,
    'identifiers must be English');
  // Every constraint is named — anonymous constraints produce unreadable errors.
  const anonymous = sql.match(/^\s+(PRIMARY KEY|FOREIGN KEY|UNIQUE|CHECK)\s/gm);
  assert.equal(anonymous, null, `unnamed constraints found: ${anonymous}`);
});

test('example DDL cites the requirement IDs it implements', () => {
  const sql = read('04-schema.sql');
  for (const id of ['BR-001', 'BR-002', 'BR-004', 'BR-005', 'VP-010', 'NF-002']) {
    assert.match(sql, new RegExp(id), `DDL never mentions ${id}`);
  }
});
