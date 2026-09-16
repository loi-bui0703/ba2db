# Modeling Patterns

Pattern hay dùng. Chỉ áp dụng khi requirement thực sự cần — mỗi pattern là chi phí.

## 1. Audit columns
`created_at/by`, `updated_at/by` cho mọi bảng nghiệp vụ. Khi `NF-*` yêu cầu
audit trail đầy đủ → thêm bảng `audit_log(table_name, record_id, action, changed_by, changed_at, old_value jsonb, new_value jsonb)`.

## 2. Soft delete
`deleted_at timestamptz NULL`. Bắt buộc kèm: unique index có điều kiện
(`WHERE deleted_at IS NULL`), view `*_active`, và quy ước mọi truy vấn phải lọc.
Không dùng nếu nghiệp vụ không cần khôi phục — nó làm mọi query phức tạp hơn.

## 3. Slowly Changing Dimension / versioning
Khi cần biết giá trị **tại một thời điểm**:
- **SCD2**: `valid_from`, `valid_to`, `is_current` + unique `(business_key) WHERE is_current`.
- **Snapshot**: chép giá trị vào bảng giao dịch (`order_line.unit_price`). Đơn
  giản hơn, dùng được cho hầu hết ca giá/địa chỉ tại thời điểm đặt.
- **History table**: bảng `<table>_history` ghi mọi phiên bản.

## 4. Multi-tenancy
| Cách | Khi nào |
|---|---|
| `tenant_id` trên mọi bảng | mặc định, nhiều tenant nhỏ |
| Schema riêng mỗi tenant | ít tenant, yêu cầu cách ly mạnh |
| Database riêng | tenant lớn, yêu cầu pháp lý |
Nếu chọn `tenant_id`: nó phải nằm trong **mọi unique constraint và mọi index chính**,
và nên bật row-level security.

## 5. Party model
Khi một chủ thể vừa là khách vừa là nhà cung cấp vừa là nhân viên → `party` +
`party_role`, thay vì ba bảng trùng lặp thông tin liên hệ. Chỉ dùng khi thực sự
có chồng lấn; nếu không thì phức tạp hóa vô ích.

## 6. Kế thừa (is-a)
| Cách | Ưu | Nhược |
|---|---|---|
| Single table + `type` + cột nullable | join đơn giản | nhiều NULL, khó ràng buộc |
| Table per type (base + con) | chặt chẽ | nhiều join |
| Table per concrete | đọc nhanh | trùng cột, khó truy vấn chung |

## 7. Hierarchy
`parent_id` self-FK (đơn giản) · closure table (`ancestor_id, descendant_id, depth`
— truy vấn cây nhanh) · `ltree`/materialized path. Chọn theo tần suất truy vấn cây.

## 8. Reference data / enum
Bảng danh mục khi: người dùng thêm/sửa lúc chạy, cần thêm thuộc tính, cần i18n.
Native enum/CHECK khi: tập giá trị cố định, gắn với logic code.

## 9. State machine
`status` + bảng `status_transition(from_status, to_status, role)` khi luồng
trạng thái phức tạp; kèm bảng `<entity>_status_history` nếu cần biết ai đổi lúc nào.

## 10. i18n
`<table>_translation(<table>_id, locale, field..., PK(<table>_id, locale))`.
Chỉ áp dụng cho bảng thực sự cần đa ngôn ngữ.

## 11. Money & unit
Luôn đi cặp: `amount numeric(19,4)` + `currency_code char(3)`;
`quantity` + `uom_code`. Không bao giờ có số trần không đơn vị.

## 12. Idempotency & external keys
Tích hợp hệ ngoài → `external_id` + `source_system` với UNIQUE `(source_system, external_id)`.
