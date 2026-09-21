# Concurrency — rule nào KHÔNG ép được khi có hai request cùng lúc

Dùng ở **Stage 3** (phân loại `BR-*` theo lớp nguy hiểm) và **Stage 4** (chốt
cơ chế, viết khẳng định chạy song song).

`review-checklist.md §9` hỏi: *"hai request cùng lúc có vượt được hạn mức /
tạo bản ghi trùng / lấy trùng việc không?"* — tài liệu này là **cách trả lời**
câu đó. Không có nó thì câu hỏi chỉ sinh ra một dòng "đã kiểm, ổn".

---

## 1. Ghi ra mức cô lập (isolation level) đang giả định

Mọi lập luận về `BR-*` đều ngầm giả định một mức cô lập. Mức mặc định khác nhau
theo engine, nên **giả định không ghi ra là giả định sai ở engine khác**:

| Engine | Mặc định | Hệ quả đáng chú ý |
|---|---|---|
| PostgreSQL | Read Committed | mỗi câu lệnh thấy snapshot mới; `SELECT` rồi `INSERT` **không** nguyên tử |
| MySQL / InnoDB | Repeatable Read | có gap lock nên chặn được một số phantom, nhưng theo cách riêng của InnoDB |
| SQL Server | Read Committed (lock-based, trừ khi bật RCSI) | đọc có thể chặn ghi — hồ sơ khoá khác hẳn |
| Oracle | Read Committed | không có dirty read; writer không chặn reader |

Ghi một dòng vào `04-migration-notes.md`: *"Mức cô lập giả định: `<mức>`. Giao
dịch chạy ở mức cao hơn: `<liệt kê hoặc không có>`."*

## 2. Ba lớp `BR-*` không tự ép được ở mức mặc định

Đây là phần hay bị bỏ sót nhất: rule **có** ghi trong tài liệu, **có** một
`CHECK` hoặc một đoạn code trông đúng, và vẫn bị vượt khi có hai request.

### Lớp A — "tối đa N" / hạn mức / tồn kho

```sql
-- SAI dưới Read Committed: hai transaction cùng đọc thấy 4, cùng chèn ⇒ thành 6
SELECT count(*) FROM booking WHERE slot_id = :s;   -- trả về 4, giới hạn là 5
INSERT INTO booking(slot_id, ...) VALUES (:s, ...);
```

`CHECK` **không** cứu được: `CHECK` chỉ nhìn một dòng, không đếm được dòng khác.

### Lớp B — "duy nhất" kiểm bằng SELECT rồi INSERT

```sql
SELECT 1 FROM customer WHERE tax_code = :t;  -- không có
INSERT INTO customer(tax_code, ...) VALUES (:t, ...);  -- hai request cùng lọt
```

### Lớp C — "không chồng lấn khoảng" (lịch, hiệu lực, giá theo kỳ)

Hai khoảng thời gian cùng được kiểm là "trống" rồi cùng được chèn. Đây là lớp
khó nhất vì không có khoá bằng nào để đụng nhau.

> **Cách nhận ra ở Stage 3:** bất kỳ `BR-*` nào phải **đọc dòng khác** để quyết
> định dòng này hợp lệ hay không đều thuộc một trong ba lớp trên. Rule chỉ nhìn
> trong một dòng (`amount > 0`, `end_date >= start_date`) thì an toàn.

## 3. Bốn cách ép, theo thứ tự nên ưu tiên

| # | Cơ chế | Ép được lớp | Cái giá |
|---|---|---|---|
| 1 | **Unique index** (kể cả partial / trên cột sinh) | B | gần như không; database tự chặn, không phụ thuộc code |
| 2 | **`EXCLUDE USING gist`** (PostgreSQL) | C | chỉ PostgreSQL — vào ngân sách khả chuyển |
| 3 | **`SELECT … FOR UPDATE`** trên **dòng cha** rồi mới đếm/chèn | A, C | tuần tự hoá theo cha; phải chọn đúng dòng cha và luôn khoá cùng thứ tự |
| 4 | **`SERIALIZABLE`** cho đúng giao dịch đó | A, B, C | ứng dụng **phải** retry khi serialization failure — không retry thì chỉ đổi lỗi này lấy lỗi khác |

Nguyên tắc chọn: **ưu tiên ràng buộc khai báo hơn khoá tường minh.** Một unique
index đúng chặn được cả những đường ghi mà không ai nhớ tới (job, script sửa
tay, migration). Một `FOR UPDATE` chỉ chặn đúng đoạn code có viết nó.

