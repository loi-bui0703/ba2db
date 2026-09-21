# Storage Topology — những quyết định công nghệ mà "một cái database" che mất

Dùng ở **Stage 1B** (đánh dấu) và **Stage 4** (chốt và ghi hệ quả).

Mỗi mục dưới đây là một quyết định **thật**, có đánh đổi thật. Nguy hiểm không
nằm ở việc chọn sai, mà ở việc **không nhận ra mình đang chọn** — khi đó không
có dòng nào trong tài liệu để người sau phản đối.

---

## 1. Hàng đợi: trong database hay broker riêng?

Dấu hiệu bạn đang xây hàng đợi trong DB mà không biết: một bảng có cột trạng
thái, một index `WHERE status = 'PENDING'`, và một worker `SELECT ... LIMIT n`.

| | Queue-in-database | Broker (Kafka / Redis / SQS / RabbitMQ) |
|---|---|---|
| Nhận việc + ghi dữ liệu trong **một transaction** | ✓ — không có bài toán outbox | ✗ — cần outbox/CDC |
| Tra cứu, báo cáo, audit trên chính hàng đợi | ✓ bằng SQL | ✗ phải sao sang DB |
| Thông lượng | vài trăm → vài nghìn/giây | cao hơn hẳn |
| Chi phí ẩn | UPDATE liên tục trên bảng lớn: bloat, autovacuum, index maintenance | một hệ thống nữa phải vận hành, và hai nguồn sự thật |
| Hạ tầng | không thêm gì | thêm cluster, thêm runbook |

**Nếu chọn queue-in-database, bốn thứ sau là bắt buộc, không phải tuỳ chọn:**

1. **Cơ chế nhận việc (claim)** — nhiều worker phải không lấy trùng:
   `SELECT ... FOR UPDATE SKIP LOCKED LIMIT n` (PostgreSQL 9.5+, MySQL 8+), hoặc
   cột lease (`locked_by`, `locked_until`) + `UPDATE ... WHERE locked_until < now()`.
   Không có cơ chế này thì thiết kế **sai**, không phải "chưa tối ưu".
2. **Index partial trên đúng trạng thái đang chờ** — không index toàn phần cột
   trạng thái lệch 99%.
3. **Ngân sách UPDATE** — mỗi dòng bị update mấy lần? mỗi update phải sửa mấy
   index? (xem `references/indexing-and-performance.md §Write path`).
4. **Đường ra cho việc chết** — dòng bị lấy rồi không ai hoàn thành: retry đến
   bao giờ, chuyển đi đâu (dead-letter), ai phát hiện.

### 1b. Nếu chọn broker: outbox hay CDC — định nghĩa, không phải một chữ viết tắt

Bảng trên ghi broker ⇒ "cần outbox/CDC". Đây là **bài toán ghi hai nơi**: ghi
vào DB và publish vào broker không nằm trong cùng một transaction, nên hỏng ở
giữa sẽ để lại một trong hai trạng thái sai — đã ghi mà không ai biết, hoặc đã
báo mà chưa ghi. `try { save(); publish(); }` không giải được; nó chỉ làm cửa
sổ hỏng nhỏ lại.

| Cách | Cơ chế | Cái giá | Khi nào chọn |
|---|---|---|---|
| **Outbox** | cùng transaction với dữ liệu, `INSERT` một dòng vào bảng `outbox`; một relay đọc bảng đó và publish, đánh dấu đã gửi | thêm một bảng ghi nhiều + một relay; chính bảng outbox là queue-in-database ⇒ **phải đủ bốn điều kiện ở §1** | mặc định; không cần quyền đặc biệt trên DB |
| **CDC** | đọc WAL/binlog (Debezium…) và phát ra sự kiện | cần quyền replication, thêm hạ tầng; sự kiện mang **hình dạng bảng**, đổi schema là đổi hợp đồng của consumer | đã có hạ tầng CDC, hoặc cần bắt mọi thay đổi kể cả từ script sửa tay |

Ba thứ phải ghi ra khi chọn outbox, vì thiếu là sai chứ không phải chưa tối ưu:

