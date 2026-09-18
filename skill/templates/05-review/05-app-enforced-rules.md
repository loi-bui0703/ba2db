# 05 — App-Enforced Rules · Quy tắc phải ép ở tầng ứng dụng

Project: `<slug>` · Engine: `<engine + version>` · Date: `<YYYY-MM-DD>`

> **Đây là artifact bàn giao cho đội phát triển, không phải phụ lục.**
> Mỗi dòng dưới đây là một quy tắc nghiệp vụ mà **database không chặn**. Nếu nó
> chỉ tồn tại rải rác trong data dictionary thì nó sẽ mất khi sang code — và mất
> một cách im lặng, vì không có gì fail.

## 1. Tổng quan

| Metric | Value |
|---|---|
| Tổng số `BR-*` | |
| Ép ở database | |
| **Ép ở ứng dụng** | |
| Trong đó: **mất chỗ ép vì lựa chọn kỹ thuật** (partition, engine) | |

## 2. Rule register

| BR-* | Quy tắc (EN/VI) | Vì sao DB không ép được | Ép ở đâu (module/hàm) | Test chứng minh | Trạng thái |
|---|---|---|---|---|---|
| BR-0xx | | | | `<tên test>` | ☐ chưa có test |

**Cột "Vì sao DB không ép được"** chỉ được nhận một trong bốn lý do — nếu không
thuộc lý do nào thì rule đó **đáng lẽ ép được ở DB**, hãy quay lại Stage 4:

| Mã | Lý do | Ví dụ |
|---|---|---|
| L1 | **Tính chất của tiến trình theo thời gian**, không phải của một dòng ở trạng thái tĩnh | tính hợp lệ của chuyển trạng thái, thứ tự sự kiện đến trễ, chuỗi thử lại, circuit breaker |
| L2 | **Phụ thuộc thời điểm hiện tại / múi giờ** | khung giờ được phép, đếm theo ngày, giới hạn theo giây |
| L3 | **"Phải có ít nhất một dòng con loại X"** — không diễn đạt được kiểu khai báo | mỗi bản mẫu phải có tối thiểu một bản ngôn ngữ mặc định |
| L4 | **Engine hoặc lựa chọn vật lý gỡ bỏ chỗ ép** | unique toàn cục trên bảng đã partition; engine không có partial unique index |

> L4 khác hẳn L1–L3: L1–L3 là **bản chất**, L4 là **hệ quả của một quyết định
> của chúng ta**. Mọi dòng L4 phải xuất hiện trong ngân sách khả chuyển
> (`04-migration-notes.md §8`) và trong findings của `05-review-report.md`.

## 3. Ranh giới có thể dự đoán được

Database ép được **tính thành viên của tập hợp, tính duy nhất, và hình dạng tham
chiếu** — tức là tính chất của một dòng hoặc một tập ở **trạng thái tĩnh**. Nó
không ép được tính chất của một **tiến trình diễn ra theo thời gian**.

Cho một danh sách `BR-*`, có thể phân loại DB / app **trước khi viết dòng DDL
nào**, chỉ bằng một câu hỏi: *quy tắc này có cần biết điều gì đã xảy ra trước đó
không?* Có → tầng ứng dụng.

## 4. Nghĩa vụ bàn giao

- [ ] Mỗi dòng ở §2 có một test tự động, hoặc được ghi rõ là **chưa có**
- [ ] Mọi dòng L4 đã xuất hiện trong findings của review report
- [ ] Đội phát triển đã nhận và xác nhận danh sách này
