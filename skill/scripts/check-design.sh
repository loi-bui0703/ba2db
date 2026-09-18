#!/usr/bin/env bash
# check-design.sh — đếm và đối chiếu bộ artifact bằng máy, làm đầu vào cho Stage 5.
#
# Lý do tồn tại: tự review có trần năng lực. Hai loại lỗi lọt qua review của
# agent một cách có hệ thống, và cả hai chỉ lộ ra khi ĐẾM:
#   * con số tự khai (số requirement, số bảng) không khớp nội dung thật;
#   * hai artifact của hai stage nói khác nhau về cùng một điều.
#
# Usage:
#   bash scripts/check-design.sh <workspace/project-dir> [--warn-only]
#
# Exit codes:
#   0  không có lỗi (có thể còn cảnh báo)
#   1  có ít nhất một lỗi (ERROR)
#   2  không tìm thấy workspace
set -uo pipefail

WS="${1:-}"; WARN_ONLY=0
[[ "${2:-}" == "--warn-only" ]] && WARN_ONLY=1
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "Usage: bash scripts/check-design.sh <workspace/project-dir> [--warn-only]" >&2
  exit 2
fi
WS="${WS%/}"

errors=0; warns=0
err()  { echo "  ✗ ERROR  $*"; errors=$((errors + 1)); }
warn() { echo "  ! WARN   $*"; warns=$((warns + 1)); }
ok()   { echo "  ✓ $*"; }
sec()  { echo ""; echo "── $* ────────────────────────────────"; }

has() { [[ -f "$WS/$1" ]]; }
mds() { find "$WS" -maxdepth 1 -name '*.md' -print 2>/dev/null; }

# Một artifact còn nguyên placeholder của template thì chưa có nội dung để đối
# chiếu. Báo lỗi trên nó là tiếng ồn, và tiếng ồn làm người ta bỏ qua cả công cụ.
is_template() {
  [[ -f "$WS/$1" ]] && grep -qE '<slug>|<project-slug>|<dbms>|<engine \+ version>|<PROJECT NAME>' "$WS/$1" 2>/dev/null
}
filled() { has "$1" && ! is_template "$1"; }

SQL="$WS/04-schema.sql"
L3="$WS/03-logical-schema.md"

echo "check-design: $WS"

# ---------------------------------------------------------------------
sec "1. Artifact inventory"
# ---------------------------------------------------------------------
for f in 00-intake-report.md 01-data-requirements.md 01b-dbms-decision.md \
         02-conceptual-erd.md 03-logical-schema.md 03-data-dictionary.md \
         04-schema.sql 04-index-plan.md 04-migration-notes.md \
         05-review-report.md 05-traceability-matrix.md 05-app-enforced-rules.md; do
  if filled "$f"; then ok "$f"
  elif has "$f";   then warn "$f — còn là template chưa điền"
  else                  warn "thiếu $f (bình thường nếu chưa tới stage đó)"
  fi
done

# ---------------------------------------------------------------------
sec "2. Placeholder còn sót"
# ---------------------------------------------------------------------
left=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if grep -qE '<project-slug>|<YYYY-MM-DD>|<slug>|`<ai' "$f" 2>/dev/null; then
    warn "$(basename "$f") còn là template chưa điền (các mục kiểm tra nội dung bên dưới bỏ qua nó)"
    left=$((left + 1))
  fi
done < <(mds)
if [[ $left -eq 0 ]]; then
  ok "không còn placeholder của template"
else
  echo "           ⇒ $left artifact chưa điền. Chạy lại sau khi hoàn thành các stage đó."
fi

# ---------------------------------------------------------------------
sec "3. Namespace ID — D-* không được dùng cho denormalization"
# ---------------------------------------------------------------------
if filled 03-logical-schema.md; then
  # Chỉ bắt D-NN ĐỊNH NGHĨA một denormalization (đầu dòng, hoặc kèm chữ
  # "denorm"). Một tham chiếu trong văn xuôi ngược về quyết định Stage 2 là
  # hợp lệ và bình thường — bắt cả nó thì công cụ thành tiếng ồn.
  bad_dn="$(grep -nE '^[[:space:]]*\*{0,2}D-[0-9]{2}\b|denorm[a-z]* D-[0-9]{2}' "$L3" 2>/dev/null | grep -v 'DN-' || true)"
  if [[ -n "$bad_dn" ]]; then
    err "03-logical-schema.md định nghĩa denormalization bằng D-NN — phải là DN-NN (đụng namespace Stage 2)"
    echo "$bad_dn" | head -3 | sed 's/^/           /'
  else
    ok "Stage 3 dùng DN-* đúng namespace"
  fi