1. **Bảo đảm là *at-least-once*, không phải *exactly-once*.** Relay có thể
   publish rồi chết trước khi đánh dấu ⇒ consumer **phải** idempotent
   (`modeling-patterns.md §12`). Ghi rõ khoá idempotency là gì.
2. **Thứ tự.** Nếu nghiệp vụ cần đúng thứ tự cho một thực thể, relay phải gửi
   tuần tự theo khoá đó — nói rõ khoá phân vùng thứ tự.
3. **Dọn bảng outbox.** Dòng đã gửi giữ bao lâu, ai xoá — một job, phải nằm
   trong `04-migration-notes.md §7`.

## 2. Aggregate: view, materialized view, hay bảng thật?

Câu hỏi phân định **không phải** "chậm hay nhanh", mà:

> **Aggregate có phải sống lâu hơn dữ liệu chi tiết sinh ra nó không?**

| Trường hợp | Chọn | Vì sao |
|---|---|---|
| Luôn tính lại được từ chi tiết, không cần nhanh | view | không có gì lệch được |
| Tính lại được, cần nhanh, chịu được độ trễ | materialized view | refresh là cơ chế có sẵn |
| **Chi tiết sẽ bị xoá/purge trước aggregate** | **bảng thật** | Một MV **chết cùng** partition bị drop. Aggregate lúc này không còn là cache mà là **sự thật của bản ghi** |

Chọn "bảng thật" kéo theo một nghĩa vụ phải ghi vào `04-migration-notes.md`:
job tổng hợp **không được bỏ sót ngày nào**, vì sau khi chi tiết bị purge thì
không có cách tính lại. Kèm theo phải có cách **phát hiện ngày bị thiếu**.

## 3. Enum kiểu dữ liệu hay bảng danh mục?

Cả hai đều đúng ở chỗ của nó. Tiêu chí chọn, theo thứ tự:

