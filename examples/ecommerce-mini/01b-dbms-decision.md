# 01B — DBMS Decision Record · Quyết định hệ quản trị

Project: `ecommerce-mini` · Date: 2026-09-16 · Author: `ba2db agent`

| | |
|---|---|
| **Decision** | **PostgreSQL 16** |
| **Status** | `provisional` |
| **Owner** | Platform team (BA-01 names no DBMS, and nobody was asked) |
| **Deadline** | before Stage 4 writes DDL |

> Lưu ý về chính ví dụ này: kết luận **trùng** với engine phổ biến nhất. Điều đó
> không làm cho lập luận thành vô nghĩa — nó chỉ có nghĩa là lập luận phải đọc
> được, để người review biết **khi nào** cần mở lại quyết định. Trạng thái là
> `provisional` vì không ai xác nhận ràng buộc nền tảng ở §2.

## 1. Decision drivers · Yếu tố quyết định (từ requirement)

| # | Driver | Requirement ID | Engine phải làm được gì | Must-have? |
|---|---|---|---|---|
| DD-01 | Giá trên dòng hàng là snapshot, không được đổi về sau | `BR-002` | Không cần gì đặc biệt — đây là quyết định mô hình, không phải tính năng engine | N |
| DD-02 | Tổng đơn = tổng các dòng, hiện ngay khi thêm dòng | `BR-005`, `BA-01 §3.6` | Trigger, hoặc generated column nếu lưu | N |
| DD-03 | Chuyển trạng thái `draft → confirmed → paid → shipped`; đã `paid` thì không huỷ | `BR-001`, `BR-004` | Trigger đọc được trạng thái cũ (`OLD`) | **Y** |
| DD-04 | Tiền phải chính xác, không được là float | `BR-002`, `BR-005` | `numeric`/`decimal` đúng nghĩa | **Y** |
| DD-05 | Báo cáo doanh thu theo ngày, lọc `status='paid'` + khoảng ngày | `VP-010` | Index chỉ trên phần nhỏ dòng `paid` sẽ rẻ hơn nhiều | N *(xem §4.2)* |
| DD-06 | 5.000 đơn/ngày, đỉnh 18:00–21:00 | `VP-001` | ~0,2 ghi/giây trung bình, đỉnh vài ghi/giây — **không** phải yếu tố phân biệt | N |
| DD-07 | Lưu 7 năm (~13M đơn, ~38M dòng hàng) | `VP-001`, `VP-002` | Vẫn dưới ngưỡng cần partition; chỉ cần index thời gian tốt | N |
| DD-08 | Ghi ai sửa gì, lúc nào | `NF-001` | Cột audit + trigger `updated_at` | N |
| DD-09 | Bảo vệ dữ liệu cá nhân của khách | `NF-002` | Che khi đọc theo vai trò: view + quyền, hoặc masking sẵn có | N |

Chỉ **hai** must-have. Điều đó tự nó là một kết quả đáng nói: nghiệp vụ này
**không** đòi hỏi năng lực đặc biệt của engine nào, nên §2 sẽ nặng hơn §4.

## 2. Context constraints · Ràng buộc bối cảnh

| # | Ràng buộc | Nguồn | Ảnh hưởng |
|---|---|---|---|
| CC-01 | Đội vận hành đang chạy engine nào | **chưa hỏi được** | **Đây là ràng buộc quyết định nhất mà lại đang trống.** Xem Q-B1 |
| CC-02 | Giấy phép / chi phí | không có thông tin | SQL Server/Oracle tính theo core; với quy mô này khó biện minh |
| CC-03 | Cloud / managed service | không có thông tin | Cả 4 engine đều có managed service |
| CC-04 | Framework, ORM, migration runner | không có thông tin | Q-B2 |
| CC-05 | Tuân thủ & vị trí dữ liệu | `NF-002` nói "pháp luật áp dụng", không nói nước nào | Q-B3 |

> Ràng buộc bối cảnh gần như trống. Vì vậy quyết định là `provisional`, không
> phải `decided` — và đây là cách trung thực để ghi nhận điều đó thay vì chọn
> rồi đi tiếp.

## 3. Candidates · Ứng viên

