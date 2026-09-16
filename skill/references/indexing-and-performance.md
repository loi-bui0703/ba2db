# Indexing & Performance

Dùng ở Stage 4. Mọi index phải truy ngược được về một truy vấn trong `VP-*`.

## Quy tắc chọn index

1. **FK ở phía con**: gần như luôn cần (join + kiểm tra khi xóa cha).
2. **Thứ tự cột trong composite index**: cột lọc bằng `=` trước → cột range
   (`>`, `BETWEEN`) → cột sort. Index `(a, b)` phục vụ được truy vấn lọc theo
   `a`, nhưng không phục vụ truy vấn chỉ lọc theo `b`.
3. **Covering index**: thêm cột `INCLUDE` khi truy vấn chỉ đọc vài cột và chạy rất nhiều.
4. **Partial index**: `WHERE status = 'pending'` khi chỉ một phần nhỏ dòng được
   truy vấn thường xuyên; cũng là cách làm unique có điều kiện cho soft delete.
5. **Text search**: `LIKE 'abc%'` dùng được B-tree; `LIKE '%abc%'` thì cần
   trigram (`pg_trgm`) hoặc full-text index.
6. **Cột lệch phân bố cực đoan** (99% một giá trị): index toàn phần thường vô ích.

## Chi phí

Mỗi index: chậm INSERT/UPDATE/DELETE, tốn dung lượng, tốn thời gian rebuild.
Bảng ghi nhiều (log, event) nên có ít index nhất có thể.

## Partitioning

Cân nhắc khi bảng dự kiến >50–100M dòng hoặc có retention theo thời gian.

| Kiểu | Khi nào | Khóa |
|---|---|---|
| Range theo thời gian | log, giao dịch, có retention | `created_at` theo tháng/năm |
| List theo tenant/vùng | multi-tenant lớn | `tenant_id`, `region` |
| Hash | phân tán đều, không có khóa tự nhiên | id |

Lợi ích lớn nhất: xóa dữ liệu hết hạn bằng `DROP PARTITION` thay vì `DELETE`
hàng loạt. Nhược điểm: mọi unique constraint phải chứa khóa phân mảnh.

## Checklist hiệu năng trước khi chốt

- [ ] Mỗi báo cáo trong `VP-*` có đường index rõ ràng
- [ ] Không có truy vấn nóng nào phải quét toàn bảng lớn
- [ ] Không có N+1 do thiếu bảng tổng hợp cho dashboard
- [ ] Bảng ghi nhiều không bị gánh quá nhiều index
- [ ] Đã ước lượng dung lượng: dòng/ngày × kích thước dòng × retention
- [ ] Đã xác định dữ liệu nào archive và archive đi đâu
- [ ] Truy vấn báo cáo nặng cân nhắc read replica / materialized view