Với lớp A, mẹo biến A thành B: nếu "tối đa N" có thể biểu diễn bằng **số thứ tự**
(`seat_no`, `slot_index` 1..N) thì `UNIQUE(parent_id, seq)` + `CHECK (seq
BETWEEN 1 AND N)` đưa bài toán đếm về bài toán duy nhất — database ép được, không
cần khoá.

## 4. Optimistic lock — "lost update" giữa hai màn hình sửa

Hai người mở cùng một bản ghi, cùng sửa, người lưu sau **ghi đè** thay đổi của
người lưu trước mà không ai biết. Không transaction nào bị lỗi — dữ liệu chỉ
đơn giản là mất.

Xem `modeling-patterns.md §13` cho cột `version`. Điều phải quyết ở Stage 3:
**bảng nào cần**? Tiêu chí: bản ghi có màn hình sửa dùng chung bởi nhiều người,
và mất một lần sửa là hậu quả nghiệp vụ thật (hồ sơ khách, đơn hàng đang xử lý,
cấu hình). Bảng chỉ append (log, event) thì không cần.

## 5. Deadlock — không phải lỗi hiếm, là hệ quả của thứ tự khoá

Hai transaction khoá cùng một tập dòng theo **thứ tự khác nhau** thì sẽ deadlock.
Ba việc phải làm, cả ba đều thuộc thiết kế:

1. **Quy ước thứ tự khoá** — luôn khoá theo cùng một thứ tự (ví dụ `id` tăng
   dần), viết vào `04-migration-notes.md`. Batch update không `ORDER BY` là
   nguồn deadlock kinh điển.
2. **Giữ transaction ngắn** — không gọi API ngoài, không chờ người dùng, bên
   trong một transaction đang giữ khoá.
3. **Ứng dụng phải retry** — deadlock và serialization failure là lỗi *tạm thời*
   và **được kỳ vọng**. Ghi vào `05-app-enforced-rules.md`: thao tác nào phải
   retry, bao nhiêu lần. Retry được chỉ khi thao tác idempotent (xem
   `modeling-patterns.md §12`).

## 6. Hàng đợi và bộ đếm — trỏ tới chỗ đã viết

- **Nhận việc trùng** (nhiều worker cùng lấy một dòng): `SKIP LOCKED` hoặc lease
  — `storage-topology.md §1`, `indexing-and-performance.md §Write path 3`.
- **Khoá hàng nóng** (mọi transaction cùng sửa một dòng đếm):
  `indexing-and-performance.md §Write path 2`.

Hai mục đó là bài toán đồng thời, chỉ nằm ở file khác vì chúng cũng là bài toán
hiệu năng. Đừng trả lời `§9` của review checklist mà bỏ qua chúng.

## 7. Chứng minh, đừng khẳng định

Với mỗi `BR-*` thuộc lớp A/B/C ở §2, Stage 4 phải viết vào `05-assertions.sql`
một cặp khẳng định — **đúng cùng quy tắc hai chiều** của Bước 5b:

- hai thao tác **đồng thời** cùng vi phạm ⇒ đúng một cái được chấp nhận;
- một thao tác hợp lệ nhưng gần giống ⇒ **không** bị chặn oan.

Chạy tuần tự trong một session thì không tái hiện được lớp A và C. Khi không có
cách chạy hai session song song, ghi thẳng: *"`BR-xxx`: cơ chế là `<unique /
FOR UPDATE / SERIALIZABLE>`, **chưa thử đồng thời**"* — cùng quy tắc trung thực
ba trạng thái như restore drill (`durability-and-availability.md §5`).

## 8. Checklist

- [ ] Mức cô lập giả định đã ghi ra, kèm engine
- [ ] Mọi `BR-*` phải đọc dòng khác để quyết định đã được phân lớp A / B / C
- [ ] Mỗi rule đã phân lớp có đúng một cơ chế ở §3, không phải chỉ có `CHECK`
- [ ] Bảng nào cần cột `version` đã được quyết, có lý do
- [ ] Thứ tự khoá đã quy ước; batch update có `ORDER BY`
- [ ] Thao tác nào ứng dụng phải retry đã nằm trong `05-app-enforced-rules.md`
- [ ] Rule lớp A/B/C có khẳng định đồng thời — hoặc ghi rõ **chưa thử đồng thời**
