---
name: db-design-03-logical-design
description: Stage 3 — normalize the conceptual model into a logical schema: tables, keys, data types, constraints, and a full data dictionary.
stage: 3
inputs: 02-conceptual-erd.md, 01-data-requirements.md, 01b-dbms-decision.md
outputs: 03-logical-schema.md, 03-data-dictionary.md
---

# Stage 3 — Logical Design

Chuyển mô hình khái niệm thành **schema logic** — vẫn độc lập tương đối với
DBMS, nhưng đã đủ chặt để sinh DDL.

## Bước 1 — Ánh xạ entity → bảng

| Từ | Thành |
|---|---|
| Entity độc lập | 1 bảng |
| Weak entity | 1 bảng, PK gồm FK tới cha + số thứ tự |
| Quan hệ M:N | 1 bảng liên kết (+ cột thuộc tính của quan hệ nếu có) |
| Quan hệ 1:1 | gộp bảng, hoặc tách nếu vòng đời/quyền truy cập khác nhau |
| Kế thừa (is-a) | chọn 1 trong 3: single table / table-per-type / table-per-concrete; ghi rõ lý do |
| Reference data | bảng danh mục nếu cần sửa lúc chạy; enum/CHECK nếu cố định |

## Bước 2 — Khóa

- **PK**: mặc định surrogate key (`bigint identity` hoặc `uuid` — xem
  `references/dbms-notes.md` để chọn theo DBMS và nhu cầu phân tán).
- **Business key** luôn phải có `UNIQUE` riêng, kể cả khi đã có surrogate key.
- **FK**: khai báo đầy đủ + chọn `ON DELETE` có chủ ý
  (`RESTRICT` mặc định; `CASCADE` chỉ cho quan hệ sở hữu thật sự).
- Composite PK ở bảng liên kết: cân nhắc `(a_id, b_id)` vs surrogate.

## Bước 3 — Chuẩn hóa

Đưa về **3NF/BCNF** trước, có kỷ luật — theo `references/normalization.md`.
Chỉ denormalize khi có `VP-*` (yêu cầu hiệu năng) chứng minh, và khi đó phải
ghi: dữ liệu nào bị nhân bản, cơ chế nào giữ đồng bộ, rủi ro gì.

**ID của denormalization là `DN-*`, không phải `D-*`.** `D-*` đã là namespace
quyết định mô hình của Stage 2; dùng lại nó làm mọi tham chiếu chéo — kể cả
comment trong DDL ở Stage 4 — trở nên nhập nhằng.

## Bước 4 — Kiểu dữ liệu & ràng buộc

Theo `references/naming-conventions.md`:
- Tiền: `numeric(19,4)` + cột `currency_code char(3)`, **không dùng float**.
- Thời gian: `timestamptz` cho mốc thời gian tuyệt đối, `date` cho ngày nghiệp
  vụ; ghi rõ quy ước múi giờ một lần cho toàn hệ thống.
- Chuỗi: có độ dài nghiệp vụ thì đặt `varchar(n)`, không có thì `text`.
- `NOT NULL` là mặc định; cho phép NULL phải có lý do nghiệp vụ.
- Mọi `BR-*` phải thành: `CHECK`, `UNIQUE`, FK, trigger, hoặc — nếu không thể
  ép ở tầng DB — ghi rõ "enforced in application" trong data dictionary.
- **Khẳng định "ép được ở DB" ở stage này là *dự kiến*, không phải sự thật.**
  Ghi `DB (planned)` và để trống cột `Verified by Stage 4`. Chỉ Stage 4 chạy DDL
  thật mới biết engine có ép được hay không — và nó có nghĩa vụ quay lại sửa.
  Ba loại rule hay bị khai sai ở đây: ràng buộc liên dòng (tổng, đếm), "phải có
  ít nhất một dòng con loại X", và **duy nhất toàn cục trên bảng sẽ partition**.
- Cột audit chuẩn: `created_at`, `created_by`, `updated_at`, `updated_by`
  (+ `deleted_at` nếu dùng soft delete — xem `references/modeling-patterns.md`).
- **Vòng đời không được mã hoá hai lần mà không có ràng buộc.** Nếu một bảng có
  cột trạng thái **và** một dãy timestamp nullable theo từng mốc (`sent_at`,
  `approved_at`, `closed_at`…), thì hai cách biểu diễn đó phải bị buộc khớp
  nhau bằng `CHECK`: trạng thái đã đạt mốc ⇒ timestamp tương ứng `NOT NULL`
  (và ngược lại nếu nghiệp vụ đòi). Không có ràng buộc này thì
  `status='DELIVERED'` với `sent_at IS NULL` là một dòng hợp lệ — và mọi job
  hay báo cáo đọc timestamp đó đều sai một cách âm thầm.

## Bước 5 — Data dictionary

Mỗi cột một dòng: bảng, cột, kiểu, null?, default, ràng buộc, mô tả (EN/VI),
`DR-*` nguồn. Đây là input trực tiếp của Stage 5 (traceability).

## Bước 6 — Tự kiểm

Đối chiếu `references/anti-patterns.md`. Với mỗi truy vấn/báo cáo trong `VP-*`,
thử "đi bộ" qua schema: có join được không, có cần bảng nào chưa có không.

Thêm hai lượt quét ngắn:

- **Vòng đời hai lần**: bảng nào có cột trạng thái + ≥2 timestamp theo mốc mà
  chưa có `CHECK` buộc chúng khớp nhau?
- **Hàng đợi**: nếu `01b-dbms-decision.md` §5 chốt là queue-in-database, bảng
  hàng đợi đã có cơ chế nhận việc (claim) chưa — `FOR UPDATE SKIP LOCKED` hay
  cột lease? Xem `references/storage-topology.md §1`.

## Artifact & Gate

`03-logical-schema.md` ← `templates/03-logical/03-logical-schema.md`;
`03-data-dictionary.md` ← `templates/03-logical/03-data-dictionary.md`.
Báo cáo: số bảng, các quyết định chuẩn hóa/denormalize (`DN-*`), rule nào không
ép được ở tầng DB, và những `BR-*` đang ghi `DB (planned)` mà Stage 4 phải kiểm
chứng. Cập nhật `STATE.md`, sang Stage 4.
