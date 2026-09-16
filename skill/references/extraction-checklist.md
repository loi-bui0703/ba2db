# Extraction Checklist — 12 nhóm tín hiệu trong tài liệu BA

Dùng ở Stage 1, **lượt 2**. Quét đủ 12 nhóm; nhóm nào tài liệu không nói → ghi
OPEN QUESTION.

> ⚠️ Checklist này là **lưới an toàn, không phải khung tư duy**. Nó bắt những
> thứ hay bị quên, nhưng không biết gì về đặc thù ngành của tài liệu bạn đang
> đọc. Đừng mở nó ở lượt 1, và đừng coi "đã quét hết 12 nhóm" là đã đọc xong —
> lượt 3 (`S9`) mới là nơi bắt phần mà mọi checklist đều bỏ sót.

## A. 12 nhóm tín hiệu

| # | Nhóm | Tìm gì trong tài liệu | Sinh ra |
|---|---|---|---|
| 1 | Danh từ nghiệp vụ | chủ ngữ/tân ngữ lặp lại trong mô tả | `EN-*` |
| 2 | Biểu mẫu & màn hình | mọi field trên form, wireframe, bảng nhập liệu | `AT-*` |
| 3 | Định danh | mã đơn, số hóa đơn, mã KH, quy tắc sinh mã | business key |
| 4 | Trạng thái & workflow | "chờ duyệt", "đã hủy", sơ đồ chuyển trạng thái | enum + `BR-*` |
| 5 | Động từ nghiệp vụ | tạo/duyệt/hủy/chuyển/thanh toán | `RL-*`, `PR-*` |
| 6 | Lượng từ | "mỗi", "nhiều", "tối đa 5", "ít nhất 1" | cardinality, `CHECK` |
| 7 | Quy tắc tính toán | tổng tiền, thuế, chiết khấu, tồn kho | `BR-*` (cột dẫn xuất?) |
| 8 | Thời gian & lịch sử | "tại thời điểm", "lịch sử thay đổi", hiệu lực từ–đến | versioning/SCD |
| 9 | Quyền & vai trò | ai xem/sửa được gì, phân quyền theo đơn vị | RBAC, row-level scope |
| 10 | Báo cáo & truy vấn | mọi báo cáo, dashboard, bộ lọc, export | `VP-*`, index |
| 11 | Khối lượng & tần suất | số user, giao dịch/ngày, thời gian lưu | `VP-*`, partition |
| 12 | Tuân thủ & tích hợp | PII, audit log, luật, API/file trao đổi với hệ thống khác | `NF-*` |

## B. Danh từ này là gì?

| Dấu hiệu | Kết luận |
|---|---|
| Có định danh riêng, có vòng đời riêng, xuất hiện trong nhiều use case | **Entity** |
| Chỉ mô tả một entity khác, không tồn tại độc lập | **Attribute** |
| Tập giá trị hữu hạn, ít thay đổi, chỉ để phân loại | **Enum / reference data** |
| Chỉ là tên một màn hình, một nút, một bước quy trình | **Không phải dữ liệu** |
| Là kết quả tính toán từ dữ liệu khác | **Derived** — quyết định lưu hay tính lúc đọc |

## C. Câu hỏi luôn phải hỏi nếu tài liệu không trả lời

1. Một `X` có thể thuộc nhiều `Y` không? Có thể không thuộc `Y` nào không?
2. Giá trị này có thay đổi theo thời gian không? Có cần biết giá trị **cũ** không?
3. Xóa thì mất hẳn hay chỉ ẩn đi? Ai được xóa?
4. Trường này có bắt buộc không? Lúc tạo mới hay chỉ ở trạng thái cuối?
5. Có duy nhất không — duy nhất trong phạm vi nào (toàn hệ thống / theo tenant / theo năm)?
6. Đơn vị đo / đơn vị tiền tệ / múi giờ là gì?
7. Dữ liệu này giữ bao lâu?
8. Ai được xem? Có dữ liệu cá nhân không?

## D. Dấu hiệu checklist đang làm hại thay vì giúp

- Mọi entity đều có đúng 4–5 attribute → đang điền cho đủ bảng, không đang đọc.
- Không có mục nào `Confidence: low` → đang tránh ghi nhận cái mình chưa chắc.
- `S9` rỗng ở một tài liệu >20 trang → lượt 3 chưa thực sự diễn ra.
- Không có `CONFLICTS` nào ở bộ tài liệu nhiều tác giả → nhiều khả năng bỏ sót.
- Mọi `BR-*` đều ép được bằng `CHECK` → nghiệp vụ thật hiếm khi gọn như vậy.
