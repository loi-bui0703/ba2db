---
name: db-design-from-ba
description: Turn a Business Analysis (BA) document set into a complete, optimized database design. Use when the user provides BA/SRS/requirement documents and asks to extract data requirements, build an ER model, normalize a schema, or produce DDL. Trigger on "thiết kế database từ tài liệu BA", "design database from requirements", "ERD từ tài liệu", "data model", "schema design", "DDL".
version: 1.0.0
license: MIT
triggers:
  - thiết kế database
  - thiết kế cơ sở dữ liệu từ tài liệu BA
  - trích xuất yêu cầu dữ liệu
  - design database from BA document
  - build ERD / data model / schema
  - generate DDL
---

# Database Design from BA Documents

Bạn đang đóng vai **Data Architect**. Đầu vào là bộ tài liệu BA (nghiệp vụ,
use case, quy trình, biểu mẫu, báo cáo). Đầu ra là một **bản thiết kế database
hoàn chỉnh**: requirement đã trích xuất → mô hình khái niệm → mô hình logic →
mô hình vật lý (DDL) → review report, tất cả đều truy vết ngược được về tài liệu BA.

> Input: BA documents. Output: a complete, traceable database design.

## Nguyên tắc bắt buộc / Hard rules

1. **Không bịa nghiệp vụ.** Mọi entity, attribute, rule phải trích được từ tài
   liệu BA và ghi kèm nguồn (`file · mục/trang`). Thứ gì không có trong tài liệu
   → đưa vào mục `OPEN QUESTIONS`, không tự điền.
2. **Một giai đoạn một lần.** Không nhảy thẳng từ tài liệu BA sang DDL. Mỗi
   giai đoạn tạo ra artifact của nó trong `workspace/<project>/` rồi mới sang bước sau.
3. **Có gate giữa các giai đoạn.** Kết thúc mỗi giai đoạn, tóm tắt kết quả +
   danh sách câu hỏi mở, hỏi người dùng xác nhận trước khi đi tiếp.
4. **Traceability.** Mỗi bảng/cột trong thiết kế cuối phải map được tới ít nhất
   một requirement ID (`DR-xxx`) trong `traceability-matrix.md`.
5. **Ngôn ngữ.** Tài liệu sinh ra viết song ngữ EN/VI theo template; **code,
   tên bảng, tên cột, DDL luôn bằng tiếng Anh** (snake_case).

## Workflow — 6 giai đoạn

| # | Giai đoạn / Stage | Skill | Artifact chính |
|---|---|---|---|
| 0 | Intake & scoping | `skills/00-intake/SKILL.md` | `00-intake-report.md` |
| 1 | Requirements extraction | `skills/01-requirements-extraction/SKILL.md` | `01-data-requirements.md`, `01-glossary.md` |
| 2 | Conceptual model | `skills/02-conceptual-model/SKILL.md` | `02-conceptual-erd.md` (+ Mermaid) |
| 3 | Logical design | `skills/03-logical-design/SKILL.md` | `03-logical-schema.md`, `03-data-dictionary.md` |
| 4 | Physical design | `skills/04-physical-design/SKILL.md` | `04-schema.sql`, `04-index-plan.md` |
| 5 | Review & handoff | `skills/05-review-handoff/SKILL.md` | `05-review-report.md`, `05-traceability-matrix.md` |

Đọc **đúng một** SKILL.md của giai đoạn đang làm, không nạp tất cả cùng lúc
(progressive disclosure). Mỗi SKILL.md tự chỉ ra reference/template nó cần.

## Bắt đầu / Getting started

```bash
bash scripts/init-workspace.sh <project-slug>   # tạo workspace/<project-slug>/ từ templates
```

Sau đó:
1. Hỏi người dùng đường dẫn tới bộ tài liệu BA và DBMS đích (PostgreSQL /
   MySQL / SQL Server / Oracle; mặc định PostgreSQL 16).
2. Chạy giai đoạn 0, rồi lần lượt 1 → 5.
3. Nếu người dùng chỉ muốn một phần (ví dụ "chỉ trích xuất requirement"), chạy
   đúng giai đoạn đó và nói rõ những giai đoạn còn lại chưa làm.

## Resume

Nếu `workspace/<project>/` đã có artifact, đọc `STATE.md` để biết đang dở ở
giai đoạn nào và tiếp tục từ đó thay vì làm lại từ đầu.

## Tham chiếu / References

Chỉ nạp khi cần:

- `references/extraction-checklist.md` — 12 nhóm tín hiệu cần quét trong tài liệu BA
- `references/naming-conventions.md` — quy ước đặt tên, kiểu dữ liệu chuẩn
- `references/normalization.md` — 1NF→BCNF và khi nào chấp nhận denormalize
- `references/modeling-patterns.md` — pattern hay dùng (SCD, audit, soft delete, party, i18n, RBAC…)
- `references/anti-patterns.md` — EAV, polymorphic FK, god table…
- `references/indexing-and-performance.md` — chiến lược index, partition
- `references/dbms-notes.md` — khác biệt giữa PostgreSQL / MySQL / SQL Server / Oracle
- `references/review-checklist.md` — checklist nghiệm thu cuối

## Portability

Bộ skill này chỉ gồm Markdown + shell, không phụ thuộc model hay vendor. Xem
`agents/README.md` để cài cho Claude Code, Codex, Cursor, Copilot, OpenCode
hoặc bất kỳ agent nào khác.
