# Indexing & Performance

Dùng ở Stage 4. Mọi index phải truy ngược được về một truy vấn trong `VP-*`.

## Quy tắc chọn index

1. **FK ở phía con**: gần như luôn cần (join + kiểm tra khi xóa cha).
2. **Thứ tự cột trong composite index**: cột lọc bằng `=` trước → cột range
   (`>`, `BETWEEN`) → cột sort. Index `(a, b)` phục vụ được truy vấn lọc theo
   `a`, nhưng không phục vụ truy vấn chỉ lọc theo `b`.
3. **Covering index**: thêm cột `INCLUDE` khi truy vấn chỉ đọc vài cột và chạy rất nhiều.
4. **Partial index**: `WHERE status = 'pending'` khi chỉ một phần nhỏ dòng được
   truy vấn thường xuyên; cũng là cách làm unique có điều kiện cho soft delete.
5. **Text search**: `LIKE 'abc%'` dùng được B-tree; `LIKE '%abc%'` thì cần
   trigram (`pg_trgm`) hoặc full-text index.
6. **Cột lệch phân bố cực đoan** (99% một giá trị): index toàn phần thường vô ích.

## Chi phí

Mỗi index: chậm INSERT/UPDATE/DELETE, tốn dung lượng, tốn thời gian rebuild.
Bảng ghi nhiều (log, event) nên có ít index nhất có thể.

## Write path & concurrency — phần hay bị bỏ trống nhất

Index phục vụ ĐỌC. Bốn thứ dưới đây quyết định bảng có sống nổi khi GHI, và
chúng không xuất hiện trong bất kỳ bảng index nào.

### 1. Ngân sách UPDATE

Với mỗi bảng nóng, trả lời bằng số: **một dòng bị UPDATE mấy lần trong đời?**

| Nếu | Hệ quả | Phải ghi gì |
|---|---|---|
| dòng chỉ INSERT rồi không đổi | rẻ nhất | không cần gì |
| dòng bị update vài lần, **không** đổi cột đang được index | PostgreSQL có thể dùng HOT update — chỉ sửa heap | nói rõ cột nào không bao giờ đổi |
| dòng bị update và **có** đổi cột được index | mỗi update sửa **tất cả** index chứa cột đó | đếm: số update × số index bị ảnh hưởng |

Hệ quả kèm theo trên bảng lớn: bloat, autovacuum chạy nặng hơn, index phình.
Với bảng nhiều update nên ghi rõ `fillfactor` thấp hơn mặc định và kỳ vọng
autovacuum — đây là tham số thiết kế, không phải việc của DBA tự đoán.

### 2. Khoá hàng nóng (hot row)

Một bộ đếm materialise (`used_count`, `balance`, `seq`) là **một dòng** mà mọi
transaction cùng sửa. Ở vài trăm ghi/giây, dòng đó là khoá nóng nhất hệ thống.

Kiểm trước khi chốt: bộ đếm có grain thế nào? Nếu là *một dòng cho cả hệ thống*
→ thiết kế lại (chia grain theo tenant/kỳ, hoặc đưa ra ngoài DB). Riêng **đếm
theo giây (rate limit)** thì không nên nằm trong DB — nó thuộc cache/limiter,
DB chỉ giữ *giá trị cấu hình*.

### 3. Nhận việc từ hàng đợi (claim)

Nếu có bảng dạng hàng đợi (cột trạng thái + worker `SELECT ... LIMIT n`), thì
**index partial là chưa đủ** — thiếu cơ chế claim thì nhiều worker lấy trùng:

- `SELECT ... FOR UPDATE SKIP LOCKED LIMIT n` (PostgreSQL 9.5+, MySQL 8+), hoặc
- cột lease (`locked_by`, `locked_until`) + `UPDATE ... WHERE locked_until < now()`.

Kèm theo: đường ra cho việc chết (retry bao nhiêu, dead-letter đi đâu, ai phát
hiện). Xem `references/storage-topology.md §1`.

### 4. Kết nối & tách đọc/ghi

Số worker × pool size phải nằm dưới giới hạn kết nối của engine; vượt thì cần
pooler. Truy vấn báo cáo nặng nên chạy trên replica — và phải nói rõ **báo cáo
nào KHÔNG chịu được dữ liệu cũ** (thường là đối soát tiền), vì một role
`readonly` không nói được điều đó.

## Partitioning

Cân nhắc khi bảng dự kiến >50–100M dòng hoặc có retention theo thời gian.

| Kiểu | Khi nào | Khóa |
|---|---|---|
| Range theo thời gian | log, giao dịch, có retention | `created_at` theo tháng/năm |
| List theo tenant/vùng | multi-tenant lớn | `tenant_id`, `region` |
| Hash | phân tán đều, không có khóa tự nhiên | id |

Lợi ích lớn nhất: xóa dữ liệu hết hạn bằng `DROP PARTITION` thay vì `DELETE`
hàng loạt.

**Ba nhược điểm phải ghi ra, không được để người sau tự phát hiện:**

1. **Mọi unique constraint phải chứa khóa phân mảnh** ⇒ ràng buộc "duy nhất toàn
   cục" trên bảng đó **mất chỗ ép ở database**. Đây là một quyết định lưu trữ vật
   lý gỡ bỏ một bảo đảm về tính đúng đắn — liệt kê đúng `BR-*` nào bị ảnh hưởng.
2. **Join bảng partition với bảng không partition làm mất pruning** ⇒ thường phải
   denormalize thêm cột (mỗi cột là một `DN-*` phải khai báo).
3. **Biên partition vs múi giờ predicate:** biên theo múi giờ nghiệp vụ + truy
   vấn viết theo UTC = âm thầm quét hai partition. Cần helper xây khoảng đúng múi giờ.

Vòng đời partition là **job**, không phải cấu hình: tạo trước N kỳ (cảnh báo khi
còn ít), drop theo retention. Không nên có `DEFAULT` partition — nó âm thầm hút
những dòng lẽ ra phải fail, và tách nó ra sau này cần quét toàn bảng.

## Checklist hiệu năng trước khi chốt

- [ ] Mỗi báo cáo trong `VP-*` có đường index rõ ràng
- [ ] Không có truy vấn nóng nào phải quét toàn bảng lớn
- [ ] Không có N+1 do thiếu bảng tổng hợp cho dashboard
- [ ] Bảng ghi nhiều không bị gánh quá nhiều index
- [ ] Đã ước lượng dung lượng: dòng/ngày × kích thước dòng × retention
- [ ] Đã xác định dữ liệu nào archive và archive đi đâu
- [ ] Truy vấn báo cáo nặng cân nhắc read replica / materialized view
- [ ] Đã đếm ngân sách UPDATE cho từng bảng nóng (số update × số index bị sửa)
- [ ] Không có bộ đếm dùng chung một dòng cho cả hệ thống
- [ ] Bảng hàng đợi có cơ chế claim (`SKIP LOCKED` / lease), không chỉ index partial
- [ ] Bảng partition: đã liệt kê `BR-*` mất chỗ ép + job tạo/drop partition
- [ ] Báo cáo nào **không** chịu được dữ liệu cũ đã được nói rõ
