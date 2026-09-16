#!/usr/bin/env bash
# init-workspace.sh — tạo workspace cho một dự án thiết kế database.
# Usage: bash scripts/init-workspace.sh <project-slug> [dbms]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="${1:-}"
DBMS="${2:-postgresql-16}"

if [[ -z "$SLUG" ]]; then
  echo "Usage: bash scripts/init-workspace.sh <project-slug> [dbms]" >&2
  exit 1
fi

DEST="$ROOT/workspace/$SLUG"
if [[ -e "$DEST" ]]; then
  echo "Workspace already exists: $DEST" >&2
  echo "Đọc $DEST/STATE.md để tiếp tục thay vì tạo lại." >&2
  exit 1
fi

mkdir -p "$DEST/ba-docs"

cp "$ROOT/templates/01-requirements/00-intake-report.md"   "$DEST/00-intake-report.md"
cp "$ROOT/templates/01-requirements/01-data-requirements.md" "$DEST/01-data-requirements.md"
cp "$ROOT/templates/01-requirements/01-glossary.md"        "$DEST/01-glossary.md"
cp "$ROOT/templates/02-conceptual/02-conceptual-erd.md"    "$DEST/02-conceptual-erd.md"
cp "$ROOT/templates/03-logical/03-logical-schema.md"       "$DEST/03-logical-schema.md"
cp "$ROOT/templates/03-logical/03-data-dictionary.md"      "$DEST/03-data-dictionary.md"
cp "$ROOT/templates/04-physical/04-schema.sql"             "$DEST/04-schema.sql"
cp "$ROOT/templates/04-physical/04-index-plan.md"          "$DEST/04-index-plan.md"
cp "$ROOT/templates/04-physical/04-migration-notes.md"     "$DEST/04-migration-notes.md"
cp "$ROOT/templates/05-review/05-review-report.md"         "$DEST/05-review-report.md"
cp "$ROOT/templates/05-review/05-traceability-matrix.md"   "$DEST/05-traceability-matrix.md"

cat > "$DEST/STATE.md" <<STATE
# STATE
project: $SLUG
dbms: $DBMS
stage_done: -1
next: 00-intake
open_questions: 0
updated: $(date +%F)

## Log
- $(date +%F) workspace initialized
STATE

cat > "$DEST/README.md" <<README
# $SLUG — Database Design

Đọc theo thứ tự / Read in order:

1. \`00-intake-report.md\` — phạm vi & tài liệu nguồn
2. \`01-data-requirements.md\` + \`01-glossary.md\` — yêu cầu dữ liệu đã trích xuất
3. \`02-conceptual-erd.md\` — mô hình khái niệm
4. \`03-logical-schema.md\` + \`03-data-dictionary.md\` — lược đồ logic
5. \`04-schema.sql\` + \`04-index-plan.md\` + \`04-migration-notes.md\` — thiết kế vật lý
6. \`05-review-report.md\` + \`05-traceability-matrix.md\` — nghiệm thu

Tài liệu BA gốc đặt trong \`ba-docs/\`. Trạng thái tiến độ: \`STATE.md\`.
README

echo "Created: $DEST"
echo "Đặt tài liệu BA vào $DEST/ba-docs/ rồi bắt đầu từ skills/00-intake/SKILL.md"
