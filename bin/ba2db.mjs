#!/usr/bin/env node
/**
 * ba2db — install the BA-to-database-design skill into your agent.
 *
 * Zero runtime dependencies by design: this package writes files into the
 * user's home and repo, so its supply chain is kept at exactly zero.
 */
import { createInterface } from 'node:readline/promises';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { stdin, stdout } from 'node:process';

import { HOSTS, getHost, SIDECAR_DIR } from '../src/hosts.mjs';
import { detectHosts } from '../src/detect.mjs';
import { install, uninstall, listInstalls } from '../src/install.mjs';
import { PROMPT } from '../src/rules.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SKILL_SRC = join(ROOT, 'skill');
const VERSION = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8')).version;

const C = process.env.NO_COLOR || !stdout.isTTY
  ? new Proxy({}, { get: () => (s) => s })
  : {
      b: (s) => `\x1b[1m${s}\x1b[0m`,
      dim: (s) => `\x1b[2m${s}\x1b[0m`,
      green: (s) => `\x1b[32m${s}\x1b[0m`,
      red: (s) => `\x1b[31m${s}\x1b[0m`,
      yellow: (s) => `\x1b[33m${s}\x1b[0m`,
      cyan: (s) => `\x1b[36m${s}\x1b[0m`,
    };

const HELP = `${C.b('ba2db')} ${C.dim(`v${VERSION}`)} — BA documents → database design, as an agent skill

${C.b('USAGE')}
  npx ba2db <command> [options]

${C.b('COMMANDS')}
  install        Install the skill into a detected agent host
  uninstall      Remove the skill from a host
  list           Show where ba2db is currently installed
  doctor         Verify an installation is complete and intact
  init <slug>    Create a design workspace for a new project
  prompt         Print the copy-paste prompt (for agents without file access)
  hosts          List supported agent hosts

${C.b('OPTIONS')}
  --host <id>    claude-code | cursor | codex | copilot | opencode | generic
  --global       Install for the current user (default where supported)
  --project      Install into the current repository
  --force        Overwrite an existing installation
  -y, --yes      Non-interactive; accept detected defaults
  -h, --help     Show this help
  -v, --version  Show version

${C.b('EXAMPLES')}
  npx ba2db install                          ${C.dim('# detect host, ask, install')}
  npx ba2db install --host claude-code --global -y
  npx ba2db init my-project                  ${C.dim('# scaffold a design workspace')}
  npx ba2db doctor

${C.dim('Docs: https://github.com/loi-bui0703/ba2db')}
`;

function parseArgs(argv) {
  const args = { _: [], flags: {} };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') args.flags.help = true;
    else if (a === '-v' || a === '--version') args.flags.version = true;
    else if (a === '-y' || a === '--yes') args.flags.yes = true;
    else if (a === '--force') args.flags.force = true;
    else if (a === '--global') args.flags.scope = 'global';
    else if (a === '--project') args.flags.scope = 'project';
    else if (a === '--host') args.flags.host = argv[++i];
    else if (a.startsWith('--host=')) args.flags.host = a.slice(7);
    else if (a.startsWith('-')) throw new Error(`Unknown option: ${a}`);
    else args._.push(a);
  }
  return args;
}

async function ask(question, choices, { yes, fallback }) {
  if (yes) return fallback;
  const rl = createInterface({ input: stdin, output: stdout });
  try {
    console.log(`\n${C.b(question)}`);
    choices.forEach((c, i) => {
      const mark = c.value === fallback ? C.green('●') : '○';
      console.log(`  ${mark} ${i + 1}) ${c.label}${c.hint ? C.dim(`  ${c.hint}`) : ''}`);
    });
    const answer = (await rl.question(C.dim(`Choose [1-${choices.length}] (default: ${fallback}): `))).trim();
    if (!answer) return fallback;
    const idx = Number(answer) - 1;
    if (Number.isInteger(idx) && choices[idx]) return choices[idx].value;
    const byValue = choices.find((c) => c.value === answer);
    if (byValue) return byValue.value;
    console.log(C.yellow(`Not a valid choice — using default: ${fallback}`));
    return fallback;
  } finally {
    rl.close();
  }
}

