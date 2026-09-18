# DBMS Selection — chọn hệ quản trị bằng lập luận, không bằng mặc định

Dùng ở **Stage 1B**, sau khi đã có `01-data-requirements.md`. Trước Stage 1 thì
chưa có gì để lập luận; sau Stage 2 thì mô hình đã bị định hình bởi một engine
chưa ai chọn.

> **Bộ skill này không có DBMS mặc định.** Một lựa chọn không có lập luận vẫn có
> thể *đúng*, nhưng nó không review được, không bàn giao được, và không ai biết
> phải xem lại nó khi nào.

---

## 1. Driver phải lấy từ requirement, không lấy từ cảm tính

Mỗi driver dưới đây chỉ được đưa vào bảng quyết định khi **trỏ được về một ID**
trong `01-data-requirements.md`. Driver không có ID là sở thích, phải ghi riêng.

| Driver | Tín hiệu trong requirement | Nó đòi gì ở engine |
|---|---|---|
| Khối lượng & retention | `VP-*` số dòng/tháng, thời gian lưu | partition khai báo, `DROP PARTITION`, nén, archive tier |
| Truy vấn nóng có SLA | `VP-*` "dưới N giây" | partial/filtered index, covering index, plan ổn định |
| Ghi nặng đồng thời | `VP-*` số ghi/giây | MVCC vs lock, chi phí UPDATE, khoá hàng nóng |
| Ràng buộc liên dòng | `BR-*` "tổng phải bằng", "không được chồng lấn" | `EXCLUDE`, deferred constraint, constraint trigger |
| Ràng buộc có điều kiện | `BR-*` "duy nhất khi đang hiệu lực" | partial unique index |
| Lịch sử / bất biến | `BR-*` "phải xem lại được", "đã chốt không sửa" | trigger, quyền cột/bảng, temporal table |
| Dữ liệu ngoài hệ thống | `NF-*`/`BR-*` payload, webhook, snapshot | JSON có index (`jsonb`, JSON path) |
| Đa đơn vị | `NF-*` multi-tenant | RLS, schema-per-tenant, quyền chi tiết |
| PII | `NF-*` che/mã hoá | mã hoá cột, masking động, view + quyền |
| Địa lý / tìm kiếm chuỗi | `VP-*` bản đồ, full-text | PostGIS, trigram, full-text engine |
| Phân tích | `VP-*` báo cáo đa chiều | replica, columnar, MV tăng dần |
| Tính đúng của tiền | `BR-*` công thức tiền | decimal đúng, generated column, không float |

## 2. Ràng buộc bối cảnh — ghi thành ràng buộc, đừng ngụy trang thành lập luận

Những thứ này **hợp lệ** và thường quyết định hơn cả tính năng. Nhưng phải ghi
là ràng buộc, không được viết như thể là kết luận kỹ thuật:

- **Đội vận hành đang chạy gì.** Một engine không ai biết backup/restore là rủi
  ro vận hành lớn hơn mọi tính năng nó có.
- **Giấy phép & chi phí.** Oracle/SQL Server tính theo core; MySQL/PostgreSQL không.
- **Nền tảng cloud đã chốt.** RDS/Cloud SQL/Azure SQL giới hạn extension và version.
- **Framework & ORM.** Cái gì đã có driver, migration runner, connection pool sẵn.
- **Tuân thủ & vị trí dữ liệu.** Managed service ở vùng nào, ai giữ khoá.
- **Năng lực nội bộ.** Ai đọc được query plan của engine đó lúc 2 giờ sáng.

Cách viết đúng: *"Chọn X. Lý do kỹ thuật: 3 `BR-*` cần partial unique index.
Ràng buộc bối cảnh: đội đã chạy X 4 năm, có sẵn runbook backup."* — hai phần
tách rời, người review gạch được từng phần.

## 3. Bảng năng lực — dùng để **loại**, không dùng để tính điểm đẹp

`✓` có sẵn · `~` làm được nhưng vòng · `✗` không có