fi
if filled 04-schema.sql && grep -qE 'denorm[a-z]*[^A-Za-z0-9_]+D-[0-9]{2}' "$SQL" 2>/dev/null; then
  warn "04-schema.sql gọi một denormalization là D-NN — phải là DN-NN"
fi

# ---------------------------------------------------------------------
sec "4. ID được dùng nhưng chưa được định nghĩa ở đâu"
# ---------------------------------------------------------------------
# "Định nghĩa" = ID xuất hiện ở đầu một dòng bảng (| BR-001 |) hoặc đầu dòng.
tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
if ! filled 01-data-requirements.md; then
  echo "           bỏ qua: 01-data-requirements.md chưa được điền"
fi
cat_md() { while IFS= read -r f; do [[ -n "$f" ]] && cat "$f"; done < <(mds); }
cat_md > "$tmpd/all.md" 2>/dev/null || true

PREFIX='(BC|EN|AT|RL|BR|PR|VP|NF|XX|DR|DD|CC|DN|IX|Q|A|D)'
USEPFX='(BC|EN|AT|RL|BR|PR|VP|NF|XX|DR|DD|CC|DN|IX)'
# Phải có ranh giới TRƯỚC tiền tố, nếu không "BA-04" sẽ bị đọc thành "A-04" —
# một ID không tồn tại, báo động giả, và người dùng học cách bỏ qua công cụ.
scan() { grep -ohE "(^|[^A-Za-z0-9_])$1-[0-9]+" "$2" 2>/dev/null | grep -ohE "$1-[0-9]+" | sort -u; }

grep -ohE "^\|?[[:space:]]*\*{0,2}$PREFIX-[0-9]+" "$tmpd/all.md" 2>/dev/null \
  | grep -ohE "$PREFIX-[0-9]+" | sort -u > "$tmpd/defined" || true
scan "$USEPFX" "$tmpd/all.md" > "$tmpd/used" || true
# IDs trong DDL cũng tính là "được dùng"
filled 04-schema.sql && scan '(BR|VP|NF|XX|DN|IX)' "$SQL" >> "$tmpd/used"
sort -u "$tmpd/used" -o "$tmpd/used"

undef=""
filled 01-data-requirements.md && undef="$(comm -13 "$tmpd/defined" "$tmpd/used" 2>/dev/null | head -12)"
if [[ -n "$undef" ]]; then
  err "ID được tham chiếu nhưng không có dòng định nghĩa:"
  while IFS= read -r id; do echo "           $id"; done <<< "$undef"
else
  ok "mọi ID được tham chiếu đều có dòng định nghĩa"
fi

# ---------------------------------------------------------------------
sec "5. Số tự khai vs số đếm được"
# ---------------------------------------------------------------------
if filled 01-data-requirements.md; then
  # Đếm ID DUY NHẤT, không đếm dòng — một requirement có thể trải nhiều dòng.
  actual="$(grep -ohE '(BC|EN|AT|RL|BR|PR|VP|NF|XX)-[0-9]+' "$WS/01-data-requirements.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
  claimed="$(grep -oiE '([0-9]{2,4})[[:space:]]*(requirement|yêu cầu)' "$WS/01-data-requirements.md" 2>/dev/null | grep -oE '[0-9]{2,4}' | head -1)"
  echo "           ID requirement duy nhất đếm được: $actual"
  if [[ -n "${claimed:-}" ]] && [[ "$claimed" != "$actual" ]]; then
    err "requirement document tự khai $claimed nhưng đếm được $actual ID duy nhất — sửa con số, đừng sửa cách đếm"
  else
    ok "không phát hiện số tự khai lệch"
  fi