async function cmdInstall(flags) {
  console.log(`${C.b('ba2db')} ${C.dim(`v${VERSION}`)}\n`);

  const detected = detectHosts();
  let hostId = flags.host;

  if (!hostId) {
    if (detected.length === 0) {
      console.log(C.yellow('No known agent host detected in this directory or your home folder.'));
      console.log(C.dim('Falling back to a manual install — see `npx ba2db prompt`.\n'));
      hostId = 'generic';
    } else {
      console.log('Detected:');
      for (const d of detected) console.log(`  ${C.green('✓')} ${d.label} ${C.dim(d.evidence)}`);
      hostId = await ask(
        'Which host do you want to install into?',
        HOSTS.filter((h) => detected.some((d) => d.id === h.id) || h.id === 'generic').map((h) => ({
          label: h.label,
          value: h.id,
        })),
        { yes: flags.yes, fallback: detected[0].id }
      );
    }
  }

  const host = getHost(hostId);
  if (!host) {
    console.error(C.red(`Unknown host: ${hostId}`));
    console.error(C.dim(`Known hosts: ${HOSTS.map((h) => h.id).join(', ')}`));
    process.exitCode = 1;
    return;
  }

  let scope = flags.scope;
  if (!scope) {
    const available = ['global', 'project'].filter((s) => host.target[s]);
    scope =
      available.length === 1
        ? available[0]
        : await ask(
            'Install scope?',
            [
              { label: 'Global — available in every project', value: 'global', hint: `${host.target.global ?? ''}` },
              { label: 'Project — this repository only', value: 'project', hint: `${host.target.project ?? ''}` },
            ].filter((c) => host.target[c.value]),
            { yes: flags.yes, fallback: available[0] }
          );
  }

  try {
    const { actions, skillPath, verify } = install({
      hostId,
      scope,
      skillSrc: SKILL_SRC,
      force: flags.force,
    });
    console.log(`\n${C.green('✓')} Installed ${C.b('ba2db')} for ${C.b(host.label)} (${scope})`);
    for (const a of actions) console.log(`  ${C.dim(a)}`);
    console.log(`\n${C.b('Try it:')} ${verify}`);
    if (host.kind === 'manual') console.log(`\n${PROMPT(skillPath)}`);
    console.log(C.dim(`\nScaffold a project workspace with:  npx ba2db init <slug>`));
  } catch (err) {
    if (err.code === 'EEXISTS_TARGET') {
      console.error(`\n${C.red('✗')} ${err.message}`);
      console.error(C.dim('Re-run with --force to overwrite, or `npx ba2db uninstall` first.'));
      process.exitCode = 1;
      return;
    }
    throw err;
  }
}

async function cmdUninstall(flags) {
  const hostId = flags.host;
  if (!hostId) {
    const installs = listInstalls();
    if (installs.length === 0) {
      console.log('Nothing to uninstall — ba2db is not installed here.');
      return;
    }
    console.log('Currently installed:');
    for (const i of installs) console.log(`  ${i.host} (${i.scope}) ${C.dim(i.path)}`);
    console.log(C.dim('\nRe-run with --host <id> [--global|--project] to remove one.'));
    return;
  }
  const scope = flags.scope || 'global';
  const removed = uninstall({ hostId, scope });
  if (removed.length === 0) {
    console.log(`Nothing removed — no ${hostId} (${scope}) installation found.`);
    return;
  }
  console.log(`${C.green('✓')} Removed:`);
  for (const r of removed) console.log(`  ${C.dim(r)}`);
}

function cmdList() {
  const installs = listInstalls();
  if (installs.length === 0) {
    console.log('ba2db is not installed in this directory or your home folder.');
    console.log(C.dim('Install with: npx ba2db install'));
    return;
  }
  console.log(C.b('ba2db installations\n'));
  for (const i of installs) {
    console.log(`  ${C.green('●')} ${C.b(i.host)} ${C.dim(`(${i.scope})`)}`);
    console.log(`    ${C.dim(i.path)}`);
  }
}

