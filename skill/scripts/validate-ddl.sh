#!/usr/bin/env bash
# validate-ddl.sh — chạy thử DDL trên một database sạch, dùng một lần rồi bỏ.
#
# Usage:
#   bash scripts/validate-ddl.sh <schema.sql> [postgres|mysql] [options]
#
# Options:
#   --version <tag>   phiên bản engine (mặc định: postgres 16, mysql 8)
#   --engine docker|local|auto    (mặc định: auto)
#   --keep            giữ container lại để tự kiểm tra thêm
#   --psql <cmd>      chạy một lệnh SQL sau khi DDL chạy xong, in kết quả
#   --assert <file>   chạy file khẳng định (05-assertions.sql) sau khi DDL xong:
#                     chứng minh RÀNG BUỘC ép đúng, không chỉ chứng minh cú pháp
#   --report          in mật độ ràng buộc theo từng bảng + FK thiếu index
#
# Chiến lược "auto": ưu tiên DOCKER, vì nó cho đúng phiên bản DBMS mình đang
# thiết kế cho và một database thật sự sạch. Chỉ khi không có docker mới dùng
# client cục bộ — client cục bộ thường là phiên bản khác với đích thiết kế, và
# một CHECK/partition/EXCLUDE hợp lệ ở bản này có thể không hợp lệ ở bản kia.
#
# Exit codes:
#   0  DDL chạy sạch
#   1  DDL có lỗi  → SỬA, đừng bỏ qua
#   2  không có môi trường nào để thử → PHẢI nói rõ "DDL chưa được chạy thử",
#      không được nói hoặc ngụ ý là đã kiểm tra.
#   3  DDL chạy được nhưng CÓ KHẲNG ĐỊNH THẤT BẠI (--assert) → ràng buộc không
#      ép đúng cái nó phải ép. Nặng hơn lỗi cú pháp, vì nó im lặng.
set -euo pipefail

SQL=""; ENGINE_KIND="auto"; DBMS="postgres"; VERSION=""; KEEP=0; POST_SQL=""
ASSERT_SQL=""; REPORT=0; ASSERT_FAILED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    postgres|postgresql|pg) DBMS="postgres"; shift ;;
    mysql)                  DBMS="mysql"; shift ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --engine)  ENGINE_KIND="${2:-auto}"; shift 2 ;;
    --keep)    KEEP=1; shift ;;
    --psql)    POST_SQL="${2:-}"; shift 2 ;;
    --assert)  ASSERT_SQL="${2:-}"; shift 2 ;;
    --report)  REPORT=1; shift ;;
    -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
    *)         SQL="$1"; shift ;;
  esac
done

[[ -n "$SQL" ]]  || { echo "Usage: bash scripts/validate-ddl.sh <schema.sql> [postgres|mysql]" >&2; exit 1; }
[[ -f "$SQL" ]]  || { echo "File not found: $SQL" >&2; exit 1; }
if [[ -n "$ASSERT_SQL" && ! -f "$ASSERT_SQL" ]]; then
  echo "Assertion file not found: $ASSERT_SQL" >&2; exit 1
fi

if [[ -z "$VERSION" ]]; then
  case "$DBMS" in postgres) VERSION="16" ;; mysql) VERSION="8" ;; esac
fi

have() { command -v "$1" >/dev/null 2>&1; }
docker_usable() { have docker && docker info >/dev/null 2>&1; }

# ----- chọn chiến lược -------------------------------------------------
case "$ENGINE_KIND" in
  docker) docker_usable || { echo "--engine docker nhưng docker không chạy được." >&2; exit 2; } ;;
  local)  : ;;
  auto)
    if docker_usable; then ENGINE_KIND="docker"
    else ENGINE_KIND="local"; fi ;;
  *) echo "Unknown --engine: $ENGINE_KIND" >&2; exit 1 ;;
esac

CONTAINER="ba2db-ddlcheck-$$-$(date +%s)"

cleanup_docker() {
  if [[ $KEEP -eq 1 ]]; then
    echo ""
    echo "Container giữ lại: $CONTAINER"
    case "$DBMS" in
      postgres) echo "  docker exec -it $CONTAINER psql -U postgres -d ddlcheck" ;;
      mysql)    echo "  docker exec -it $CONTAINER mysql -uroot -proot ddlcheck" ;;
    esac
    echo "  docker rm -f $CONTAINER   # khi xong"
  else
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  fi
}

