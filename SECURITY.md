# Security Policy

## Scope

`ba2db` is a skill package: Markdown instructions plus a small zero-dependency
Node CLI and a shell installer. It has **no runtime service, no network calls,
and no telemetry**. The security surface is therefore narrow but not empty:

| Surface | Risk |
|---|---|
| `bin/ba2db.mjs`, `install.sh` | Write files into `$HOME` and the current repo |
| `skill/scripts/validate-ddl.sh` | Creates and drops a temporary local database |
| Skill instructions | Influence what an AI agent does on the user's machine |

## Supported versions

| Version | Supported |
|---|---|
| 1.x | ✅ |
| < 1.0 | ❌ |

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

Use GitHub's private vulnerability reporting:
*Security → Report a vulnerability* on this repository.

Include what an attacker could achieve and the minimal steps to reproduce.
We aim to acknowledge within 7 days.

## What we consider a vulnerability

- Path traversal or arbitrary file write via a CLI argument
- The installer overwriting user files outside its documented targets
- Skill instructions that could lead an agent to exfiltrate data, run
  destructive commands, or commit secrets
- Supply chain: this package declares **zero dependencies**; any dependency
  appearing in `package.json` without discussion is a security issue

## What we do not consider a vulnerability

- An AI agent producing a poor database design (that is a quality issue —
  please file it as one, it is still very welcome)
- `validate-ddl.sh` requiring local database credentials that the user supplies

## Note for users

This package installs instructions that an AI agent will follow. Review the
contents of `skill/` before installing it into an agent that has write access
to systems you care about — the same care you would apply to any other
agent configuration.
