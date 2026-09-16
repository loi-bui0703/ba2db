#!/usr/bin/env node
/** Minimal zero-dependency test runner. Node's built-in test runner needs
 *  no extra packages, but this keeps output readable in CI logs too. */
import { run } from 'node:test';
import { tap } from 'node:test/reporters';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readdirSync } from 'node:fs';

const here = dirname(fileURLToPath(import.meta.url));
const files = readdirSync(here)
  .filter((f) => f.endsWith('.test.mjs'))
  .map((f) => join(here, f));

let failed = 0;
run({ files, concurrency: 1 })
  .on('test:fail', () => { failed++; })
  .compose(tap)
  .pipe(process.stdout)
  .on('finish', () => { process.exitCode = failed > 0 ? 1 : 0; });
