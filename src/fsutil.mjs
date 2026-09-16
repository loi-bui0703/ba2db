/** Small filesystem helpers. Node builtins only — this package has zero deps. */
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, statSync } from 'node:fs';
import { dirname } from 'node:path';

export function copyDir(from, to, { force = false } = {}) {
  if (existsSync(to) && !force) {
    const err = new Error(`Target already exists: ${to}`);
    err.code = 'EEXISTS_TARGET';
    throw err;
  }
  if (existsSync(to)) rmSync(to, { recursive: true, force: true });
  mkdirSync(dirname(to), { recursive: true });
  cpSync(from, to, { recursive: true });
}

export function writeFile(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content, 'utf8');
}

/**
 * Append a block to a file exactly once, delimited by markers so that
 * `uninstall` can remove it again without touching the user's own content.
 */
export function appendBlock(path, block, marker) {
  const begin = `<!-- ${marker}:begin -->`;
  const end = `<!-- ${marker}:end -->`;
  const payload = `${begin}\n${block.trim()}\n${end}\n`;
  const existing = existsSync(path) ? readFileSync(path, 'utf8') : '';

  if (existing.includes(begin)) {
    const re = new RegExp(`${escapeRe(begin)}[\\s\\S]*?${escapeRe(end)}\\n?`);
    writeFile(path, existing.replace(re, payload));
    return 'updated';
  }
  const sep = existing && !existing.endsWith('\n\n') ? '\n\n' : '';
  writeFile(path, `${existing}${sep}${payload}`);
  return existing ? 'appended' : 'created';
}

export function removeBlock(path, marker) {
  if (!existsSync(path)) return false;
  const begin = `<!-- ${marker}:begin -->`;
  const end = `<!-- ${marker}:end -->`;
  const content = readFileSync(path, 'utf8');
  if (!content.includes(begin)) return false;
  const re = new RegExp(`\\n*${escapeRe(begin)}[\\s\\S]*?${escapeRe(end)}\\n?`);
  writeFile(path, content.replace(re, '\n').replace(/\n{3,}/g, '\n\n'));
  return true;
}

export function remove(path) {
  if (!existsSync(path)) return false;
  rmSync(path, { recursive: true, force: true });
  return true;
}

export const isDir = (p) => existsSync(p) && statSync(p).isDirectory();

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