function cmdDoctor() {
  console.log(`${C.b('ba2db doctor')} ${C.dim(`v${VERSION}`)}\n`);
  const required = [
    'SKILL.md',
    'skills/00-intake/SKILL.md',
    'skills/01-requirements-extraction/SKILL.md',
    'skills/02-conceptual-model/SKILL.md',
    'skills/03-logical-design/SKILL.md',
    'skills/04-physical-design/SKILL.md',
    'skills/05-review-handoff/SKILL.md',
    'references/extraction-checklist.md',
    'references/naming-conventions.md',
    'references/normalization.md',
    'references/modeling-patterns.md',
    'references/anti-patterns.md',
    'references/indexing-and-performance.md',
    'references/dbms-notes.md',
    'references/review-checklist.md',
    'templates/01-requirements/01-data-requirements.md',
    'templates/02-conceptual/02-conceptual-erd.md',
    'templates/03-logical/03-logical-schema.md',
    'templates/03-logical/03-data-dictionary.md',
    'templates/04-physical/04-schema.sql',
    'templates/05-review/05-review-report.md',
    'templates/05-review/05-traceability-matrix.md',
    'scripts/init-workspace.sh',
  ];

  let failed = 0;
  const check = (label, ok, detail = '') => {
    console.log(`  ${ok ? C.green('✓') : C.red('✗')} ${label}${detail ? C.dim(`  ${detail}`) : ''}`);
    if (!ok) failed++;
  };

  console.log(C.b('Package'));
  check('skill/ directory present', existsSync(SKILL_SRC), SKILL_SRC);
  const missing = required.filter((f) => !existsSync(join(SKILL_SRC, f)));
  check(`${required.length} skill files intact`, missing.length === 0, missing.length ? `missing: ${missing[0]}${missing.length > 1 ? ` (+${missing.length - 1})` : ''}` : '');

  console.log(`\n${C.b('Installations')}`);
  const installs = listInstalls();
  if (installs.length === 0) {
    console.log(`  ${C.yellow('!')} none found ${C.dim('(run: npx ba2db install)')}`);
  } else {
    for (const i of installs) {
      const intact = i.kind !== 'copy' || existsSync(join(i.path, 'SKILL.md'));
      check(`${i.host} (${i.scope})`, intact, i.path);
    }
  }

  console.log(`\n${failed === 0 ? C.green('All checks passed.') : C.red(`${failed} check(s) failed.`)}`);
  if (failed > 0) process.exitCode = 1;
}

async function cmdInit(slug, flags) {
  if (!slug) {
    console.error(C.red('Usage: npx ba2db init <project-slug>'));
    process.exitCode = 1;
    return;
  }
  if (!/^[a-z0-9][a-z0-9-]*$/.test(slug)) {
    console.error(C.red(`Invalid slug: "${slug}" — use lowercase letters, digits and hyphens.`));
    process.exitCode = 1;
    return;
  }
  const { spawnSync } = await import('node:child_process');
  const script = join(SKILL_SRC, 'scripts', 'init-workspace.sh');
  const res = spawnSync('bash', [script, slug, flags.dbms || 'postgresql-16'], { stdio: 'inherit' });
  if (res.status !== 0) process.exitCode = res.status ?? 1;
}

function cmdHosts() {
  const detected = detectHosts().map((d) => d.id);
  console.log(C.b('Supported hosts\n'));
  for (const h of HOSTS) {
    const mark = detected.includes(h.id) ? C.green('●') : C.dim('○');
    console.log(`  ${mark} ${C.b(h.id.padEnd(14))} ${h.label}`);
    const scopes = ['global', 'project'].filter((s) => h.target[s]).join(', ');
    console.log(`    ${C.dim(`scopes: ${scopes} · install: ${h.kind}`)}`);
  }
  console.log(C.dim(`\n● = detected on this machine.  Docs: docs/hosts/`));
}

async function main() {
  let args;
  try {
    args = parseArgs(process.argv.slice(2));
  } catch (err) {
    console.error(C.red(err.message));
    console.error(C.dim('Run `npx ba2db --help` for usage.'));
    process.exitCode = 1;
    return;
  }

  if (args.flags.version) return void console.log(VERSION);
  const cmd = args._[0];
  if (args.flags.help || !cmd) return void console.log(HELP);

  switch (cmd) {
    case 'install': return cmdInstall(args.flags);
    case 'uninstall': return cmdUninstall(args.flags);
    case 'list': return cmdList();
    case 'doctor': return cmdDoctor();
    case 'init': return cmdInit(args._[1], args.flags);
    case 'prompt': return void console.log(PROMPT(SIDECAR_DIR));
    case 'hosts': return cmdHosts();
    default:
      console.error(C.red(`Unknown command: ${cmd}`));
      console.error(C.dim('Run `npx ba2db --help` for usage.'));
      process.exitCode = 1;
  }
}

main().catch((err) => {
  console.error(C.red(`\n✗ ${err.message}`));
  if (process.env.DEBUG) console.error(err.stack);
  process.exitCode = 1;
});
