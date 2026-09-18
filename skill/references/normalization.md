# Normalization — 1NF → BCNF và khi nào dừng

## Các dạng chuẩn

| Dạng | Yêu cầu | Vi phạm điển hình trong dự án thật |
|---|---|---|
| **1NF** | Mỗi ô một giá trị nguyên tử; không có nhóm lặp | `phone` chứa "0901, 0902"; `item_1, item_2, item_3` |
| **2NF** | 1NF + mọi cột không khóa phụ thuộc **toàn bộ** khóa chính | Bảng `order_line(order_id, product_id, product_name)` — `product_name` chỉ phụ thuộc `product_id` |
| **3NF** | 2NF + không có phụ thuộc bắc cầu | `employee(id, dept_id, dept_name)` — `dept_name` phụ thuộc `dept_id` |
| **BCNF** | Mọi định thức đều là siêu khóa | Bảng có hai khóa ứng viên chồng nhau |
| **4NF** | Không có phụ thuộc đa trị độc lập | `staff(id, skill, language)` gộp hai danh sách không liên quan |

**Mặc định: đưa về 3NF/BCNF.** 4NF/5NF chỉ xét khi thực sự gặp phụ thuộc đa trị.

## Quy trình kiểm tra nhanh mỗi bảng

1. Có cột nào chứa danh sách / chuỗi ghép không? → tách bảng (1NF).
2. Khóa chính là composite? Mỗi cột còn lại có phụ thuộc **cả** khóa không? (2NF)
3. Có cột nào suy ra được từ cột không khóa khác không? → tách (3NF).
4. Cùng một sự thật có xuất hiện ở hai nơi không? → chỉ một nơi là nguồn sự thật.

## Khi nào được denormalize

Chỉ khi có **bằng chứng** từ `VP-*`, và phải ghi đủ 4 mục.

> **ID dùng `DN-*`, không dùng `D-*`.** `D-*` đã là namespace của quyết định mô
> hình ở Stage 2. Một `D-01` mang hai nghĩa khác nhau trong cùng một bộ artifact
> làm mọi tham chiếu chéo — kể cả comment trong DDL — trở nên nhập nhằng.

```
DN-01
What: order.customer_name nhân bản từ customer.name
Why: báo cáo đơn hàng 50k dòng/ngày, join customer làm chậm p95 (VP-004)
Sync: cập nhật qua trigger khi customer.name đổi  |  hoặc: snapshot cố ý, không đồng bộ
Risk: dữ liệu lệch nếu trigger lỗi; chấp nhận vì đây là snapshot tại thời điểm đặt hàng
```

Hai loại denormalize **hợp lệ và khác nhau** — đừng nhầm:
- **Snapshot nghiệp vụ**: giá/địa chỉ **tại thời điểm giao dịch**. Đây không
  phải dư thừa, mà là yêu cầu nghiệp vụ. Luôn làm.
- **Cache hiệu năng**: bản sao để đọc nhanh. Cần cơ chế đồng bộ rõ ràng.

## Cột dẫn xuất (derived)

`order.total_amount` = tổng các dòng. Ba lựa chọn:
1. Tính lúc đọc (view) — đúng luôn, chậm khi báo cáo nhiều.
2. Lưu + trigger/generated column — nhanh, cần đảm bảo nhất quán.
3. Materialized view — cho báo cáo, chấp nhận độ trễ.

Chọn cái nào cũng được, nhưng **phải ghi lựa chọn vào data dictionary**.