| Ứng viên | Vì sao vào shortlist |
|---|---|
| **PostgreSQL 16** | Mã nguồn mở, đủ mọi năng lực ở §1, phổ biến nhất cho OLTP mới |
| **MySQL 8** | Mã nguồn mở, rất phổ biến ở web/e-commerce, nhiều đội đã có sẵn kinh nghiệm |
| **SQL Server 2022** | Chỉ nếu tổ chức đã dùng .NET/Windows và đã trả giấy phép |

Oracle **không** vào shortlist: không có yêu cầu nào ở §1 mà nó là lựa chọn duy
nhất đáp ứng, còn chi phí thì cao nhất nhóm. Loại ở bước shortlist, có lý do.

## 4. Elimination & comparison

### 4.1 Must-have

| Ứng viên | DD-03 (trigger đọc `OLD`) | DD-04 (decimal cho tiền) | Kết luận |
|---|---|---|---|
| PostgreSQL 16 | ✓ | ✓ `numeric(19,4)` | **giữ** |
| MySQL 8 | ✓ | ✓ `DECIMAL(19,4)` | **giữ** |
| SQL Server 2022 | ✓ | ✓ `DECIMAL(19,4)` | **giữ** |

Không ứng viên nào bị loại ở must-have. **Nói rõ điều này**: nghiệp vụ CRUD-ish
không tạo ra sự khác biệt giữa các engine, và một bảng so sánh cố tỏ ra có khác
biệt lớn ở đây là bảng được viết ngược.

### 4.2 Số `BR-*` mất chỗ ép ở tầng database

| Ứng viên | Số `BR-*` phải đẩy sang ứng dụng | Những ID nào | Vì thiếu năng lực gì |
|---|---|---|---|
| PostgreSQL 16 | **1** | `BR-003` | "phải có ít nhất một dòng con" — không engine nào ép được kiểu khai báo |
| MySQL 8 | **1** | `BR-003` | như trên |
| SQL Server 2022 | **1** | `BR-003` | như trên |

Ba ứng viên **bằng nhau**. Với 5 business rule thì con số này chưa phân biệt được
gì — nó chỉ trở nên quyết định khi có rule dạng ràng buộc liên dòng hoặc duy nhất
có điều kiện. Ghi ra để người review thấy là **đã đo, và phép đo không phân biệt**.

### 4.3 Nice-to-have

| Khía cạnh | PostgreSQL 16 | MySQL 8 |
|---|---|---|
| `VP-010` báo cáo doanh thu (`status='paid'` + khoảng ngày) | **Partial index** `WHERE status='paid'` — chỉ index phần dòng thật sự được truy vấn | Không có partial index; phải index đủ `(status, order_date)` hoặc thêm cột sinh |
| `NF-002` che PII theo vai trò | View + `GRANT` (che bằng **quyền**, không bằng việc app nhớ che) | View được, nhưng phân quyền theo cột kém linh hoạt hơn |
| `NF-001` audit | Trigger + `COMMENT ON` mang data dictionary vào DB | Trigger được; không có `COMMENT ON` cho cột theo cùng cách |
| Nếu sau này cần lịch sử giá (`XX-002`) | `EXCLUDE`/`daterange` chống chồng lấn khoảng hiệu lực | Không có `EXCLUDE` → phải ép ở tầng ứng dụng |
| Đội đã quen | **chưa biết — CC-01** | **chưa biết — CC-01** |

Hai dòng cuối nói hết vấn đề: PostgreSQL thắng ở `VP-010` và ở khả năng mở rộng
cho `XX-002`, nhưng nếu CC-01 trả lời là "đội chỉ vận hành MySQL" thì **MySQL 8
là lựa chọn đúng** — và cái giá phải trả chỉ là một index rộng hơn cùng `BR-003`
vẫn ở tầng ứng dụng như cũ. Đó là một cái giá nhỏ, và nó phải được nói ra.

## 5. Storage topology

