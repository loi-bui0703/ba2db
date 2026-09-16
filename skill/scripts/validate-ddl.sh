#!/usr/bin/env bash
# validate-ddl.sh — chạy thử DDL trên một database rỗng tạm thời.
# Usage: bash scripts/validate-ddl.sh <schema.sql> [postgres|mysql]
set -euo pipefail

SQL="${1:-}"; ENGINE="${2:-postgres}"
[[ -f "$SQL" ]] || { echo "File not found: $SQL" >&2; exit 1; }

case "$ENGINE" in
  postgres)
    command -v psql >/dev/null || { echo "psql không có trên máy — bỏ qua bước kiểm tra, PHẢI báo rõ DDL chưa chạy thử." >&2; exit 2; }
    DB="ddlcheck_$(date +%s)"
    createdb "$DB"
    trap 'dropdb --if-exists "$DB"' EXIT
    psql -v ON_ERROR_STOP=1 -d "$DB" -f "$SQL"
    echo "OK: DDL applied cleanly to $ENGINE."
    ;;
  mysql)
    command -v mysql >/dev/null || { echo "mysql client không có — bỏ qua, báo rõ DDL chưa chạy thử." >&2; exit 2; }
    DB="ddlcheck_$(date +%s)"
    mysql -e "CREATE DATABASE \`$DB\`;"
    trap 'mysql -e "DROP DATABASE IF EXISTS \`$DB\`;"' EXIT
    mysql "$DB" < "$SQL"
    echo "OK: DDL applied cleanly to $ENGINE."
    ;;
  *) echo "Unsupported engine: $ENGINE" >&2; exit 1 ;;
esac
