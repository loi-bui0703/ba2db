---
name: db-design-01b-dbms-selection
description: Stage 1B — choose the DBMS by reasoning from the extracted requirements, compare real candidates, and record the decision as an ADR before any modeling starts.
stage: 1b
inputs: 01-data-requirements.md, 00-intake-report.md
outputs: 01b-dbms-decision.md
---

# Stage 1B — DBMS Decision

Chọn **hệ quản trị** bằng lập luận từ requirement đã trích xuất, rồi ghi lại
thành một ADR có thể review và có thể phản đối từng dòng.

> **Bộ skill này KHÔNG có DBMS mặc định.** Không được viết "PostgreSQL (mặc
> định)" rồi đi tiếp. Nếu kết luận trùng với cái phổ biến nhất thì vẫn phải có
> lập luận dẫn tới nó — mặc định là *kết luận không có tiền đề*.

## Vì sao ở đây, không sớm hơn và không muộn hơn

- **Không ở Stage 0:** lúc đó chưa biết khối lượng, chưa biết `BR-*` nào cần
  ràng buộc gì. Chọn ở Stage 0 là chọn trước khi có dữ kiện.
- **Không ở Stage 4:** lúc đó mô hình logic đã được định hình bởi một engine mà
  chưa ai chọn. Đổi engine ở Stage 4 là làm lại Stage 3 và 4.
- **Ở Stage 1B:** vừa có đủ `VP-*`, `BR-*`, `NF-*` để lập luận, và chưa có dòng
  DDL nào để phải bỏ đi.

Đọc `references/dbms-selection.md` trước khi làm bước 1.

## Bước 1 — Rút driver từ requirement

Mỗi driver **phải trỏ về một ID** trong `01-data-requirements.md`. Driver không
có ID không phải driver — nó là sở thích, và thuộc bước 2.

| Driver | Requirement ID | Engine phải làm được gì | Must-have? |
|---|---|---|---|

Đánh dấu `Must-have` khi thiếu năng lực đó thì **một `BR-*` mất chỗ ép** hoặc
một `VP-*` không đạt được — chứ không phải khi nó chỉ "tiện hơn".

## Bước 2 — Ràng buộc bối cảnh

Hỏi người dùng, đừng suy đoán: đội vận hành đang chạy engine nào (ai backup,
restore, đọc query plan), giấy phép/chi phí, cloud đã chốt chưa, framework/ORM
đã có driver gì, ràng buộc tuân thủ & vị trí dữ liệu.

Không trả lời được câu nào → **ghi thành assumption có rủi ro**, đừng dừng cả
quy trình. Nhưng ghi rõ đây là ràng buộc bối cảnh, **tách khỏi** lập luận kỹ
thuật, để người review gạch được từng phần.

## Bước 3 — Shortlist 2–4 ứng viên

Không so sánh một mình một ứng viên (đó là biện minh, không phải lựa chọn), và
cũng không liệt kê cả thị trường. Ứng viên đưa vào phải **thực sự có thể được
chọn** trong bối cảnh ở bước 2.

## Bước 4 — Loại theo must-have, rồi đếm rule mất chỗ ép

Theo `references/dbms-selection.md §3–§4`:

1. Ứng viên thiếu một must-have → **bị loại**, không cứu bằng ưu điểm khác.
2. Với mỗi ứng viên còn lại, **đếm số `BR-*` phải đẩy xuống tầng ứng dụng** và
   liệt kê đúng những ID đó. Đây là con số quan trọng nhất của cả stage: nó biến
   "khác phương ngữ" thành "mất bao nhiêu bảo đảm về tính đúng đắn".
3. Nice-to-have so sánh bằng chữ.

**Không dùng điểm tổng có trọng số** — nó cho một con số trông khách quan từ
những trọng số do chính mình bịa ra.

## Bước 5 — Đánh dấu topology

Theo `references/storage-topology.md`, đánh dấu (chưa cần chốt) các thành phần
có thể cần ngoài engine chính: hàng đợi, cache/đếm theo giây, tìm kiếm, phân
tích, lưu trữ lạnh. Với mỗi cái nói rõ **có nằm trong phạm vi thiết kế database
này hay không**.

Đặc biệt: nếu `PR-*`/`VP-*` cho thấy có **hàng đợi**, phải quyết định ngay là
queue-in-database hay broker — vì nếu là queue-in-database thì Stage 3/4 có
nghĩa vụ thiết kế cơ chế nhận việc (claim), không được để trống.

## Bước 6 — Chốt quyết định

Ghi đủ bốn phần, thiếu phần nào thì ADR vô giá trị:

1. **Quyết định**: engine + version cụ thể (`PostgreSQL 16`, không phải "Postgres").
2. **Hệ quả**: tính năng nào sẽ dùng, `BR-*` nào phải đẩy sang ứng dụng, cái gì
   Stage 4 phải làm khác đi.
3. **Rủi ro nếu sai** + **cách kiểm chứng** (ai xác nhận, hỏi gì).
4. **Trigger xem lại**: điều gì xảy ra thì mở lại quyết định này.

Nếu người dùng không chốt được: vẫn ra quyết định **provisional**, ghi
`status: provisional · owner: <ai>` trong artifact **và** trong header của
`04-schema.sql` ở Stage 4. Không được im lặng đi tiếp như thể đã chốt.

## Bước 7 — Ngân sách khả chuyển (portability budget)

Ghi vào ADR: danh sách tính năng **chỉ engine đã chọn có**, và với mỗi tính năng
là `BR-*` nào phụ thuộc nó. Đây chính là chi phí thật nếu sau này phải đổi nền
tảng — xem `references/dbms-notes.md §Portability budget`.

Đánh giá rủi ro của assumption "engine đã chọn" phải dựa trên bảng này: nếu có
≥3 `BR-*` phụ thuộc tính năng độc quyền thì rủi ro là **High**, không phải
Medium.

## Artifact & Gate

`workspace/<project>/01b-dbms-decision.md` ← `templates/01b-dbms/01b-dbms-decision.md`.

Cập nhật `STATE.md`: `dbms: <engine-version>` và `dbms_status: decided|provisional`.

Trình bày ở gate: bảng driver must-have, ứng viên bị loại **và vì sao bị loại**,
số `BR-*` mất chỗ ép của phương án được chọn, và ngân sách khả chuyển. Xin xác
nhận rồi sang `skills/02-conceptual-model/SKILL.md`.