| Thành phần | Có cần? | Tín hiệu | Trong phạm vi thiết kế DB này? |
|---|---|---|---|
| Hàng đợi | **Không** | Không có `PR-*` nào nói tới xử lý bất đồng bộ | — |
| Cache | **Không** | 5.000 đơn/ngày; không có yêu cầu đọc lặp lớn | — |
| Tìm kiếm chuỗi | **Chưa rõ** | `BA-01 §2.1` "tìm khách theo tên" — tiền tố hay chứa chuỗi? | Q-B4. Nếu là `LIKE '%...%'` thì cần trigram |
| Phân tích / warehouse | **Không** | Một báo cáo ngày, trên một bảng | — |
| Lưu trữ lạnh | **Chưa rõ** | 7 năm là dài, nhưng ~13M đơn thì vẫn nhỏ | Không cần bây giờ; xem lại nếu khối lượng tăng bậc |
| Read replica | **Không** | Báo cáo ngày nhẹ | — |

## 6. Consequences

**Tính năng sẽ dùng:** `numeric(19,4)` cho tiền · `timestamptz` · trigger cho
`BR-001`/`BR-004`/`BR-005` · **partial index** cho `VP-010` · view + `GRANT` cho
`NF-002` · `COMMENT ON` mang data dictionary vào DB.

**`BR-*` phải ép ở tầng ứng dụng:**

| BR-* | Vì sao DB không ép được | Ép ở đâu |
|---|---|---|
| `BR-003` | "Phải có ít nhất một dòng con" không diễn đạt được kiểu khai báo ở **bất kỳ** engine nào — đây là **L1/L3**, bản chất, không phải hệ quả của việc chọn PostgreSQL | service layer khi confirm đơn |

**Stage 4 phải làm khác đi:** dùng partial index cho `VP-010` thay vì index đầy
đủ; ghi `Status: PROVISIONAL` vào header `04-schema.sql`.

## 7. Portability budget

| Tính năng độc quyền | Phụ thuộc | Mất gì nếu đổi engine |
|---|---|---|
| Partial index `WHERE status='paid'` | `VP-010` | MySQL 8 không có → index rộng hơn, chậm hơn nhưng **vẫn đúng**. Không mất ràng buộc nào |
| `COMMENT ON COLUMN` | `NF-001` (tài liệu) | Chỉ mất tiện lợi tài liệu |

**Risk của assumption "engine đã chọn": `Low`.**
Không có `BR-*` nào phụ thuộc tính năng độc quyền của PostgreSQL (0 < 3). Đổi
sang MySQL 8 sẽ tốn một buổi sửa cú pháp và một index rộng hơn — **không** mất
bảo đảm nào. Đây là lý do `provisional` ở đây là chấp nhận được: cái giá của
việc sai là thấp, đã đo được, và đã viết ra.

## 8. Risk, verification, review trigger

| # | Rủi ro | Cách kiểm chứng | Ai xác nhận |
|---|---|---|---|
| R-01 | Đội vận hành không chạy PostgreSQL (CC-01) | Hỏi platform team ai backup/restore engine nào | Platform team |
| R-02 | Tìm khách theo tên thực ra là tìm chứa chuỗi (Q-B4) | Xem lại màn hình tìm kiếm với BA | BA |

**Trigger xem lại quyết định:** CC-01 có câu trả lời · khối lượng tăng >10× so
với `VP-001` · xuất hiện yêu cầu lịch sử giá (`XX-002`) · xuất hiện ràng buộc
liên dòng hoặc duy nhất có điều kiện (lúc đó bảng ở §4.2 sẽ **không** còn bằng nhau).

## 9. Open questions from this stage

| # | Question | Blocks |
|---|---|---|
| Q-B1 | Đội vận hành đang chạy và biết vận hành engine nào? | trạng thái quyết định (`provisional` → `decided`) |
| Q-B2 | Đã chốt framework/ORM/migration runner chưa? | thứ tự & định dạng migration ở Stage 4 |
| Q-B3 | "Pháp luật áp dụng" ở `NF-002` là của nước nào? | yêu cầu vị trí dữ liệu & mã hoá |
| Q-B4 | "Tìm khách theo tên" là tiền tố hay chứa chuỗi? | có cần trigram index không (Stage 4) |

## 10. Assumptions

| # | Assumption | Risk if wrong | How to verify |
|---|---|---|---|
| A-B1 | Không có ràng buộc giấy phép buộc dùng engine thương mại | Low | Hỏi platform team |
| A-B2 | ~13M đơn / 38M dòng trong 7 năm là không cần partition | Low — vẫn thêm được partition sau, tốn một lần migration | Xem lại nếu `VP-001` tăng bậc |
