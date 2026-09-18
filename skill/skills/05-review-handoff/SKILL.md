---
name: db-design-05-review-handoff
description: Stage 5 — verify the design against the BA requirements, build the traceability matrix, and package the deliverable.
stage: 5
inputs: all previous artifacts
outputs: 05-review-report.md, 05-traceability-matrix.md, 05-app-enforced-rules.md, README of deliverable
---

# Stage 5 — Review & Handoff

Giai đoạn này **tìm lỗi trong chính thiết kế của mình**, không phải tóm tắt lại nó.

## Bước 0 — Đếm bằng máy trước khi tự đánh giá

```bash
bash scripts/check-design.sh workspace/<project>
bash scripts/validate-ddl.sh workspace/<project>/04-schema.sql <engine> --report
```

Chạy trước mọi bước khác, vì hai loại lỗi sau **lọt qua tự review một cách có hệ
thống** và chỉ lộ ra khi đếm:

- **Con số tự khai không khớp nội dung** (số requirement, số bảng). Số do agent
  tự khai phải coi là *thứ cần kiểm chứng*, không phải dữ liệu.
- **Hai artifact của hai stage nói khác nhau** về cùng một `BR-*`.

Ngoài ra `--report` cho **mật độ ràng buộc theo từng bảng** và **FK thiếu index**
— thứ không đọc ra được bằng cách đọc lại bản tóm tắt của chính mình.

> Mọi `ERROR` của `check-design.sh` phải được xử lý **trước** khi mở gate. Nếu nó
> bắt được điều gì mà review không thấy, ghi vào findings **kèm câu "review đã bỏ
> sót"** — đó là dữ liệu về trần năng lực của tự review, đáng giá hơn việc che đi.

## Bước 1 — Traceability matrix

Hai chiều, cả hai đều phải sạch:

- **Forward**: mỗi `DR-*` → bảng/cột/ràng buộc nào hiện thực nó.
  `DR-*` không map được → **thiếu thiết kế**.
- **Backward**: mỗi bảng/cột → `DR-*` nào sinh ra nó.
  Không map được → **thừa** (bịa thêm) hoặc thiếu requirement.

Điền `templates/05-review/05-traceability-matrix.md`.

## Bước 2 — Chạy checklist

Đi hết `references/review-checklist.md` — **9 nhóm**. Mỗi mục đánh
`PASS / FAIL / N-A` kèm ghi chú; **không** đánh PASS cho thứ chưa thực sự kiểm.

Nhóm 1–8 xác nhận những gì đã làm. **Nhóm 9 (lượt đọc đối kháng) là nhóm duy
nhất tạo ra finding mới** — và là nhóm hay bị làm qua loa nhất, vì nó đòi phản
đối chính mình. Điều kiện đạt: tìm được **ít nhất 3 cách làm dữ liệu sai mà
schema vẫn chấp nhận**, viết ra đúng câu `INSERT`/`UPDATE` đó — hoặc nói rõ đã
thử những hướng nào mà không tìm ra.

**Nếu host hỗ trợ subagent, hãy chạy nhóm 9 bằng một agent riêng**, chỉ đưa
`04-schema.sql` + `01-data-requirements.md`, **không** đưa các artifact giải
thích lý do thiết kế. Mất phần biện minh chính là điều làm nó nhìn ra lỗ hổng.
Xem `agents/README.md`.

## Bước 3 — Diễn tập use case

Chọn 5–8 use case quan trọng nhất từ `PR-*` và viết truy vấn/thao tác thật
(INSERT/SELECT/UPDATE) đi qua schema. Use case nào phải join >5 bảng hoặc cần
subquery vòng vèo là tín hiệu mô hình chưa khớp nghiệp vụ.

## Bước 3b — Đăng ký rule ép ở tầng ứng dụng

Điền `templates/05-review/05-app-enforced-rules.md` vào
`workspace/<project>/05-app-enforced-rules.md`: mọi `BR-*` mà database **không**
chặn, kèm lý do (L1–L4), chỗ ép trong code, và test chứng minh.

Đây là artifact bàn giao, không phải phụ lục: một rule app-enforced chỉ nằm rải
trong data dictionary sẽ **mất khi sang code**, và mất im lặng vì không có gì fail.

Chú ý riêng các dòng **L4** — rule mất chỗ ép vì *lựa chọn của chúng ta*
(partition, engine), không vì bản chất. Mỗi dòng L4 phải xuất hiện trong findings
của báo cáo và trong ngân sách khả chuyển ở `04-migration-notes.md §8`.

## Bước 4 — Báo cáo

`05-review-report.md` gồm:
- Tóm tắt thiết kế: số bảng, phân hệ, quyết định lớn và lý do
- Kết quả checklist
- **Findings** xếp theo mức: Blocker / Major / Minor, mỗi finding có đề xuất sửa
- **Open questions** còn lại cho phía BA (đây là đầu ra hợp lệ, không phải thất bại)
- **Assumptions** đã dùng — người đọc phải tự xác nhận được. Assumption về engine
  lấy mức rủi ro từ ngân sách khả chuyển (≥3 `BR-*` phụ thuộc ⇒ **High**), không
  đánh "Medium" theo cảm tính
- **Những gì KHÔNG được đánh PASS** — nói thẳng ra: load test chưa chạy, chưa
  diễn tập restore, dung lượng là ước lượng chứ không phải đo
- Rủi ro & việc nên làm tiếp (load test, sizing, archive…)

## Bước 5 — Đóng gói

Bàn giao trong `workspace/<project>/`: artifact của cả 7 giai đoạn (gồm
`01b-dbms-decision.md`, `05-app-enforced-rules.md`, `05-assertions.sql`) +
`README.md` mô tả thứ tự đọc. Cập nhật `STATE.md` (`stage_done: 5`) và giữ lại
mục `## Amendments` — nó cho người đọc biết khẳng định nào đã bị stage sau sửa.

Nếu người dùng muốn bản đọc cho người khác (team, khách hàng), đề nghị xuất
thành một trang HTML/Artifact — không để deliverable nằm mãi trong scrollback.
