---
name: db-design-04-physical-design
description: Stage 4 — produce runnable DDL for the target DBMS plus index, partition, and storage plans driven by the volume requirements.
stage: 4
inputs: 03-logical-schema.md, 03-data-dictionary.md, VP-* requirements
outputs: 04-schema.sql, 04-index-plan.md, 04-migration-notes.md
---

# Stage 4 — Physical Design

Ra **DDL chạy được** trên DBMS đích + kế hoạch index/partition có căn cứ.

## Bước 1 — Sinh DDL

Theo thứ tự trong `templates/04-physical/04-schema.sql`:
1. schema/extension, 2. enum & reference data, 3. bảng (theo thứ tự phụ thuộc
FK), 4. ràng buộc bổ sung, 5. index, 6. view, 7. trigger/function, 8. seed data.

Quy tắc:
- Tên tiếng Anh, `snake_case`, bảng số nhiều hay số ít thì **nhất quán** toàn
  bộ (mặc định: số ít) — `references/naming-conventions.md`.
- Ràng buộc đặt tên tường minh: `pk_`, `fk_<child>_<parent>`, `uq_`, `ck_`, `ix_`.
- Idempotent khi có thể (`IF NOT EXISTS`) để chạy lại được.
- Cú pháp đúng phương ngữ của DBMS đích — `references/dbms-notes.md`.
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

## Bước 4 — Vận hành

`04-migration-notes.md` ghi: thứ tự triển khai, migration từ hệ thống cũ (nếu
có legacy schema ở Stage 0), kế hoạch backup/retention, phân quyền DB role,
mã hóa cột PII theo `NF-*`.

## Bước 5 — Kiểm tra cú pháp

Nếu máy có DBMS/CLI, chạy thử DDL trên database rỗng tạm thời:

```bash
bash ../scripts/validate-ddl.sh workspace/<project>/04-schema.sql postgres
```

Không có môi trường thì nói rõ **DDL chưa được chạy thử**, đừng khẳng định là đã chạy.

## Artifact & Gate

`04-schema.sql`, `04-index-plan.md`, `04-migration-notes.md`. Cập nhật
`STATE.md`, sang Stage 5.
