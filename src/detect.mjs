/** Host detection — pure filesystem probing, no network, no guessing. */
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { HOSTS } from './hosts.mjs';

/**
 * @param {string} cwd
 * @returns {{id: string, label: string, evidence: string}[]}
 */
export function detectHosts(cwd = process.cwd()) {
  const found = [];
  for (const host of HOSTS) {
    if (host.kind === 'manual') continue;
    for (const probe of host.detect) {
      const path = probe.startsWith('/') ? probe : resolve(cwd, probe);
      if (existsSync(path)) {
        found.push({ id: host.id, label: host.label, evidence: path });
        break;
      }
    }
  }
  return found;
}