fi
if filled 04-schema.sql; then
  # Partition KHÔNG phải bảng thiết kế — đếm chung là cách tự thổi số bảng lên.
  tbl_sql="$(grep -E '^[[:space:]]*CREATE TABLE' "$SQL" 2>/dev/null | grep -vc 'PARTITION OF' || true)"
  part_sql="$(grep -cE 'PARTITION OF' "$SQL" 2>/dev/null || true)"
  echo "           bảng trong DDL: $tbl_sql   partition: $part_sql"
  if has 05-review-report.md; then
    rep_tbl="$(grep -oiE '\|[[:space:]]*Tables?[[:space:]]*\|[[:space:]]*([0-9]+)' "$WS/05-review-report.md" 2>/dev/null | grep -oE '[0-9]+' | head -1)"
    if [[ -n "${rep_tbl:-}" ]] && [[ "$rep_tbl" != "$tbl_sql" ]]; then
      err "review report ghi $rep_tbl bảng nhưng DDL có $tbl_sql (chưa tính $part_sql partition)"
    fi
  fi
fi

# ---------------------------------------------------------------------
sec "6. Drift giữa Stage 3 và Stage 4"
# ---------------------------------------------------------------------
if filled 03-logical-schema.md && filled 04-schema.sql; then
  if grep -qE '^\|.*DB \(planned\)' "$L3" 2>/dev/null; then
    err "03-logical-schema.md còn dòng 'DB (planned)' sau khi Stage 4 đã chạy — Bước 6 back-propagate chưa làm"
    grep -n 'DB (planned)' "$L3" | head -3 | sed 's/^/           /'
  else
    ok "không còn khẳng định 'DB (planned)' chưa kiểm chứng"
  fi

  # BR ghi là DB ở Stage 3 nhưng Stage 4 nói không ép được
  drift=0
  grep -ohE 'BR-[0-9]+' "$L3" 2>/dev/null | sort -u > "$tmpd/brs" || true
  while IFS= read -r br; do
    [[ -z "$br" ]] && continue
    grep -E "^\|[[:space:]]*\*{0,2}$br\b" "$L3" 2>/dev/null | grep -qE '\|[[:space:]]*DB[[:space:]]*\|' || continue
    for f in "$WS"/04-index-plan.md "$WS"/04-migration-notes.md "$WS"/05-review-report.md; do
      [[ -f "$f" ]] || continue
      if grep -E "$br" "$f" 2>/dev/null | grep -qiE 'cannot|không ép được|not enforceable|app-enforced|enforced in the application'; then
        err "$br: Stage 3 ghi 'DB' nhưng $(basename "$f") nói không ép được ở database"
        drift=$((drift + 1)); break
      fi
    done
  done < "$tmpd/brs"
  [[ $drift -eq 0 ]] && ok "không có BR-* nào bị hai stage mô tả trái nhau"
fi

