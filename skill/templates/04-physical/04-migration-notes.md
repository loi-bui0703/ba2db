# 04 — Migration & Operations Notes

## 1. Deployment order
1. schema & extensions → 2. enums → 3. tables → 4. constraints → 5. indexes →
6. views → 7. triggers → 8. seed data

## 2. Legacy migration (nếu có hệ thống cũ)

| Legacy source | Target table | Transformation | Key mapping | Data quality risk |
|---|---|---|---|---|

Chiến lược cắt chuyển: big-bang / song song / theo phân hệ — chọn và nêu lý do.

## 3. Roles & privileges

| Role | Grants | Used by |
|---|---|---|
| app_rw | SELECT/INSERT/UPDATE on app.* | application |
| app_ro | SELECT on app.* | reporting |

## 4. Backup & retention

| Item | Policy |
|---|---|
| Full backup | |
| PITR / WAL | |
| Archive | |

## 5. Security (từ `NF-*`)

| Item | Approach |
|---|---|
| PII encryption | |
| Row-level security | |
| Audit log | |

## 6. Validation status

- [ ] DDL đã chạy thử trên database rỗng — môi trường: `<...>`
- [ ] Chưa chạy thử (ghi rõ nếu không có môi trường)
