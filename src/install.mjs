/** install / uninstall / list — the actual work behind the CLI verbs. */
import { existsSync, readFileSync } from 'node:fs';
import { isAbsolute, join, relative, resolve } from 'node:path';
import { getHost, HOSTS, SIDECAR_DIR, SKILL_NAME } from './hosts.mjs';
import { RULES, MARKER } from './rules.mjs';
import { appendBlock, copyDir, remove, removeBlock, writeFile } from './fsutil.mjs';

/**
 * @param {object} o
 * @param {string} o.hostId
 * @param {'global'|'project'} o.scope
 * @param {string} o.skillSrc  absolute path to the packaged skill/ directory
 * @param {string} o.cwd
 * @param {boolean} o.force
 * @returns {{actions: string[], skillPath: string, verify: string}}
 */
export function install({ hostId, scope, skillSrc, cwd = process.cwd(), force = false }) {
  const host = getHost(hostId);
  if (!host) throw new Error(`Unknown host: ${hostId}`);

  const target = host.target[scope];
  if (!target) {
    throw new Error(
      `${host.label} does not support ${scope} installs — use --project (it is configured per repository).`
    );
  }
  const abs = (p) => (isAbsolute(p) ? p : resolve(cwd, p));
  const actions = [];

  // 1. Place the skill body.
  let skillPath;
  if (host.kind === 'copy') {
    skillPath = abs(target);
    copyDir(skillSrc, skillPath, { force });
    actions.push(`skill → ${skillPath}`);
  } else {
    // Rule-based and manual hosts get the skill in a sidecar directory,
    // and a short rule file that points at it.
    skillPath = abs(scope === 'global' ? join(process.env.HOME || '.', SIDECAR_DIR) : SIDECAR_DIR);
    copyDir(skillSrc, skillPath, { force });
    actions.push(`skill → ${skillPath}`);
  }

  // 2. Wire the host up to it.
  if (host.kind === 'rule') {
    const rulePath = abs(target);
    const pointer = relative(cwd, skillPath) || skillPath;
    const body = RULES[host.id](pointer);
    if (host.append) {
      const how = appendBlock(rulePath, body, MARKER);
      actions.push(`rule  → ${rulePath} (${how})`);
    } else {
      if (existsSync(rulePath) && !force) {
        throw Object.assign(new Error(`Rule file already exists: ${rulePath}`), {
          code: 'EEXISTS_TARGET',
        });
      }
      writeFile(rulePath, body);
      actions.push(`rule  → ${rulePath}`);
    }
  }

  return { actions, skillPath, verify: host.verify };
}

export function uninstall({ hostId, scope, cwd = process.cwd() }) {
  const host = getHost(hostId);
  if (!host) throw new Error(`Unknown host: ${hostId}`);
  const abs = (p) => (isAbsolute(p) ? p : resolve(cwd, p));
  const removed = [];
  const target = host.target[scope];
  if (!target) return removed;

  if (host.kind === 'copy') {
    if (remove(abs(target))) removed.push(abs(target));
  } else {
    const rulePath = abs(target);
    if (host.append) {
      if (removeBlock(rulePath, MARKER)) removed.push(`${rulePath} (ba2db block)`);
    } else if (remove(rulePath)) {
      removed.push(rulePath);
    }
    const sidecar = abs(scope === 'global' ? join(process.env.HOME || '.', SIDECAR_DIR) : SIDECAR_DIR);
    if (remove(sidecar)) removed.push(sidecar);
  }
  return removed;
}

/** Everywhere this machine currently has ba2db installed. */
export function listInstalls({ cwd = process.cwd() } = {}) {
  const out = [];
  const abs = (p) => (isAbsolute(p) ? p : resolve(cwd, p));

  for (const host of HOSTS) {
    for (const scope of ['global', 'project']) {
      const target = host.target[scope];
      if (!target) continue;
      const path = abs(target);
      if (!existsSync(path)) continue;

      // For hosts we append into, the file existing proves nothing —
      // check that our own marker block is really in there.
      if (host.append) {
        const content = readFileSync(path, 'utf8');
        if (!content.includes(`<!-- ${MARKER}:begin -->`)) continue;
      }
      out.push({ host: host.label, scope, path, kind: host.kind });
    }
  }
  return out;
}

export { SKILL_NAME, SIDECAR_DIR };