# ---------------------------------------------------------------------
sec "7. Vòng đời mã hoá hai lần mà không có ràng buộc"
# ---------------------------------------------------------------------
if filled 04-schema.sql; then
  awk '
    /^[[:space:]]*CREATE TABLE/ && /PARTITION OF/ { next }
    /^[[:space:]]*CREATE TABLE/ {
      inblk=1; tname=$0
      sub(/.*CREATE TABLE (IF NOT EXISTS )?/, "", tname)
      sub(/[[:space:]]*\(.*/, "", tname); gsub(/"/, "", tname); gsub(/[^A-Za-z0-9_].*/, "", tname)
      nts=0; hasstatus=0; ckts=0; delete tsname; next
    }
    inblk && /^[[:space:]]*\)/ {
      # Ngưỡng 2 là ngưỡng đã ghi trong skills/03-logical-design/SKILL.md
      # (Bước 6, "Vòng đời hai lần"). Script từng dùng 3 và im lặng bỏ qua
      # đúng những bảng mà rule đã cấm — công cụ phải bắt rule đã viết,
      # không được nới lỏng nó một cách âm thầm.
      if (hasstatus && nts >= 2 && ckts == 0) print tname "|" nts
      inblk=0; next
    }
    inblk {
      line=$0
      if (line ~ /(timestamptz|timestamp|datetime)/ && line !~ /NOT NULL/ && line !~ /CONSTRAINT|CHECK|PRIMARY|FOREIGN|UNIQUE|EXCLUDE/) {
        n=split(line, a, /[[:space:]]+/); for (i=1;i<=n;i++) if (a[i] != "") { c=a[i]; break }
        if (c ~ /_at$|_time$|_on$/) { nts++; tsname[c]=1 }
      }
      if (line ~ /(^|[^a-z_])(status|state|lifecycle)[[:space:]]/ && line !~ /CONSTRAINT|CHECK/) hasstatus=1
      if (line ~ /CHECK/) { for (c in tsname) if (line ~ c) ckts=1 }
    }
  ' "$SQL" > "$tmpd/lifecycle" 2>/dev/null || true

  if [[ -s "$tmpd/lifecycle" ]]; then
    warn "bảng mã hoá vòng đời hai lần (cột status + timestamp theo mốc) mà không có CHECK buộc khớp:"
    while IFS='|' read -r t n; do
      echo "           $t — $n timestamp nullable, không CHECK nào tham chiếu tới chúng"
    done < "$tmpd/lifecycle"
    echo "           ⇒ status='DONE' với timestamp NULL là dòng hợp lệ; mọi job/báo cáo đọc timestamp đó sai âm thầm"
  else
    ok "không phát hiện vòng đời mã hoá hai lần không ràng buộc"
  fi
fi

# ---------------------------------------------------------------------
sec "8. Mật độ ràng buộc theo từng bảng"
# ---------------------------------------------------------------------
if filled 04-schema.sql; then
  awk '
    /^[[:space:]]*CREATE TABLE/ && /PARTITION OF/ { next }
    /^[[:space:]]*CREATE TABLE/ {
      inblk=1; tname=$0
      sub(/.*CREATE TABLE (IF NOT EXISTS )?/, "", tname)
      sub(/[[:space:]]*\(.*/, "", tname); gsub(/"/, "", tname); gsub(/[^A-Za-z0-9_].*/, "", tname)
      cols=0; cons=0; next
    }
    inblk && /^[[:space:]]*\)/ {
      if (cols > 0 && tname != "") printf "%-32s %3d cols %3d cons  %.2f\n", tname, cols, cons, cons/cols
      inblk=0; next
    }
    inblk {
      if ($0 ~ /CONSTRAINT|PRIMARY KEY|FOREIGN KEY|UNIQUE|CHECK|EXCLUDE/) { cons++ }
      else if ($0 ~ /^[[:space:]]+"?[a-z_][a-z0-9_]*"?[[:space:]]+[a-z]/) { cols++ }
    }
  ' "$SQL" 2>/dev/null | sort -k6 -n > "$tmpd/density" || true

  if [[ -s "$tmpd/density" ]]; then
    sed 's/^/           /' "$tmpd/density"
    echo ""
    echo "           Đọc bảng này: bảng ở đầu danh sách được database bảo vệ ÍT NHẤT."
    echo "           Với mỗi bảng < 0.20, Stage 5 phải trả lời: đây là bảng bằng chứng"
    echo "           (cố tình lỏng để nhận cả dữ liệu xấu), hay là một lỗ hổng thật?"
    low="$(awk '$6 < 0.20 {print $1}' "$tmpd/density" | head -5)"
    [[ -n "$low" ]] && warn "bảng mật độ ràng buộc thấp cần giải thích: $(echo "$low" | tr '\n' ' ')"
  fi
fi

# ---------------------------------------------------------------------
sec "9. App-enforced register có đủ không"
# ---------------------------------------------------------------------
if filled 03-logical-schema.md; then
  appbr="$(grep -E '^\|[[:space:]]*\*{0,2}BR-[0-9]+' "$L3" 2>/dev/null \
            | grep -iE '\bapp\b|application|ứng dụng' | grep -ohE 'BR-[0-9]+' | sort -u)"
  cnt="$(echo "$appbr" | grep -c 'BR-' || true)"
  if [[ -n "$appbr" ]]; then
    echo "           $cnt rule ghi là ép ở tầng ứng dụng"
    if has 05-app-enforced-rules.md; then
      miss=""
      for br in $appbr; do
        grep -q "$br" "$WS/05-app-enforced-rules.md" || miss="$miss $br"
      done
      if [[ -n "$miss" ]]; then
        err "05-app-enforced-rules.md thiếu:$miss — rule app-enforced không có register sẽ mất khi sang code"
      else
        ok "mọi rule app-enforced đều có trong register"
      fi
    else
      err "có $cnt rule app-enforced nhưng thiếu 05-app-enforced-rules.md"
    fi
  fi
fi

# ---------------------------------------------------------------------
echo ""
echo "─────────────────────────────────────────────"
echo "ERROR: $errors   WARN: $warns"
if [[ $errors -gt 0 && $WARN_ONLY -eq 0 ]]; then
  echo "Sửa các ERROR trước khi mở gate Stage 5." >&2
  exit 1
fi
exit 0
