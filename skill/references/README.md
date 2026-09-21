# `references/` — tra cứu theo nhu cầu, không nạp cả bộ

Twelve reference documents. **Load only what the current stage needs.**

Đây không phải tài liệu để đọc từ đầu đến cuối. Mỗi file trả lời một nhóm câu
hỏi cụ thể, và `SKILL.md` của từng giai đoạn tự chỉ ra nó cần file nào
(progressive disclosure). Nạp cả 12 file cho một giai đoạn là tốn context cho
thứ giai đoạn đó không dùng.

> Muốn biết **thứ tự công việc**, đọc `../SKILL.md` và `../skills/*/SKILL.md`.
> Thư mục này chỉ trả lời "quyết định này nên cân nhắc những gì".

---

## Nạp file nào ở giai đoạn nào

| Stage | Đọc | Có thể cần |
|---|---|---|
| 0 — Intake | — | `extraction-checklist.md` (xem trước phạm vi) |
| 1 — Requirements | `extraction-checklist.md` | — |
| 1B — DBMS | `dbms-selection.md`, `storage-topology.md` | `durability-and-availability.md`, `concurrency.md`, `dbms-notes.md` |
| 2 — Conceptual | `modeling-patterns.md` | `anti-patterns.md` |
| 3 — Logical | `normalization.md`, `naming-conventions.md`, `modeling-patterns.md`, `anti-patterns.md` | `concurrency.md` |
| 4 — Physical | `indexing-and-performance.md`, `dbms-notes.md`, `storage-topology.md`, `durability-and-availability.md`, `concurrency.md` | `naming-conventions.md` |
| 5 — Review | `review-checklist.md` | `anti-patterns.md` |

## Từng file

### `extraction-checklist.md` — Stage 1
12 nhóm tín hiệu phải quét trong tài liệu BA (danh từ nghiệp vụ, biểu mẫu, trạng
thái, lượng từ, báo cáo, khối lượng, tuân thủ…), cách phân biệt **entity** với
**attribute** với **enum**, và 11 câu hỏi luôn phải hỏi khi tài liệu im lặng.
Kèm mục D: dấu hiệu checklist đang **làm hại** thay vì giúp — dùng ở lượt 2,
không phải lượt 1.

### `dbms-selection.md` — Stage 1B
Cách chọn hệ quản trị **bằng lập luận thay vì mặc định**: driver phải trỏ về một
requirement ID, ràng buộc bối cảnh (đội đang chạy gì, giấy phép, cloud) ghi tách
khỏi lý do kỹ thuật, bảng năng lực 4 engine dùng để **loại ứng viên** chứ không
để tính điểm, và bốn cách chọn sai kinh điển.

### `storage-topology.md` — Stage 1B (đánh dấu) · Stage 4 (chốt)
Những quyết định công nghệ mà chữ "một cái database" che mất: hàng đợi trong DB
hay broker (kèm outbox/CDC nếu chọn broker), aggregate là view / materialized
view / bảng thật, enum kiểu dữ liệu hay bảng danh mục, lưu trữ nóng–lạnh, hợp
đồng cache (ghi thế nào, TTL, `BR-*` nào **không** được đọc từ cache), tách
đọc/ghi, và giả định **một node ghi** phải được ghi ra chứ không im lặng.

### `durability-and-availability.md` — Stage 1B (đánh dấu) · Stage 4 (chốt)
Hỏng thì **mất bao nhiêu dữ liệu** (RPO) và **ngừng bao lâu** (RTO) — hai con số
lấy từ `BR-*`/`NF-*`, theo nhóm bảng. Backup là *phương tiện* và phải đủ cho mục
tiêu đó (full backup hàng đêm ≠ RPO 5 phút). Kèm: replica topology + ngân sách
độ trễ, bẫy read-after-write, failover ai gọi, **restore drill theo quy tắc ba
trạng thái** (`verified` / `partial` / `not tested`), và ngưỡng phải xem lại giả
định một node ghi.

