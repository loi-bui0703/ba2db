#!/usr/bin/env bash
# init-workspace.sh — tạo workspace cho một dự án thiết kế database.
#
# Usage: bash scripts/init-workspace.sh <project-slug> [dbms]
#
# Templates luôn lấy từ thư mục skill (cạnh script này). Workspace được tạo
# trong THƯ MỤC ĐANG LÀM VIỆC của người dùng, không phải trong thư mục skill —
# skill có thể nằm ở ~/.claude/skills/ba2db hoặc trong node_modules, ghi vào đó
# thì artifact nằm ngoài dự án và không được commit.
# Ghi đè đích bằng biến môi trường BA2DB_WORKSPACE_ROOT nếu cần.
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="${BA2DB_WORKSPACE_ROOT:-$PWD}"
SLUG="${1:-}"
DBMS="${2:-undecided}"   # KHÔNG mặc định engine — chốt ở Stage 1B

if [[ -z "$SLUG" ]]; then
  echo "Usage: bash scripts/init-workspace.sh <project-slug> [dbms]" >&2
  exit 1
fi

if [[ ! "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid slug: \"$SLUG\" — dùng chữ thường, số và dấu gạch ngang." >&2
  exit 1
fi

TEMPLATES="$SKILL_ROOT/templates"
if [[ ! -d "$TEMPLATES" ]]; then
  echo "Không tìm thấy templates tại $TEMPLATES" >&2
  exit 1
fi

DEST="$WORKSPACE_ROOT/workspace/$SLUG"
if [[ -e "$DEST" ]]; then
  echo "Workspace already exists: $DEST" >&2
  echo "Đọc $DEST/STATE.md để tiếp tục thay vì tạo lại." >&2
  exit 1
fi

mkdir -p "$DEST/ba-docs"

cp "$TEMPLATES/01-requirements/00-intake-report.md"     "$DEST/00-intake-report.md"
cp "$TEMPLATES/01-requirements/01-data-requirements.md" "$DEST/01-data-requirements.md"
cp "$TEMPLATES/01-requirements/01-glossary.md"          "$DEST/01-glossary.md"
cp "$TEMPLATES/01b-dbms/01b-dbms-decision.md"           "$DEST/01b-dbms-decision.md"
cp "$TEMPLATES/02-conceptual/02-conceptual-erd.md"      "$DEST/02-conceptual-erd.md"
cp "$TEMPLATES/03-logical/03-logical-schema.md"         "$DEST/03-logical-schema.md"
cp "$TEMPLATES/03-logical/03-data-dictionary.md"        "$DEST/03-data-dictionary.md"
cp "$TEMPLATES/04-physical/04-schema.sql"               "$DEST/04-schema.sql"
cp "$TEMPLATES/04-physical/04-index-plan.md"            "$DEST/04-index-plan.md"
cp "$TEMPLATES/04-physical/04-migration-notes.md"       "$DEST/04-migration-notes.md"
cp "$TEMPLATES/05-review/05-review-report.md"           "$DEST/05-review-report.md"
cp "$TEMPLATES/05-review/05-traceability-matrix.md"     "$DEST/05-traceability-matrix.md"
cp "$TEMPLATES/05-review/05-app-enforced-rules.md"     "$DEST/05-app-enforced-rules.md"
cp "$TEMPLATES/05-review/05-assertions.sql"            "$DEST/05-assertions.sql"

cat > "$DEST/STATE.md" <<STATE
# STATE
project: $SLUG
dbms: $DBMS
dbms_status: undecided   # undecided | provisional | decided (Stage 1B)
stage_done: -1
next: 00-intake
open_questions: 0
updated: $(date +%F)

## Log
- $(date +%F) workspace initialized

## Amendments
<!-- Stage sau chứng minh một khẳng định của stage trước là sai thì ghi một dòng
     ở đây VÀ sửa artifact gốc. Để hai artifact nói khác nhau là bàn giao một
     khẳng định sai. Ví dụ:
- 2026-09-20 BR-014: DB (planned) -> app (unique toàn cục không ép được trên bảng partition) -->
STATE

cat > "$DEST/README.md" <<README
# $SLUG — Database Design

Đọc theo thứ tự / Read in order:

1. \`00-intake-report.md\` — phạm vi & tài liệu nguồn
2. \`01-data-requirements.md\` + \`01-glossary.md\` — yêu cầu dữ liệu đã trích xuất
3. \`01b-dbms-decision.md\` — quyết định hệ quản trị (ADR)
4. \`02-conceptual-erd.md\` — mô hình khái niệm
5. \`03-logical-schema.md\` + \`03-data-dictionary.md\` — lược đồ logic
6. \`04-schema.sql\` + \`04-index-plan.md\` + \`04-migration-notes.md\` — thiết kế vật lý
7. \`05-review-report.md\` + \`05-traceability-matrix.md\` + \`05-app-enforced-rules.md\` — nghiệm thu

Kiểm tra bằng máy trước khi nghiệm thu:
\`\`\`
bash scripts/check-design.sh workspace/$SLUG
bash scripts/validate-ddl.sh workspace/$SLUG/04-schema.sql <engine> \\
  --assert workspace/$SLUG/05-assertions.sql --report
\`\`\`

Tài liệu BA gốc đặt trong \`ba-docs/\`. Trạng thái tiến độ: \`STATE.md\`.
README

echo "Created: $DEST"
echo "Đặt tài liệu BA vào $DEST/ba-docs/ rồi bắt đầu từ skills/00-intake/SKILL.md"
