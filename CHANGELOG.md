# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because this package is mostly instructions rather than code, we version it by
**behavioural impact on generated designs**:

- **MAJOR** — the workflow changes shape (stages added/removed/reordered), or
  existing workspaces are no longer compatible.
- **MINOR** — new references, templates, hosts, or CLI commands; output gets
  richer but existing artifacts stay valid.
- **PATCH** — wording, fixes, documentation.

## [Unreleased]

## [1.0.0] — 2026-09-16

First public release.

### Added

- Six-stage workflow: intake → requirements extraction → conceptual model →
  logical design → physical design → review & handoff, each with its own
  `SKILL.md` and a confirmation gate.
- Nine extraction sections (`BC/EN/AT/RL/BR/PR/VP/NF/XX`) with stable IDs, plus
  a three-pass reading method (open sweep → checklist classify → challenge).
- Two-way traceability matrix: uncovered requirements and unjustified schema
  objects are both reported as defects.
- Eight reference documents: extraction checklist, naming conventions,
  normalization, modeling patterns, anti-patterns, indexing and performance,
  DBMS dialect notes, review checklist.
- Eleven bilingual (EN/VI) artifact templates.
- Zero-dependency CLI: `install`, `uninstall`, `list`, `doctor`, `init`,
  `prompt`, `hosts`.
- Host support: Claude Code, Cursor, Codex/AGENTS.md, GitHub Copilot, OpenCode,
  and a manual mode for any other agent.
- `install.sh` for users without Node.
- Test suite (21 tests) covering skill integrity, frontmatter validity,
  dangling references, and non-destructive install/uninstall.
- CI across Node 18/20/22 on Linux, macOS and Windows.

[Unreleased]: https://github.com/loi-bui0703/ba2db/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/loi-bui0703/ba2db/releases/tag/v1.0.0
