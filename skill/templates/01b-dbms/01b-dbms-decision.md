# 01B — DBMS Decision Record · Quyết định hệ quản trị

Project: `<project-slug>` · Date: `<YYYY-MM-DD>` · Author: `<agent/người>`

| | |
|---|---|
| **Decision** | `<engine + version cụ thể, ví dụ PostgreSQL 16>` |
| **Status** | `decided` / `provisional` |
| **Owner** (nếu provisional) | `<ai phải chốt>` |
| **Deadline** (nếu provisional) | `<trước stage nào>` |

> Không có mặc định. Nếu kết luận trùng với engine phổ biến nhất thì vẫn phải
> đọc được lập luận dẫn tới nó ở §1–§4.

## 1. Decision drivers · Yếu tố quyết định (từ requirement)

Mỗi dòng phải trỏ về một ID trong `01-data-requirements.md`.

| # | Driver | Requirement ID | Engine phải làm được gì | Must-have? |
|---|---|---|---|---|
| DD-01 | | `VP-0xx` | | Y / N |
| DD-02 | | `BR-0xx` | | Y / N |

**Must-have** = thiếu năng lực này thì một `BR-*` mất chỗ ép hoặc một `VP-*`
không đạt được. Không phải "tiện hơn".

## 2. Context constraints · Ràng buộc bối cảnh

Tách khỏi §1 có chủ ý: đây là ràng buộc, không phải lập luận kỹ thuật.

| # | Ràng buộc | Nguồn (ai nói) | Ảnh hưởng tới lựa chọn |
|---|---|---|---|
| CC-01 | Đội vận hành đang chạy | | |
| CC-02 | Giấy phép / chi phí | | |
| CC-03 | Cloud / managed service | | |
| CC-04 | Framework, ORM, migration runner | | |
| CC-05 | Tuân thủ & vị trí dữ liệu | | |

Câu nào chưa có câu trả lời → ghi thành assumption ở §6, **không** im lặng chọn hộ.

## 3. Candidates · Ứng viên

Từ 2 đến 4. Chỉ đưa vào ứng viên **thực sự có thể được chọn** trong bối cảnh §2.

| Ứng viên | Vì sao vào shortlist |
|---|---|
| | |

## 4. Elimination & comparison · Loại và so sánh

### 4.1 Must-have — ứng viên bị loại

| Ứng viên | Must-have không đạt | Kết luận |
|---|---|---|
| | `DD-0x` | **LOẠI** |

### 4.2 Số `BR-*` mất chỗ ép ở tầng database

Con số quan trọng nhất của stage này — liệt kê đúng ID, không chỉ đếm.

| Ứng viên | Số `BR-*` phải đẩy sang ứng dụng | Những ID nào | Vì thiếu năng lực gì |
|---|---|---|---|
| | | | |

### 4.3 Nice-to-have

So sánh bằng chữ. **Không** dùng điểm tổng có trọng số.

| Khía cạnh | Ứng viên A | Ứng viên B |
|---|---|---|
| | | |

## 5. Storage topology · Thành phần ngoài engine chính

Theo `references/storage-topology.md` — đánh dấu, chưa cần chốt hết.

| Thành phần | Có cần? | Tín hiệu (`VP-*`/`PR-*`) | Trong phạm vi thiết kế DB này? |
|---|---|---|---|
| Hàng đợi (queue-in-DB / broker) | | | |
| Cache / đếm theo giây | | | |
| Tìm kiếm chuỗi | | | |
| Phân tích / warehouse | | | |
| Lưu trữ lạnh (archive) | | | |
| Read replica | | | |

> Nếu hàng đợi là **queue-in-database**: Stage 3/4 **bắt buộc** thiết kế cơ chế
> nhận việc (`FOR UPDATE SKIP LOCKED` hoặc cột lease) và ngân sách UPDATE.

## 6. Consequences · Hệ quả của quyết định

**Tính năng sẽ dùng:**
- 

**`BR-*` phải ép ở tầng ứng dụng vì engine không làm được:**

| BR-* | Vì sao DB không ép được | Ép ở đâu |
|---|---|---|

**Stage 4 phải làm khác đi:**
- 

## 7. Portability budget · Ngân sách khả chuyển

Tính năng **chỉ engine đã chọn có**, và `BR-*` nào phụ thuộc nó. Đây là chi phí
thật nếu sau này đổi nền tảng.

| Tính năng độc quyền | `BR-*` / `VP-*` phụ thuộc | Mất gì nếu đổi engine |
|---|---|---|

**Risk của assumption "engine đã chọn":** `Low / Medium / High`
(≥3 `BR-*` phụ thuộc tính năng độc quyền ⇒ **High**)

## 8. Risk, verification, review trigger

| # | Rủi ro nếu quyết định sai | Cách kiểm chứng | Ai xác nhận |
|---|---|---|---|
| | | | |

**Trigger xem lại quyết định này:**
- 

## 9. Assumptions · Giả định

| # | Assumption | Risk if wrong | How to verify |
|---|---|---|---|
| A-0x | | | |
