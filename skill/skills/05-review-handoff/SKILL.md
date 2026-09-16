---
name: db-design-05-review-handoff
description: Stage 5 — verify the design against the BA requirements, build the traceability matrix, and package the deliverable.
stage: 5
inputs: all previous artifacts
outputs: 05-review-report.md, 05-traceability-matrix.md, README of deliverable
---

# Stage 5 — Review & Handoff

Giai đoạn này **tìm lỗi trong chính thiết kế của mình**, không phải tóm tắt lại nó.

## Bước 1 — Traceability matrix

Hai chiều, cả hai đều phải sạch:

- **Forward**: mỗi `DR-*` → bảng/cột/ràng buộc nào hiện thực nó.
  `DR-*` không map được → **thiếu thiết kế**.
- **Backward**: mỗi bảng/cột → `DR-*` nào sinh ra nó.
  Không map được → **thừa** (bịa thêm) hoặc thiếu requirement.

Điền `templates/05-review/05-traceability-matrix.md`.

## Bước 2 — Chạy checklist

Đi hết `references/review-checklist.md`: tính đúng đắn, toàn vẹn, chuẩn hóa,
hiệu năng, bảo mật/PII, vận hành, đặt tên, tài liệu. Mỗi mục đánh
`PASS / FAIL / N-A` kèm ghi chú; **không** đánh PASS cho thứ chưa thực sự kiểm.

## Bước 3 — Diễn tập use case

Chọn 5–8 use case quan trọng nhất từ `PR-*` và viết truy vấn/thao tác thật
(INSERT/SELECT/UPDATE) đi qua schema. Use case nào phải join >5 bảng hoặc cần
subquery vòng vèo là tín hiệu mô hình chưa khớp nghiệp vụ.

## Bước 4 — Báo cáo

`05-review-report.md` gồm:
- Tóm tắt thiết kế: số bảng, phân hệ, quyết định lớn và lý do
- Kết quả checklist
- **Findings** xếp theo mức: Blocker / Major / Minor, mỗi finding có đề xuất sửa
- **Open questions** còn lại cho phía BA (đây là đầu ra hợp lệ, không phải thất bại)
- **Assumptions** đã dùng — người đọc phải tự xác nhận được
- Rủi ro & việc nên làm tiếp (load test, sizing, archive…)

## Bước 5 — Đóng gói

Bàn giao trong `workspace/<project>/`: 6 artifact của các stage + `README.md`
mô tả thứ tự đọc. Cập nhật `STATE.md` (`stage_done: 5`).

Nếu người dùng muốn bản đọc cho người khác (team, khách hàng), đề nghị xuất
thành một trang HTML/Artifact — không để deliverable nằm mãi trong scrollback.