wait_ready() {
  # Phải thử KẾT NỐI ĐƯỢC VÀO ĐÚNG DATABASE ĐÍCH, không chỉ "server có sống".
  # `pg_isready` trả OK ngay cả trên server tạm mà initdb dựng lên trước khi
  # POSTGRES_DB được tạo — chạy DDL vào lúc đó fail với "database does not
  # exist", và trông y như một lỗi DDL. Lỗi hạ tầng không được phép giả dạng
  # lỗi thiết kế.
  for _ in $(seq 1 60); do
    case "$DBMS" in
      postgres) docker exec "$CONTAINER" psql -U postgres -d ddlcheck -c 'SELECT 1' >/dev/null 2>&1 && return 0 ;;
      mysql)    docker exec "$CONTAINER" mysql -uroot -proot -e 'USE ddlcheck; SELECT 1;' >/dev/null 2>&1 && return 0 ;;
    esac
    sleep 1
  done
  echo "Database 'ddlcheck' không sẵn sàng sau 60 giây." >&2
  return 1
}

run_docker() {
  local image
  case "$DBMS" in
    postgres) image="postgres:${VERSION}" ;;
    mysql)    image="mysql:${VERSION}" ;;
  esac

  echo "→ docker: $image (database sạch, xoá sau khi chạy)"
  trap cleanup_docker EXIT

  case "$DBMS" in
    postgres)
      docker run -d --name "$CONTAINER" \
        -e POSTGRES_PASSWORD=ba2db -e POSTGRES_DB=ddlcheck \
        "$image" >/dev/null ;;
    mysql)
      docker run -d --name "$CONTAINER" \
        -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=ddlcheck \
        "$image" >/dev/null ;;
  esac

  wait_ready || return 1
  docker cp "$SQL" "$CONTAINER:/tmp/schema.sql" >/dev/null

  case "$DBMS" in
    postgres)
      docker exec "$CONTAINER" psql -U postgres -d ddlcheck -v ON_ERROR_STOP=1 -q -f /tmp/schema.sql || return 1 ;;
    mysql)
      docker exec "$CONTAINER" sh -c 'mysql -uroot -proot ddlcheck < /tmp/schema.sql' || return 1 ;;
  esac

  # Đếm object thật sự được tạo — "không lỗi" chưa chắc là "đã tạo được gì".
  echo ""
  echo "Objects created:"
  case "$DBMS" in
    postgres)
      docker exec "$CONTAINER" psql -U postgres -d ddlcheck -tAc "
        SELECT '  tables      : ' || count(*) FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT c.relispartition
        UNION ALL SELECT '  partitions  : ' || count(*) FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public' AND c.relispartition
        UNION ALL SELECT '  indexes     : ' || count(*) FROM pg_indexes WHERE schemaname = 'public'
        UNION ALL SELECT '  constraints : ' || count(*) FROM pg_constraint c
          JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'public'
        UNION ALL SELECT '  triggers    : ' || count(*) FROM pg_trigger WHERE NOT tgisinternal
        UNION ALL SELECT '  views       : ' || count(*) FROM pg_views WHERE schemaname = 'public'" ;;
    mysql)
      docker exec "$CONTAINER" mysql -uroot -proot -N -B -e "
        SELECT CONCAT('  tables      : ', count(*)) FROM information_schema.tables WHERE table_schema='ddlcheck'
        UNION ALL SELECT CONCAT('  indexes     : ', count(DISTINCT table_name, index_name)) FROM information_schema.statistics WHERE table_schema='ddlcheck'" ;;
  esac

  if [[ $REPORT -eq 1 && "$DBMS" == "postgres" ]]; then
    echo ""
    echo "Constraint density per table (bảng ở đầu = database bảo vệ ÍT NHẤT):"
    docker exec "$CONTAINER" psql -U postgres -d ddlcheck -tA -F'  ' -c "
      WITH t AS (
        SELECT c.oid, c.relname,
               (SELECT count(*) FROM pg_attribute a
                 WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped) AS cols,
               (SELECT count(*) FROM pg_constraint k WHERE k.conrelid = c.oid)     AS cons
          FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT c.relispartition)
      SELECT relname, cols, cons, round(cons::numeric / NULLIF(cols,0), 2)
        FROM t ORDER BY 4 NULLS FIRST, relname" | sed 's/^/  /'

    echo ""
    echo "Foreign keys with no index on the child side (mỗi dòng là một join/RESTRICT phải quét bảng):"
    docker exec "$CONTAINER" psql -U postgres -d ddlcheck -tA -c "
      SELECT '  ' || conrelid::regclass || ' (' ||
             (SELECT string_agg(a.attname, ',' ORDER BY x.ord)
                FROM unnest(conkey) WITH ORDINALITY AS x(attnum, ord)
                JOIN pg_attribute a ON a.attrelid = conrelid AND a.attnum = x.attnum) || ')'
        FROM pg_constraint c
       WHERE contype = 'f'
         AND NOT EXISTS (
           SELECT 1 FROM pg_index i
            WHERE i.indrelid = c.conrelid
              AND (i.indkey::smallint[])[0:array_length(c.conkey,1)-1] @> c.conkey)
       ORDER BY 1" || true
  fi

  if [[ -n "$POST_SQL" ]]; then
    echo ""
    echo "Post-check:"
    case "$DBMS" in
      postgres) docker exec "$CONTAINER" psql -U postgres -d ddlcheck -c "$POST_SQL" ;;
      mysql)    docker exec "$CONTAINER" mysql -uroot -proot ddlcheck -e "$POST_SQL" ;;
    esac
  fi

  # Chạy khẳng định SAU khi DDL xong. DDL chạy được chỉ chứng minh cú pháp;
  # khẳng định mới chứng minh ràng buộc ép đúng — cả chiều từ chối và chiều
  # chấp nhận cái hợp lệ gần giống.
  if [[ -n "$ASSERT_SQL" ]]; then
    echo ""
    echo "Assertions: $ASSERT_SQL"
    docker cp "$ASSERT_SQL" "$CONTAINER:/tmp/assert.sql" >/dev/null
    case "$DBMS" in
      postgres)
        docker exec "$CONTAINER" psql -U postgres -d ddlcheck -v ON_ERROR_STOP=1 -q -f /tmp/assert.sql \
          || ASSERT_FAILED=1 ;;
      mysql)
        docker exec "$CONTAINER" sh -c 'mysql -uroot -proot ddlcheck < /tmp/assert.sql' \
          || ASSERT_FAILED=1 ;;
    esac
  fi
}

