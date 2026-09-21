---
name: db-design-04-physical-design
description: Stage 4 — produce runnable DDL for the target DBMS plus index, partition, and storage plans driven by the volume requirements.
stage: 4
inputs: 03-logical-schema.md, 03-data-dictionary.md, 01b-dbms-decision.md, VP-* requirements
outputs: 04-schema.sql, 04-index-plan.md, 04-migration-notes.md, 05-assertions.sql
---

# Stage 4 — Physical Design

Ra **DDL chạy được** trên DBMS đã chọn ở Stage 1B + kế hoạch index/partition có
căn cứ.

Header của `04-schema.sql` phải ghi engine + version + `dbms_status` lấy từ
`01b-dbms-decision.md`. Nếu quyết định còn `provisional`, nói rõ trong header —
đừng để người đọc tưởng engine đã được chốt.

## Bước 1 — Sinh DDL

Theo thứ tự trong `templates/04-physical/04-schema.sql`:
1. schema/extension, 2. enum & reference data, 3. bảng (theo thứ tự phụ thuộc
FK), 4. ràng buộc bổ sung, 5. index, 6. view, 7. trigger/function, 8. seed data.

Quy tắc:
- Tên tiếng Anh, `snake_case`, bảng số nhiều hay số ít thì **nhất quán** toàn
  bộ (mặc định: số ít) — `references/naming-conventions.md`.
- Ràng buộc đặt tên tường minh: `pk_`, `fk_<child>_<parent>`, `uq_`, `ck_`, `ix_`.
- Idempotent khi có thể (`IF NOT EXISTS`) để chạy lại được.
- Cú pháp đúng phương ngữ của engine đã chọn — `references/dbms-notes.md`.
- Comment trên bảng/cột (`COMMENT ON` hoặc tương đương) lấy từ data dictionary.

## Bước 2 — Index

Không rải index theo cảm tính. Với mỗi truy vấn nóng trong `VP-*`, ghi một dòng:

| Query | Predicate / sort | Index đề xuất | Lý do |
|---|---|---|---|

Quy tắc theo `references/indexing-and-performance.md`:
- FK gần như luôn cần index ở phía con.
- Composite index: cột lọc bằng (`=`) trước, cột range/sort sau.
- Partial/filtered index cho cột trạng thái lệch phân bố.
- Full-text / trigram cho tìm kiếm chuỗi, không dùng `LIKE '%...%'` trần.
- Mỗi index thêm vào là chi phí ghi — nói rõ đánh đổi.

## Bước 3 — Partition, lưu trữ, vòng đời

Chỉ đề xuất partition khi `VP-*` cho thấy bảng sẽ lớn (thường >50–100M dòng
hoặc có retention theo thời gian). Ghi: khóa phân mảnh, chu kỳ, cách xóa dữ liệu
hết hạn (drop partition thay vì DELETE), nơi lưu dữ liệu lịch sử/archive.

Ba cái giá của partition **phải được ghi ra**, không được để người sau tự phát hiện:

1. **Unique toàn cục biến mất.** Unique index trên bảng partition buộc chứa khoá
   phân mảnh ⇒ mọi `BR-*` dạng "duy nhất toàn cục" trên bảng đó **mất chỗ ép ở
   database**. Liệt kê đúng những `BR-*` nào, và ép thay thế ở đâu.
2. **Cột bị denormalize thêm** để truy vấn không phải join bảng partition với
   bảng không partition (mất pruning) — mỗi cột là một `DN-*`.
3. **Biên partition và múi giờ.** Nếu biên đặt theo múi giờ nghiệp vụ, predicate
   viết theo UTC sẽ **âm thầm mất pruning**. Ghi rõ, và đề xuất một helper xây
   khoảng thời gian đúng múi giờ.

Nếu `VP-*` có hai mốc retention khác nhau, hoặc tài liệu nhắc "lưu trữ lạnh":
archive là **một phần của thiết kế**, không phải việc tính sau —
`references/storage-topology.md §4`.

Nếu thiết kế này triển khai lên một hệ **đang chạy** (không phải database mới),
mỗi thay đổi schema phải chọn một dòng ở `04-migration-notes.md §1b`: chạy thẳng
được, hay cần expand/contract. Thêm một cột `NOT NULL` vào bảng nóng là cách phổ
biến nhất để một thiết kế đúng gây ra downtime — nó khoá bảng để ghi giá trị cho
mọi dòng. Mỗi bước phải chạy được **cùng lúc với cả phiên bản ứng dụng cũ và
mới**; bước nào không thoả là downtime, và downtime phải được ghi kèm con số để
so với RTO.

## Bước 4 — Vận hành

`04-migration-notes.md` ghi: thứ tự triển khai, migration từ hệ thống cũ (nếu
có legacy schema ở Stage 0), phân quyền DB role, mã hóa cột PII theo `NF-*`,
**ngân sách khả chuyển** (`references/dbms-notes.md §Portability budget`).