1. **Danh mục có mang thuộc tính không?** (ví dụ "kênh này có báo giao thành
   công không") → **bảng**. Enum không mang được thuộc tính.
2. **Có bảng khác khoá theo nó không?** (FK, unique tổ hợp, bảng cấu hình con)
   → **bảng**.
3. **Người vận hành có thêm giá trị lúc chạy không?** → **bảng**.
4. **Tần suất thêm giá trị:** mỗi lần thêm vào enum PostgreSQL là
   `ALTER TYPE ... ADD VALUE` — **không rollback được** và không chạy chung
   transaction với migration khác. Danh mục sẽ phình (mã lỗi, lý do từ chối,
   loại sự kiện) → **bảng**.
5. Còn lại — tập cố định, thuần phân loại, đổi cùng với code (`ACTIVE/INACTIVE`)
   → **enum** hoặc `CHECK`, và ghi rõ đã chọn.

> Sai kinh điển: một danh mục dạng "lý do" (`rejection_reason`,
> `suppression_reason`) làm enum. Nó luôn dài ra theo nghiệp vụ, và mọi lần dài
> ra là một migration không rollback được.

## 4. Lưu trữ nóng / lạnh

Nếu `VP-*` có hai mốc retention khác nhau (chi tiết ngắn, báo cáo dài), hoặc
tài liệu BA nhắc "lưu trữ lạnh", thì **archive là một phần của thiết kế**, không
phải việc tính sau. Phải chốt: dữ liệu đi đâu (bảng archive / object storage /
DB khác), ai còn truy vấn được, định dạng gì, và **đường về** khi cần điều tra.

Chưa chốt thì ghi thành `OPEN QUESTION` và nói rõ nó ảnh hưởng gì (thường là
granularity partition và tổng dung lượng).

## 5. Cache, tìm kiếm, phân tích — ranh giới phạm vi

| Thành phần | Dấu hiệu cần | Ghi ở đâu |
|---|---|---|
| Cache (Redis/memcached) | đọc lặp cực nhiều trên dữ liệu ít đổi; **rate limit theo giây** | Đếm theo giây **không** nên nằm trong DB: một dòng/tenant sẽ là khoá nóng nhất hệ thống |
| Tìm kiếm (Elastic/OpenSearch) | `LIKE '%...%'` trên bảng lớn, xếp hạng liên quan, tìm nhiều trường | Nếu chỉ tìm chính xác hoặc tiền tố → không cần, B-tree/trigram là đủ |
| Phân tích (warehouse/columnar) | báo cáo đa chiều quét lịch sử dài, khác hẳn hình dạng OLTP | Read replica trước, warehouse sau — đừng nhảy bước |

Với mỗi thành phần: nói rõ **có trong phạm vi thiết kế database này hay không**.
Nếu không, ghi một dòng "quyết định kiến trúc, ngoài phạm vi" — như vậy nó vẫn
hiện ra cho người đọc thay vì biến mất.

### 5b. Nếu có cache: hợp đồng làm mới, không chỉ "dùng Redis"

"Có cache" chưa phải một quyết định. Ba ô dưới đây mới là quyết định, và cả ba
đều ảnh hưởng tới schema:

| Phải chốt | Lựa chọn | Hệ quả lên thiết kế DB |
|---|---|---|
| **Ghi thế nào** | *cache-aside* (ứng dụng đọc miss thì nạp) · *write-through* (ghi cả hai) · *write-behind* (ghi cache trước, DB sau) | write-behind biến cache thành **nguồn sự thật tạm thời** ⇒ mất cache là mất dữ liệu. Chỉ chọn khi chấp nhận được, và khi đó nó thuộc phạm vi thiết kế này |
| **Hết hạn thế nào** | TTL · vô hiệu hoá theo sự kiện · cả hai | TTL cần một con số: **dữ liệu cũ bao lâu thì sai nghiệp vụ?** Lấy từ `VP-*`, không tự đặt 5 phút |
| **Khoá cache dẫn xuất từ gì** | khoá chính · khoá nghiệp vụ · hash của truy vấn | nếu dẫn xuất từ cột có thể đổi, mọi lần đổi phải xoá cả khoá cũ — nói rõ ai xoá |

Và một câu phải trả lời dứt khoát: **`BR-*` nào được phép đọc từ cache?** Hạn
mức, chống trùng, đối soát tiền đọc từ cache là đọc một giá trị có thể đã cũ để
quyết định một việc không hoàn tác được. Những rule đó đọc từ database, và nếu
là rule đồng thời thì xem `references/concurrency.md §2`.

Cache **không** vô hiệu hoá được thì không phải cache — nó là một bản sao thứ
hai của sự thật, và hai bản sao sẽ lệch.

## 6. Đọc/ghi tách nhau

Nếu `VP-*` có báo cáo nặng đi cùng đường ghi nóng, ghi rõ:
truy vấn nào chạy trên replica, độ trễ replica chấp nhận được bao nhiêu, và báo
cáo nào **không** chịu được dữ liệu cũ (thường là đối soát tiền). Một
`readonly` role không nói được điều đó — phải nói ra bằng câu.

Replica là một quyết định **hai mặt**: nó vừa phục vụ đọc, vừa là phương tiện
đạt RPO/RTO. Đồng bộ hay bất đồng bộ, ngân sách độ trễ, failover, và bẫy
read-after-write ("tạo xong xem ngay nhưng đọc trúng replica") nằm ở
`references/durability-and-availability.md §3`. Đừng chốt "có replica đọc" ở đây
rồi để trống phần mục tiêu phục hồi ở Stage 4 — cùng một hạ tầng, hai yêu cầu.

## 7. Một node ghi — giả định mặc định, phải ghi ra

Bộ skill này giả định **một primary ghi**, scale bằng dọc + replica đọc +
partition. Giả định đó đúng cho phần lớn thiết kế đi ra từ tài liệu BA, nhưng
nó phải là một dòng trong `04-migration-notes.md §4`, không phải sự im lặng:
*"Giả định: một node ghi. Ngưỡng phải xem lại: `<số ghi/giây hoặc dung lượng>`."*

Sharding (chia dữ liệu qua **nhiều** database) khác partition (chia trong **một**
database) ở đúng chỗ quan trọng nhất: partition vẫn giữ được transaction và FK
trong cùng một database, sharding thì mất. Nếu `VP-*` hoặc yêu cầu vị trí dữ
liệu (data residency) buộc phải shard, xem
`references/durability-and-availability.md §6` — và liệt kê `BR-*` mất chỗ ép y
như cách Stage 4 làm với partition.