run_local() {
  case "$DBMS" in
    postgres)
      if ! have psql || ! have createdb; then
        cat >&2 <<'MSG'
Không có docker, cũng không có psql/createdb trên máy.

  → DDL CHƯA ĐƯỢC CHẠY THỬ.

Phải nói rõ điều này trong báo cáo Stage 4. Không được viết "DDL hợp lệ" hay
"đã kiểm tra cú pháp" khi chưa thực sự chạy.

Cách có môi trường để chạy (chọn một):
  * khởi động docker (Docker Desktop / colima start) rồi chạy lại lệnh này
  * cài postgres client: brew install libpq   (hoặc apt install postgresql-client)
MSG
        exit 2
      fi
      # SC2155: khai báo và gán riêng, để mã lỗi của `date` không bị `local` che.
      local db
      db="ddlcheck_$(date +%s)"
      echo "→ local psql ($(psql --version | awk '{print $3}')) — LƯU Ý: có thể khác phiên bản đích"
      createdb "$db"
      trap 'dropdb --if-exists "$db" >/dev/null 2>&1 || true' EXIT
      psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$SQL" || return 1
      if [[ -n "$ASSERT_SQL" ]]; then
        echo ""; echo "Assertions: $ASSERT_SQL"
        psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$ASSERT_SQL" || ASSERT_FAILED=1
      fi
      ;;
    mysql)
      if ! have mysql; then
        echo "Không có docker, cũng không có mysql client → DDL CHƯA ĐƯỢC CHẠY THỬ. Phải báo rõ." >&2
        exit 2
      fi
      local db
      db="ddlcheck_$(date +%s)"
      echo "→ local mysql — LƯU Ý: có thể khác phiên bản đích"
      mysql -e "CREATE DATABASE \`$db\`;"
      trap 'mysql -e "DROP DATABASE IF EXISTS \`$db\`;" >/dev/null 2>&1 || true' EXIT
      mysql "$db" < "$SQL" || return 1
      if [[ -n "$ASSERT_SQL" ]]; then
        echo ""; echo "Assertions: $ASSERT_SQL"
        mysql "$db" < "$ASSERT_SQL" || ASSERT_FAILED=1
      fi
      ;;
  esac
}

echo "Validating $SQL against $DBMS $VERSION"
if [[ "$ENGINE_KIND" == "docker" ]]; then
  run_docker || { echo ""; echo "✗ DDL FAILED — sửa lỗi ở trên rồi chạy lại." >&2; exit 1; }
else
  run_local  || { echo ""; echo "✗ DDL FAILED — sửa lỗi ở trên rồi chạy lại." >&2; exit 1; }
fi

if [[ $ASSERT_FAILED -eq 1 ]]; then
  echo ""
  echo "✗ ASSERTIONS FAILED — DDL chạy được, nhưng một ràng buộc KHÔNG ép đúng." >&2
  echo "  Đây là lỗi nặng hơn lỗi cú pháp: nó không làm deploy fail, nó làm dữ liệu sai." >&2
  echo "  Sửa ràng buộc (hoặc sửa khẳng định nếu khẳng định viết sai) rồi chạy lại." >&2
  exit 3
fi

echo ""
echo "✓ OK: DDL applied cleanly to $DBMS $VERSION."
if [[ -n "$ASSERT_SQL" ]]; then
  echo "✓ OK: all assertions in $(basename "$ASSERT_SQL") passed."
else
  echo "  (chưa chạy khẳng định nào — DDL chạy được chỉ chứng minh CÚ PHÁP đúng."
  echo "   Dùng --assert <file> để chứng minh ràng buộc ép đúng nghiệp vụ.)"
fi