### Bước 4a — Độ bền & sẵn sàng: viết **mục tiêu**, không chỉ viết phương tiện

"Full backup hàng đêm" là phương tiện. Yêu cầu là **RPO** (được phép mất bao
nhiêu dữ liệu) và **RTO** (được phép ngừng bao lâu), và hai con số đó phải trỏ
về `BR-*`/`NF-*`. Một chính sách backup không có RPO thì không ai kiểm được là
nó đủ hay thiếu — 24 giờ dữ liệu mất là chấp nhận được hay là thảm hoạ?

Điền `04-migration-notes.md §4` theo `references/durability-and-availability.md`:
mục tiêu theo nhóm bảng, phương tiện backup **đủ cho mục tiêu đó**, replica
topology kèm ngân sách độ trễ, failover, và restore drill.

> **Restore drill theo quy tắc ba trạng thái** — đúng quy tắc mà Bước 5 áp cho
> DDL: `verified` / `partial` / **`not tested`**. Backup chưa restore thử thì
> chưa biết là backup. `not tested` là câu trả lời hợp lệ; im lặng thì không.

Hai thứ hay bị bỏ khi đã có replica đọc: **read-after-write** (`PR-*` dạng "tạo
xong xem ngay" đọc trúng replica và không thấy dữ liệu vừa tạo) và danh sách
**báo cáo không chịu được dữ liệu cũ**. Cả hai phải được ghi bằng câu.

Giả định mặc định của bộ skill này là **một node ghi**. Nó vẫn phải được ghi ra
kèm ngưỡng phải xem lại — im lặng không phải là một giả định được ghi.

### Bước 4c — Đồng thời: rule nào không ép được khi có hai request

`review-checklist.md §9` hỏi "hai request cùng lúc có vượt được hạn mức không".
Trả lời được câu đó là việc của Stage 4, theo `references/concurrency.md`:

1. Ghi **mức cô lập giả định** — mặc định khác nhau theo engine, nên giả định
   không ghi ra là giả định sai ở engine khác.
2. Phân lớp mọi `BR-*` phải **đọc dòng khác** để quyết định dòng này hợp lệ:
   **A** hạn mức/đếm · **B** duy nhất kiểm bằng `SELECT` rồi `INSERT` ·
   **C** không chồng lấn khoảng. Rule chỉ nhìn trong một dòng thì an toàn.
3. Chọn cơ chế, **ưu tiên ràng buộc khai báo hơn khoá tường minh**: unique index
   (kể cả partial / trên cột sinh) → `EXCLUDE` → `SELECT … FOR UPDATE` trên dòng
   cha → `SERIALIZABLE` + retry ở ứng dụng.
4. Quy ước **thứ tự khoá** (batch update không `ORDER BY` là deadlock chờ sẵn) và
   ghi thao tác nào ứng dụng phải retry vào `05-app-enforced-rules.md`.

> Một `CHECK` **không** ép được lớp A: nó chỉ nhìn một dòng, không đếm được dòng
> khác. Thấy `CHECK` đứng một mình cho một rule dạng "tối đa N" là thấy một rule
> đã mất chỗ ép mà chưa ai ghi nhận.

### Bước 4b — Đăng ký job vận hành mà schema phụ thuộc

Một thiết kế chỉ đúng khi có những job chạy đều. Những job đó là **phần của
thiết kế**, không phải việc của đội vận hành tự đoán. Với mỗi job ghi bốn ô:
tần suất · **hỏng gì nếu không chạy** · **có hồi phục được không** · **phát hiện
bằng cách nào**.

Thường gặp: tạo partition trước hạn, drop partition theo retention, job tổng hợp
số liệu báo cáo, quét TTL (idempotency/khoá tạm), quét hết hạn theo thời gian,
đối chiếu bộ đếm đã materialise, nhả circuit breaker.

> **Ô nguy hiểm nhất là "có hồi phục được không".** Một job tổng hợp bỏ sót một
> ngày mà dữ liệu chi tiết sau đó bị purge thì ngày đó **mất vĩnh viễn** — không
> có cách tính lại. Job như vậy phải có cơ chế phát hiện thiếu (watermark / bảng
> job-run), không chỉ một dòng trong tài liệu.

## Bước 5 — Chạy thử DDL (bắt buộc cố gắng, không phải tuỳ chọn)

DDL chưa chạy thì chưa biết là đúng. Phần lớn lỗi thật — hàm không IMMUTABLE
trong generated column, unique index trên bảng partition thiếu khoá phân mảnh,
EXCLUDE với kiểu không có operator class — chỉ lộ ra khi chạy.

```bash
bash scripts/validate-ddl.sh workspace/<project>/04-schema.sql postgres
```

Script tự chọn **docker trước** (đúng phiên bản DBMS đích, database sạch), chỉ
dùng client cục bộ khi không có docker. Tuỳ chọn hữu ích:

```bash
--version 15        # thử trên phiên bản khác
--engine local      # ép dùng client cục bộ
--keep              # giữ container lại để tự kiểm tra thêm
--psql "SELECT ..."  # chạy một truy vấn sau khi DDL xong
```

Ba kết quả, ba cách hành xử:

| Exit | Nghĩa | Phải làm gì |
|---|---|---|
| 0 | DDL chạy sạch | Ghi số object đã tạo vào `04-migration-notes.md` |
| 1 | DDL lỗi | **Sửa rồi chạy lại.** Không được bàn giao DDL không chạy được |
| 2 | Không có môi trường | **Nói rõ "DDL chưa được chạy thử"** trong báo cáo. Không viết "DDL hợp lệ" hay "đã kiểm tra cú pháp" |

### Bước 5b — Thử ràng buộc, đừng chỉ thử cú pháp

DDL chạy được mới chỉ chứng minh cú pháp đúng, chưa chứng minh **nghiệp vụ được
ép đúng**. Với mỗi `BR-*` đã ghi là ép ở tầng DB, viết hai khẳng định:

- một thao tác **vi phạm** rule → phải bị từ chối
- một thao tác **hợp lệ nhưng gần giống** → phải được chấp nhận

Vế thứ hai mới là vế hay bắt được lỗi: một `UNIQUE` quá rộng vẫn từ chối đúng
cái sai, nhưng đồng thời từ chối cả cái đúng. Ví dụ: cùng một
`Idempotency-Key` từ **bên tích hợp khác** phải thành công; một địa chỉ bị một
bên tích hợp chặn vẫn phải chặn được bởi bên khác.

Viết các khẳng định vào `workspace/<project>/05-assertions.sql` (khuôn:
`templates/05-review/05-assertions.sql`) rồi chạy cùng lúc với DDL:

```bash
bash scripts/validate-ddl.sh workspace/<project>/04-schema.sql postgres   --assert workspace/<project>/05-assertions.sql
```

Exit `3` nghĩa là DDL chạy được nhưng **có khẳng định thất bại** — ràng buộc
không ép đúng cái nó phải ép. Ghi kết quả vào `04-migration-notes.md`: rule nào
đã thử và đạt, rule nào **chưa** thử.

Đừng để việc này thành ad-hoc: file assertion là artifact bàn giao, đội phát
triển chạy lại được sau mỗi lần sửa schema.

Với `BR-*` đã phân lớp A/B/C ở Bước 4c, một khẳng định chạy **tuần tự trong một
session không chứng minh được gì** — lớp A và C chỉ hỏng khi có hai session.
Thử được thì thử hai session song song; không thử được thì ghi thẳng
*"`BR-xxx`: cơ chế là `<…>`, **chưa thử đồng thời**"*, cùng quy tắc ba trạng thái
như exit 2.

## Bước 6 — Back-propagate: sửa lại stage trước khi thực tế nói khác

Stage 4 là stage đầu tiên đối mặt với engine thật, nên nó thường **chứng minh
một khẳng định của Stage 3 là sai**. Khi đó, sửa artifact Stage 3 là **bắt
buộc**, không phải tuỳ chọn — để hai artifact nói khác nhau là bàn giao một
khẳng định sai cho người đọc sau.

Quy trình, làm trước khi mở gate:

1. Đi hết bảng `BR-*` ở `03-logical-schema.md §6`. Với mỗi dòng ghi
   `DB (planned)`:
   - ép được thật (đã có khẳng định chạy qua) → đổi thành `DB` + tick
     `Verified by Stage 4`;
   - **không** ép được → đổi thành `app`, ghi lý do engine không làm được, và
     thêm một dòng vào `03-logical-schema.md §8 Amendments`.
2. Mọi `DN-*` mới phát sinh ở Stage 4 (thường do partition) phải được **thêm vào
   Stage 3**, không chỉ ghi trong comment SQL.
3. ERD ở Stage 2 lệch so với schema cuối (bảng/cột thêm ở Stage 3/4, đổi tên) →
   **sinh lại ERD**, hoặc ghi rõ lệch chỗ nào. Đừng bàn giao ERD cũ.
4. Ghi vào `STATE.md`:

```markdown
## Amendments
- <YYYY-MM-DD> BR-0xx: DB (planned) → app — engine không ép được (partitioned unique)
- <YYYY-MM-DD> DN-0x thêm ở Stage 4 — đã cập nhật 03-logical-schema.md
```

Gate của Stage 4 phải **đọc ra** danh sách amendment này. Không có amendment nào
là một kết quả hợp lệ — nhưng phải nói rõ là "đã kiểm, không có", chứ không im lặng.

## Artifact & Gate

`04-schema.sql`, `04-index-plan.md`, `04-migration-notes.md`, `05-assertions.sql`
(+ các sửa đổi back-propagate ở Stage 2/3). Cập nhật `STATE.md`, sang Stage 5.
