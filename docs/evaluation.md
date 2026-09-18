# Đánh giá bộ skill — cách đo cho ra kết luận, không cho ra cảm giác

Tài liệu này nói **cách thử nghiệm ba2db**, không phải cách dùng nó. Nó ra đời từ
một lần chạy thực tế (`notificationb2b`, PostgreSQL 16, 30 bảng) mà kết luận
trung thực nhất lại là: *lần chạy đó cho thấy skill **hoạt động**, nhưng không
chứng minh được nó **tốt hơn** một agent không dùng skill.*

Đó là một khoảng trống về phương pháp, không phải về kết quả — và nó lặp lại ở
mọi lần thử nghiệm skill nếu không được thiết kế trước.

## 1. Bốn yếu tố gây nhiễu phải khai báo trước

| # | Yếu tố | Vì sao nó thổi phồng kết quả | Cách xử lý |
|---|---|---|---|
| 1 | **Không có nhánh đối chứng** | Không có gì để so sánh ⇒ mọi khẳng định "tốt hơn" là vô căn cứ | §2 |
| 2 | **Cùng một model viết tài liệu BA rồi tự phân tích nó** | Đầu vào có cấu trúc tốt bất thường; mâu thuẫn "tìm được" là mâu thuẫn tự cài vào | §3 |
| 3 | **N = 1, một nghiệp vụ, một DBMS** | Nghiệp vụ dày quy tắc là mảnh đất thuận lợi; một màn hình CRUD dùng tới ít phần phương pháp hơn nhiều | §4 |
| 4 | **Tự đánh giá** | Người review và người thiết kế là cùng một model | §5 |

Báo cáo nào không nói ra bốn điều này thì con số của nó không đọc được.

## 2. Nhánh đối chứng — thí nghiệm đáng giá nhất còn chưa chạy

**Thiết kế:** hai nhánh, cùng bộ tài liệu BA, cùng model.

- **Nhánh A (control):** agent không có skill, một lượt, prompt duy nhất:
  *"thiết kế database từ bộ tài liệu này, cho PostgreSQL 16"*.
- **Nhánh B (treatment):** agent chạy đủ 7 giai đoạn của skill.

**Chấm điểm chỉ bằng tiêu chí khách quan** — tiêu chí nào cần đọc hiểu để cho
điểm thì bỏ, vì nó mở đường cho thiên vị:

| Tiêu chí | Cách đo | Ai đo |
|---|---|---|
| DDL có chạy được không | `validate-ddl.sh` exit 0 | máy |
| Bao nhiêu `BR-*` thực sự bị database chặn | `--assert` với **cùng một** bộ khẳng định cho cả hai nhánh | máy |
| Ràng buộc có quá rộng không | vế "hợp lệ nhưng gần giống" phải được chấp nhận | máy |
| Số bảng bịa ra (không map về requirement nào) | traceability ngược | người, mù nhánh |
| Có phát hiện mâu thuẫn cài sẵn không | có/không, theo từng mâu thuẫn | người, mù nhánh |
| Số ID tham chiếu mà không định nghĩa | `check-design.sh §4` | máy |
| Con số tự khai có khớp nội dung | `check-design.sh §5` | máy |

**Quy tắc quan trọng:** bộ khẳng định (`05-assertions.sql`) phải được viết
**trước** khi chạy hai nhánh, từ danh sách `BR-*` của tài liệu BA — không được
viết sau khi đã xem schema của nhánh nào. Viết sau là đo lại chính thiết kế.

Người chấm các tiêu chí "người đo" **không được biết** artifact thuộc nhánh nào.

## 3. Đầu vào độc lập

Tài liệu BA phải do **người khác** viết, không phải model đang được đánh giá —
lý tưởng nhất là tài liệu thật, với đủ sự lộn xộn thật: mục thiếu, thuật ngữ
không nhất quán, bảng dán từ Excel, phiên bản chưa duyệt lẫn với bản đã duyệt.

Nếu buộc phải dùng tài liệu tự soạn, hãy khai báo và **đếm riêng**: phát hiện
nào đến từ mâu thuẫn *cài sẵn* (không chứng minh gì) và phát hiện nào **không**
cài sẵn (đây mới là phần đáng đọc).

## 4. Độ phủ ca thử nghiệm

Một lần chạy trên một nghiệp vụ không nói được phương pháp có khái quát hay không.
Tối thiểu ba hình dạng khác nhau:

| Hình dạng | Ví dụ | Kỳ vọng |
|---|---|---|
| **Dày quy tắc, nặng kiểm toán** | hạ tầng gửi tin, thanh toán, bảo hiểm | dùng tới nhiều phần nhất của phương pháp |
| **CRUD-heavy** | quản trị danh mục, nội dung | phần lớn phương pháp là overhead — **đo overhead đó** |
| **Nhiều thực thể, ít quy tắc** | ERP một phân hệ | kiểm tra khả năng chịu quy mô của trích xuất |

Và tối thiểu **hai DBMS**, vì bước chọn DBMS (Stage 1B) chỉ được kiểm thật khi
kết luận không phải lúc nào cũng ra cùng một engine.

## 5. Người review độc lập

Stage 5 là tự review. Nó có trần năng lực — trong lần chạy `notificationb2b` nó
bỏ sót hai lỗi mà việc đếm bằng máy bắt được:

1. tài liệu requirement tự khai **147** trong khi đếm được **198**;
2. bảng nóng nhất hệ thống mã hoá vòng đời **hai lần** (`status` + 6 timestamp
   nullable) mà **không có ràng buộc nào** buộc hai cách biểu diễn khớp nhau.

Vì vậy, khi đánh giá skill, phải tách ba nguồn finding và đếm riêng:

- finding do **Stage 5 tự review** tìm ra;
- finding do **`check-design.sh`** (máy) tìm ra;
- finding do **agent đối kháng độc lập** tìm ra (`skill/agents/README.md`).

Tỷ lệ giữa ba nguồn này chính là số đo về trần năng lực của tự review — và là
kết quả hữu ích nhất mà một lần thử nghiệm skill có thể cho.

## 6. Chi phí, không chỉ kết quả

Hiệu quả không chỉ là cái gì đi ra, mà còn là phải trả bao nhiêu để có nó. Đo:

- **Chi phí context mỗi giai đoạn**: số từ hướng dẫn thực sự được nạp / tổng số
  từ của skill (progressive disclosure có hoạt động không).
- **Thời gian tới artifact đầu tiên có thể review được.**
- **Số lượt gate người dùng phải xử lý** — 7 gate là chi phí thật, phải đối chiếu
  với giá trị chúng tạo ra.

## 7. Cách đọc một báo cáo thử nghiệm

Chia mọi con số làm hai loại và **nói rõ loại nào ở đâu**:

| Loại | Đứng vững trước yếu tố gây nhiễu? | Ví dụ |
|---|---|---|
| **Do máy kiểm chứng** | Có — database hoặc chấp nhận DDL, hoặc từ chối | số object tạo được, số khẳng định đạt, query plan |
| **Tự khai báo** | Không | số requirement trích xuất, số phát hiện, độ phủ |

Con số tự khai của agent phải được coi là **thứ cần kiểm chứng, không phải dữ
liệu** — kể cả khi nó nằm trong một báo cáo trông rất chắc chắn.

> **Gọi đúng tên kết quả.** Một lần chạy sạch, không có nhánh đối chứng, là một
> **lần chạy đạt tiêu chuẩn (qualification run)** — không phải một benchmark.
