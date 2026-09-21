# 04 — Migration & Operations Notes

Project: `<slug>` · Engine: `<engine + version>` · `dbms_status`: `decided / provisional`
(nguồn: `01b-dbms-decision.md`)

## 1. Deployment order
1. schema & extensions → 2. enums → 3. tables → 4. constraints → 5. indexes →
6. views → 7. triggers → 8. seed data

### 1b. Zero-downtime schema change · Đổi schema khi hệ đang chạy

Chỉ áp cho lần triển khai **sau** lần đầu. Mỗi thay đổi dưới đây phải chọn một dòng.

| Thay đổi | Chạy thẳng có an toàn không | Cách expand/contract |
|---|---|---|
| Thêm cột NULL, không default | an toàn | — |
| Thêm cột `NOT NULL` | **không** trên bảng nóng | thêm NULL → backfill theo lô → `CHECK ... NOT VALID` → `VALIDATE` → `SET NOT NULL` |
| Đổi tên cột / bảng | **không** — ứng dụng cũ gãy ngay | thêm tên mới → ghi cả hai → chuyển đọc → bỏ tên cũ (3 lần deploy) |
| Đổi kiểu dữ liệu | **không** — rewrite toàn bảng, giữ khoá | cột mới + backfill + đổi đọc + bỏ cột cũ |
| Thêm index | phải dùng `CREATE INDEX CONCURRENTLY` (PG) / `ALGORITHM=INPLACE` (MySQL) | — |
| Thêm FK / CHECK | khoá bảng để kiểm | `NOT VALID` rồi `VALIDATE CONSTRAINT` sau |
| Bỏ cột | an toàn ở DB, **gãy ở ứng dụng** nếu còn `SELECT *` | ngừng đọc trước, bỏ cột ở deploy sau |

| Thay đổi cần expand/contract | Bảng | Số lần deploy | Backfill: lô bao nhiêu / mất bao lâu |
|---|---|---|---|

> Quy tắc: **mỗi bước phải chạy được cùng lúc với cả phiên bản ứng dụng cũ và
> mới.** Bước nào không thoả thì đó là downtime, và downtime phải được ghi ra
> kèm con số — so với RTO ở §4.

## 2. Legacy migration (nếu có hệ thống cũ)

| Legacy source | Target table | Transformation | Key mapping | Data quality risk |
|---|---|---|---|---|

Chiến lược cắt chuyển: big-bang / song song / theo phân hệ — chọn và nêu lý do.

## 3. Roles & privileges

| Role | Grants | Used by |
|---|---|---|
| app_rw | SELECT/INSERT/UPDATE on app.* | application |
| app_ro | SELECT on app.* | reporting |

## 4. Durability & availability · Độ bền và sẵn sàng

Tham chiếu: `references/durability-and-availability.md`.

### 4.1 Mục tiêu phục hồi (từ `BR-*` / `NF-*`)

| Nhóm bảng | RPO (mất tối đa bao nhiêu dữ liệu) | RTO (ngừng tối đa bao lâu) | Nguồn yêu cầu |
|---|---|---|---|
| Giao dịch tiền | | | |
| Dữ liệu nghiệp vụ chung | | | |
| Log / sự kiện tái tạo được | | | |

Chưa có yêu cầu ⇒ ghi `OPEN QUESTION`, **không** tự điền con số trông hợp lý.

### 4.2 Backup & retention — phương tiện phải đủ cho RPO ở §4.1

| Item | Policy | Đủ cho RPO nào |
|---|---|---|
| Full backup | | |
| Incremental | | |
| PITR / WAL / binlog archive (lưu ở đâu — **không cùng đĩa với DB**) | | |
| Archive dữ liệu lạnh | | |
| Thời gian giữ bản sao lưu | | |

### 4.3 Replica topology

| Replica | Đồng bộ / bất đồng bộ | Dùng để | Ngân sách độ trễ | Cảnh báo khi vượt |
|---|---|---|---|---|

Báo cáo / truy vấn **KHÔNG** chịu được dữ liệu cũ (chạy trên primary): `<liệt kê>`

`PR-*` dạng "tạo xong xem ngay" và cách xử lý read-after-write
(đọc primary / chờ LSN-GTID / chấp nhận và hiển thị độ trễ): `<...>`

### 4.4 Failover

| Câu hỏi | Trả lời |
|---|---|
| Ai/cái gì phát hiện primary chết | |
| Tự động hay thủ công (ai bấm, runbook ở đâu) | |
| Ứng dụng tìm primary mới bằng gì (DNS / VIP / pooler) | |
| Thời gian failover cam kết (sàn của RTO) | |
| Replica cũ rejoin thế nào | |

### 4.5 Restore drill — ba trạng thái, không bỏ trống

| Item | Giá trị |
|---|---|
| Trạng thái | `verified` / `partial` / **`not tested`** |
| Ngày drill gần nhất | |
| Restore từ đâu, vào môi trường nào | |
| **Thời gian restore đo được** (số duy nhất chứng minh RTO) | |
| Kiểm đúng dữ liệu bằng gì (đếm dòng + một `BR-*` kiểm bằng truy vấn) | |
| Chu kỳ drill định kỳ | |

> `not tested` là câu trả lời **hợp lệ** và phải hiện ở báo cáo Stage 5. Một
> chính sách backup không có dòng nào về restore là khẳng định chưa có bằng chứng.

### 4.6 Giả định quy mô

Giả định: **một node ghi** (scale dọc + replica đọc + partition).
Ngưỡng phải xem lại: `<số ghi/giây hoặc dung lượng>`.
Yêu cầu vị trí dữ liệu (data residency) nếu có: `<...>`

### 4.7 Theo dõi

| Thứ theo dõi | Tín hiệu | Ngưỡng cảnh báo |
|---|---|---|
| Tuổi backup thành công gần nhất | | > RPO |
| Độ trễ replica | | > ngân sách §4.3 |
| Job archive WAL/binlog | | bất kỳ lỗi nào |
| Truy vấn chậm | `log_min_duration_statement` / `slow_query_log` | lấy từ `VP-*` |
| Index không ai dùng | | |
| Ngày restore drill gần nhất | | > chu kỳ §4.5 |

## 4b. Concurrency · Đồng thời

Tham chiếu: `references/concurrency.md`.

Mức cô lập giả định: `<Read Committed / Repeatable Read / …>` · Giao dịch chạy ở
mức cao hơn: `<liệt kê hoặc "không có">`

| `BR-*` | Lớp (A hạn mức / B duy nhất / C chồng lấn) | Cơ chế ép (unique · EXCLUDE · FOR UPDATE · SERIALIZABLE) | Đã thử đồng thời? |
|---|---|---|---|
| | | | Y / **chưa thử đồng thời** |

Bảng có cột `version` (optimistic lock) và lý do: `<...>`

Quy ước thứ tự khoá (chống deadlock): `<ví dụ: luôn khoá theo id tăng dần; batch
update phải có ORDER BY>`

Thao tác ứng dụng **phải retry** (deadlock / serialization failure), số lần và
điều kiện idempotent: `<...>` — cũng phải có trong `05-app-enforced-rules.md`.

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
