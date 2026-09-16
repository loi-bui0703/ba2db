# Anti-patterns — kiểm tra trước khi chốt schema

| Anti-pattern | Biểu hiện | Thay bằng |
|---|---|---|
| **EAV** | `attribute_name/attribute_value` cho dữ liệu cốt lõi | cột thật; `jsonb` cho phần thật sự động |
| **Polymorphic FK** | `owner_type` + `owner_id`, không FK được | bảng liên kết riêng cho mỗi loại, hoặc bảng cha chung |
| **God table** | 1 bảng 80+ cột, nửa số cột NULL | tách theo entity/vòng đời |
| **Comma-separated** | `tags = "a,b,c"`, `role_ids = "1,2"` | bảng liên kết |
| **Không FK** | "ràng buộc để application lo" | khai FK; DB là hàng rào cuối |
| **PK là dữ liệu nghiệp vụ hay đổi** | PK = email, mã số thuế | surrogate PK + UNIQUE trên business key |
| **Float cho tiền** | `price float` | `numeric(19,4)` |
| **Timestamp không timezone** | `timestamp` lẫn lộn giờ local | `timestamptz`, lưu UTC |
| **Cột lặp đánh số** | `phone1, phone2, phone3` | bảng con |
| **`status` là chuỗi tự do** | typo "Pending" vs "pending" | enum / bảng danh mục / CHECK |
| **Bảng lịch sử trộn bảng chính** | cờ `is_history` trong bảng nóng | bảng history riêng hoặc partition |
| **Over-normalization** | tách bảng chỉ để chứa 1 cột không bao giờ đổi | gộp lại |
| **Index rải đại trà** | index mọi cột "cho chắc" | index theo truy vấn thật trong `VP-*` |
| **NULL mang nghĩa** | NULL = "chưa duyệt" và cũng = "không áp dụng" | tách cột/trạng thái tường minh |
| **Soft delete không kỷ luật** | `deleted_at` nhưng unique/query không lọc | partial unique index + view active |
| **Thiếu tenant trong unique** | `uq_user_email` toàn cục ở hệ multi-tenant | `uq_user_tenant_email` |