| Năng lực | PostgreSQL 16 | MySQL 8 | SQL Server 2022 | Oracle 19c+ |
|---|---|---|---|---|
| Partition khai báo + `DROP PARTITION` | ✓ | ✓ | ✓ (partition scheme) | ✓ |
| **Partial / filtered index** | ✓ | **✗** | ✓ | ~ (function-based) |
| **Unique có điều kiện** | ✓ (partial UQ) | **✗** (cột sinh + UQ) | ✓ | ~ |
| **`EXCLUDE` / chống chồng lấn khoảng** | ✓ (gist) | **✗** | **✗** | **✗** |
| **Deferred constraint / constraint trigger** | ✓ | **✗** | ✗ (trigger thường) | ✓ (deferrable FK) |
| Generated column (stored) | ✓ | ✓ | ✓ (computed persisted) | ✓ (virtual) |
| JSON có index | ✓ `jsonb` + GIN | ~ JSON + cột sinh | ~ JSON + cột computed | ~ |
| Row-level security | ✓ | ✗ | ✓ | ✓ (VPD) |
| Masking động | ~ (view + quyền) | ✗ | ✓ | ✓ |
| Enum kiểu dữ liệu | ✓ (khó bỏ giá trị) | ✓ `ENUM` | ✗ (CHECK) | ✗ (CHECK) |
| Temporal / system-versioned table | ✗ (làm tay) | ✗ | ✓ | ✓ (Flashback) |
| Full-text / trigram | ✓ + `pg_trgm` | ✓ | ✓ | ✓ |
| Địa lý | ✓ PostGIS | ~ | ✓ | ✓ |
| Columnar / analytics tại chỗ | ✗ (extension) | ✗ | ✓ (columnstore) | ✓ |
| Giấy phép mở | ✓ | ✓ (GPL/thương mại) | ✗ | ✗ |

> Bảng này là **năng lực**, không phải thứ tự ưu tiên. Một dòng `✗` chỉ quan
> trọng khi có `BR-*`/`VP-*` cần tới nó — và khi đó nó **loại** ứng viên, không
> phải trừ điểm.

## 4. Quy trình chấm — 5 bước, không tính điểm tổng

1. **Must-have**: driver nào là *điều kiện đúng đắn* (rule sẽ mất chỗ ép nếu
   thiếu). Ứng viên thiếu một must-have thì **bị loại**, không cứu bằng điểm khác.
2. **Đếm rule mất chỗ ép**: với mỗi ứng viên, đếm số `BR-*` phải đẩy xuống tầng
   ứng dụng. Đây là con số có ý nghĩa nhất của cả bước chọn — nó biến "khác
   phương ngữ" thành "mất bao nhiêu bảo đảm".
3. **Nice-to-have**: so sánh bằng chữ, không bằng thang điểm giả.
4. **Ràng buộc bối cảnh (§2)** — có thể đảo kết quả §1–3, và khi đảo thì phải
   ghi rõ *"chọn ngược kết luận kỹ thuật vì ràng buộc Y"*.
5. **Trigger xem lại**: điều gì xảy ra thì quyết định này phải mở lại.

Tránh **điểm tổng có trọng số**: nó cho một con số trông khách quan từ những
trọng số do chính agent bịa ra. Loại theo must-have + đếm rule mất mát thì
người review kiểm được từng dòng.

## 5. Một engine thường không phải cả câu trả lời

Xem `references/storage-topology.md`. Ở bước này chỉ cần **đánh dấu** các thành
phần bổ trợ có thể cần (hàng đợi, cache, tìm kiếm, phân tích, lưu trữ lạnh) và
nói rõ cái nào **được quyết định trong phạm vi thiết kế database này**, cái nào
là quyết định kiến trúc nằm ngoài. Đừng âm thầm giả định "mọi thứ nằm trong DB".

## 6. Bốn cách chọn sai kinh điển

| Cách sai | Vì sao sai | Cách đúng |
|---|---|---|
| Lấy mặc định của tool | Kết luận không có tiền đề; không ai biết khi nào phải xem lại | Vẫn phải viết ADR, kể cả khi kết luận trùng mặc định |
| Chọn theo cái mới nhất/phổ biến nhất | Requirement không xuất hiện trong lập luận | Bắt đầu từ `VP-*`/`BR-*`/`NF-*` |
| Chọn rồi mới tìm lý do | Bảng so sánh được viết ngược để ra kết quả đã định | Viết must-have **trước** khi mở bảng năng lực |
| Đánh giá thấp cái giá đổi nền tảng | "Chỉ khác cú pháp" — thực ra mất cả ràng buộc | Đếm rule mất chỗ ép (§4.2) + `dbms-notes.md §Portability budget` |
