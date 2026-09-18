#!/usr/bin/env bash
# check-structure.sh — kiểm tra bộ skill còn đủ file sau khi chỉnh sửa.
#
# Danh sách file lấy từ skill/MANIFEST — cùng một nguồn với `ba2db doctor`,
# để hai lệnh không bao giờ bất đồng về việc thế nào là "đầy đủ".
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/MANIFEST"

if [[ ! -f "$MANIFEST" ]]; then
  echo "MISSING: MANIFEST — không biết skill cần những file nào." >&2
  exit 1
fi

missing=0
total=0
while IFS= read -r f || [[ -n "$f" ]]; do
  f="${f%%#*}"                       # bỏ comment
  f="$(echo "$f" | xargs)"           # trim
  [[ -z "$f" ]] && continue
  total=$((total + 1))
  [[ -e "$ROOT/$f" ]] || { echo "MISSING: $f"; missing=$((missing + 1)); }
done < "$MANIFEST"

if [[ $missing -eq 0 ]]; then
  echo "OK: structure complete ($total files)."
else
  echo "$missing of $total file(s) missing." >&2
  exit 1
fi