### `concurrency.md` — Stage 3 (phân lớp) · Stage 4 (chốt cơ chế)
Rule nào **không tự ép được** khi có hai request cùng lúc. Ghi mức cô lập đang
giả định (mặc định khác nhau theo engine), phân lớp mọi `BR-*` phải đọc dòng
khác — **A** hạn mức · **B** duy nhất kiểm bằng `SELECT` rồi `INSERT` ·
**C** chồng lấn khoảng — rồi chọn cơ chế theo thứ tự ưu tiên: unique index →
`EXCLUDE` → `SELECT … FOR UPDATE` → `SERIALIZABLE` + retry. Kèm optimistic lock,
thứ tự khoá chống deadlock, và yêu cầu **thử đồng thời**, không chỉ thử tuần tự.

### `normalization.md` — Stage 3
1NF → BCNF bằng ví dụ, và bốn thứ phải ghi ra trước khi chấp nhận denormalize
(what / why / cách đồng bộ / rủi ro). Denormalization dùng namespace `DN-*`,
không dùng `D-*` — `D-*` thuộc về quyết định mô hình ở Stage 2.

### `naming-conventions.md` — Stage 3, 4
Quy ước đặt tên bảng/cột/ràng buộc/index, kiểu dữ liệu chuẩn theo từng DBMS,
cột audit bắt buộc, và các từ khoá SQL phải tránh. Code và tên luôn tiếng Anh,
`snake_case`.

### `modeling-patterns.md` — Stage 2, 3
14 pattern hay dùng kèm **cái giá** của từng cái: audit columns, soft delete,
SCD/versioning, multi-tenancy, party model, kế thừa, cây phân cấp, reference
data, state machine, i18n, tiền & đơn vị, idempotency, **optimistic lock
(`version`)**, và **xoá dữ liệu cá nhân vs audit trail** — hai nghĩa vụ ngược
nhau, và cách giải quyết định hình schema.

### `anti-patterns.md` — Stage 2, 3, 5
16 anti-pattern: EAV, polymorphic FK, god table, float cho tiền, giá trị ngăn
cách bằng dấu phẩy… Mỗi mục kèm dấu hiệu nhận ra và cách làm đúng. Dùng như một
lượt quét, không phải để đọc thuộc.

### `indexing-and-performance.md` — Stage 4
Chọn index (thứ tự cột composite, covering, partial, text search), chi phí của
mỗi index, **đường ghi** — ngân sách UPDATE, khoá hàng nóng, cơ chế nhận việc từ
hàng đợi, kết nối/tách đọc–ghi — partition kèm **ba nhược điểm phải ghi ra**, và
**quan sát được**: log truy vấn chậm với ngưỡng lấy từ `VP-*`, thống kê tích luỹ,
index không ai dùng, `EXPLAIN` trên dữ liệu đủ lớn.

### `dbms-notes.md` — Stage 1B, 4
Khác biệt thực dụng giữa PostgreSQL · MySQL 8 · SQL Server · Oracle: kiểu dữ
liệu, cú pháp, thứ được và không được, và **ngân sách khả chuyển** (dùng tính
năng độc quyền nào, `BR-*` nào phụ thuộc nó, đổi engine thì mất gì).

### `review-checklist.md` — Stage 5
Checklist nghiệm thu, 9 nhóm, đánh `PASS / FAIL / N-A` cho từng mục. Nhóm 1–8
xác nhận thiết kế **đã làm những gì nó nói**; **nhóm 9 là lượt đọc đối kháng** —
nhóm duy nhất sinh ra finding mới, và nên chạy bằng một agent riêng chỉ được đưa
DDL + requirement, không đưa phần biện minh.

---

## Quy tắc chung cho mọi file ở đây

1. **Không có mặc định im lặng.** Mỗi quyết định phải xuất hiện thành một dòng
   trong artifact, kể cả khi kết luận trùng với thứ ai cũng sẽ chọn — người sau
   cần chỗ để phản đối.
2. **Chưa kiểm thì nói là chưa kiểm.** DDL chưa chạy, restore chưa thử, rule
   chưa thử đồng thời, `EXPLAIN` chưa chạy trên dữ liệu thật — trạng thái "chưa"
   là câu trả lời hợp lệ; im lặng thì không.
3. **Mỗi pattern là một chi phí.** Không áp dụng vì nó "chuẩn", chỉ áp dụng khi
   có requirement đòi.

Sửa một file ở đây thì nhớ: `../MANIFEST` liệt kê file bắt buộc, `../SKILL.md`
giữ mục lục tham chiếu, và `test/skill.test.mjs` có regression guard cho phần
lớn nội dung dưới đây — chạy `npm test` sau khi sửa.
