#!/usr/bin/env bash
# check-structure.sh — kiểm tra bộ skill còn đủ file sau khi chỉnh sửa.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
missing=0
while read -r f; do
  [[ -e "$ROOT/$f" ]] || { echo "MISSING: $f"; missing=1; }
done <<'LIST'
SKILL.md
skills/00-intake/SKILL.md
skills/01-requirements-extraction/SKILL.md
skills/02-conceptual-model/SKILL.md
skills/03-logical-design/SKILL.md
skills/04-physical-design/SKILL.md
skills/05-review-handoff/SKILL.md
references/extraction-checklist.md
references/naming-conventions.md
references/normalization.md
references/modeling-patterns.md
references/anti-patterns.md
references/indexing-and-performance.md
references/dbms-notes.md
references/review-checklist.md
templates/01-requirements/00-intake-report.md
templates/01-requirements/01-data-requirements.md
templates/01-requirements/01-glossary.md
templates/02-conceptual/02-conceptual-erd.md
templates/03-logical/03-logical-schema.md
templates/03-logical/03-data-dictionary.md
templates/04-physical/04-schema.sql
templates/04-physical/04-index-plan.md
templates/04-physical/04-migration-notes.md
templates/05-review/05-review-report.md
templates/05-review/05-traceability-matrix.md
scripts/init-workspace.sh
agents/README.md
LIST
[[ $missing -eq 0 ]] && echo "OK: structure complete." || exit 1
