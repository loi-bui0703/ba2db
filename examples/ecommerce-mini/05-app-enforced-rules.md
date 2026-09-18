# 05 — App-Enforced Rules · Quy tắc phải ép ở tầng ứng dụng

Project: `ecommerce-mini` · Engine: PostgreSQL 16 · Date: 2026-09-16

> Đây là artifact bàn giao cho đội phát triển, không phải phụ lục. Mỗi dòng là
> một quy tắc nghiệp vụ mà **database không chặn** — nếu nó chỉ nằm rải trong
> data dictionary thì nó sẽ mất khi sang code, và mất im lặng vì không có gì fail.

## 1. Tổng quan

| Metric | Value |
|---|---|
| Tổng số `BR-*` | 5 |
| Ép ở database | 4 (`BR-001`, `BR-002`, `BR-004`, `BR-005`) |
| **Ép ở ứng dụng** | **1** |
| Trong đó mất chỗ ép vì lựa chọn kỹ thuật của chúng ta (L4) | **0** |

Con số cuối cùng là con số đáng nói: lần này **không** có rule nào mất chỗ ép vì
một quyết định của chúng ta. Rule duy nhất ở tầng ứng dụng là **bản chất** không
diễn đạt được kiểu khai báo — ở bất kỳ engine nào.

## 2. Rule register

| BR-* | Quy tắc (EN/VI) | Vì sao DB không ép được | Ép ở đâu | Test chứng minh | Trạng thái |
|---|---|---|---|---|---|
| `BR-003` | An order must contain at least one line · Một đơn phải có ít nhất một dòng hàng | **L3** — "phải có ít nhất một dòng con" không diễn đạt được bằng `CHECK`/`UNIQUE`/FK. Một `CHECK` chỉ thấy dòng của chính bảng nó; đơn được tạo **trước** dòng đầu tiên, nên không có thời điểm nào ràng buộc này đúng liên tục | service layer, tại bước `confirm` đơn (không phải lúc `INSERT` đơn) | `test_confirm_rejects_empty_order` | ☐ chưa có test |

### Tại sao không dùng trigger

Một `AFTER DELETE` trigger trên `order_line` có thể chặn việc xoá dòng cuối
cùng, nhưng **không** chặn được một đơn `draft` chưa bao giờ có dòng nào. Ràng
buộc thật gắn với **chuyển trạng thái** (`draft → confirmed`), không gắn với sự
tồn tại của dòng — nên nó thuộc về nơi xử lý chuyển trạng thái.

Đây là một ví dụ của nguyên tắc ở §3: rule cần biết *hệ thống đang ở bước nào*,
không chỉ *dữ liệu đang trông thế nào*.

## 3. Ranh giới có thể dự đoán được

Database ép được **tính thành viên của tập hợp, tính duy nhất, và hình dạng tham
chiếu** — tính chất của một dòng hoặc một tập ở **trạng thái tĩnh**. Nó không ép
được tính chất của một **tiến trình diễn ra theo thời gian**.

Đối chiếu trên chính 5 rule của ví dụ này:

| BR-* | Cần biết "điều gì đã xảy ra trước đó"? | Kết luận |
|---|---|---|
| `BR-001` đã `paid` thì không huỷ | Có — nhưng chỉ cần **trạng thái ngay trước** (`OLD.status`), thứ mà trigger nhìn thấy được | DB (trigger) |
| `BR-002` giá là snapshot | Không — là một cột, không phải một phép tra cứu | DB (thiết kế cột) |
| `BR-003` ít nhất một dòng | **Có — cần biết đơn đang ở bước nào của quy trình** | **app** |
| `BR-004` thứ tự chuyển trạng thái | Có — `OLD.status`, trigger nhìn thấy | DB (trigger) |
| `BR-005` tổng = tổng các dòng | Không — là một phép tính trên dữ liệu hiện có | DB (trigger) |

Câu hỏi phân loại chỉ có một: *quy tắc này có cần biết điều gì đã xảy ra trước
đó mà một dòng dữ liệu không nói ra được?* Có → tầng ứng dụng. Trả lời được câu
này **trước khi viết dòng DDL nào**.

## 4. Nghĩa vụ bàn giao

- [ ] `BR-003` có test tự động — **chưa có**, ghi rõ thay vì bỏ qua
- [x] Không có dòng L4 nào phải đưa vào findings (vì không có dòng L4)
- [ ] Đội phát triển đã nhận và xác nhận danh sách này
