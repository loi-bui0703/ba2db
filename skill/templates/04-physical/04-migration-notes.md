# 04 — Migration & Operations Notes

Project: `<slug>` · Engine: `<engine + version>` · `dbms_status`: `decided / provisional`
(nguồn: `01b-dbms-decision.md`)

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

## 6. Partition lifecycle (nếu có partition)

| Bảng | Khoá phân mảnh | Chu kỳ | Vì sao chu kỳ này |
|---|---|---|---|

| Cái giá của partition | Chi tiết |
|---|---|
| `BR-*` mất chỗ ép (unique toàn cục) | |
| Cột phải denormalize thêm (`DN-*`) | |
| Biên partition & múi giờ predicate | |

Tạo partition: trước `<N>` kỳ, cảnh báo khi còn `<M>`. Có `DEFAULT` partition
không: `<có/không + lý do>`. Purge: `DROP PARTITION`, không `DELETE`.

## 7. Operational jobs the schema depends on · Job mà thiết kế phụ thuộc

Đây là **phần của thiết kế**, không phải việc đội vận hành tự đoán. Thiết kế
**không đúng** nếu những job này không chạy.

| Job | Tần suất | Hỏng gì nếu không chạy | Hồi phục được? | Phát hiện bằng cách nào |
|---|---|---|---|---|
| | | | Y / **N — mất vĩnh viễn** | |

> Ô **"Hồi phục được?"** là ô nguy hiểm nhất. Một job tổng hợp bỏ sót một ngày mà
> dữ liệu chi tiết sau đó bị purge thì ngày đó mất vĩnh viễn. Mọi job có `N` phải
> có cơ chế phát hiện thiếu (watermark / bảng job-run), không chỉ một dòng ở đây.

## 8. Portability budget · Ngân sách khả chuyển

Tính năng chỉ engine đã chọn có, và `BR-*`/`VP-*` nào phụ thuộc nó.

| Tính năng độc quyền đang dùng | `BR-*` / `VP-*` phụ thuộc | Nếu đổi engine |
|---|---|---|

**Risk của assumption "engine đã chọn":** `Low / Medium / High`
(≥3 `BR-*` phụ thuộc ⇒ **High**)

## 9. Validation status

- [ ] DDL đã chạy thử trên database rỗng — môi trường: `<...>`
- [ ] Chưa chạy thử (ghi rõ nếu không có môi trường)

Objects thực sự được tạo (từ `validate-ddl.sh`, không tự khai):

| Đối tượng | Số lượng |
|---|---|
| tables / partitions / indexes / constraints / triggers / views | |

Assertions (`05-assertions.sql`): `<số đạt>/<số chạy>` · rule đã thử:
`BR-xxx, …` · rule **chưa** thử: `BR-xxx, …`
