---
name: db-design-00-intake
description: Stage 0 — inventory the BA document set, confirm scope, DBMS target and constraints before any modeling work.
stage: 0
inputs: BA documents (any format)
outputs: 00-intake-report.md, STATE.md
---

# Stage 0 — Intake & Scoping

Mục tiêu: biết chính xác **có gì trong tay** và **thiết kế cho cái gì**, trước khi đọc sâu.

## Bước 1 — Kiểm kê tài liệu / Document inventory

Liệt kê mọi file BA nhận được, mỗi file ghi:

| Field | Mô tả |
|---|---|
| `id` | `BA-01`, `BA-02`… dùng để trích dẫn về sau |
| `path` | đường dẫn file |
| `type` | SRS / use case / BPMN / wireframe / form / report spec / interview note / legacy schema |
| `coverage` | phân hệ nghiệp vụ nào |
| `quality` | complete / partial / draft / conflicting |

Không đọc kỹ nội dung ở bước này — chỉ mục lục, tiêu đề, danh sách hình/bảng.

## Bước 2 — Xác định phạm vi / Scope

Hỏi người dùng (hoặc suy ra từ tài liệu rồi xin xác nhận):

1. **Phân hệ nào trong phạm vi**, phân hệ nào ngoài phạm vi?
2. **Ứng viên DBMS + ràng buộc nền tảng** — *không chọn ở đây*. Ghi lại: đội
   vận hành đang chạy engine nào, cloud/managed service đã chốt chưa, giấy phép
   có giới hạn gì, framework/ORM đã có driver nào. **Quyết định DBMS thuộc
   Stage 1B**, sau khi đã có `VP-*`/`BR-*`/`NF-*` để lập luận.
3. **Loại tải**: OLTP / OLAP / hỗn hợp / có yêu cầu reporting riêng?
4. **Quy mô ước tính**: số user, số bản ghi/ngày của các thực thể lớn nhất,
   thời gian lưu trữ (retention).
5. **Ràng buộc phi chức năng**: multi-tenant?, audit trail?, soft delete?,
   dữ liệu cá nhân/PII cần mã hóa?, i18n?, múi giờ?, tích hợp hệ thống cũ?
6. **Có schema/legacy DB đang chạy không** — nếu có, đây là ràng buộc migration.

Câu nào người dùng không trả lời → ghi vào `OPEN QUESTIONS`, **chọn default an
toàn và ghi rõ giả định**, đừng dừng cả quy trình lại vì một câu hỏi.

**Một ngoại lệ: DBMS không có default.** Nếu người dùng không nói, để
`undecided` và chuyển câu hỏi sang Stage 1B — ở đó nó được quyết định bằng lập
luận từ requirement chứ không bằng một giá trị mặc định.

## Bước 3 — Ghi artifact

Điền `templates/01-requirements/00-intake-report.md` vào
`workspace/<project>/00-intake-report.md`, và tạo `STATE.md`:

```markdown
# STATE
project: <slug>
dbms: undecided          # chốt ở Stage 1B, không mặc định
dbms_status: undecided   # undecided | provisional | decided
stage_done: 0
next: 01-requirements-extraction
open_questions: 3
updated: <YYYY-MM-DD>
```

> `dbms: undecided` là trạng thái **đúng** khi kết thúc Stage 0. Một Stage 0 kết
> thúc với một DBMS đã chọn nghĩa là đã chọn trước khi có dữ kiện.

## Gate

Trình bày với người dùng: bảng kiểm kê tài liệu + phạm vi chốt + danh sách câu
hỏi mở + giả định đã chọn + **ràng buộc nền tảng đã thu được** (đầu vào cho
Stage 1B). Xin xác nhận rồi chuyển sang
`skills/01-requirements-extraction/SKILL.md`.
