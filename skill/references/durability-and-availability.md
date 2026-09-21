# Durability & Availability — mất bao nhiêu dữ liệu, ngừng bao lâu

Dùng ở **Stage 1B** (đánh dấu: engine có làm được mức này không) và **Stage 4**
(chốt con số, ghi vào `04-migration-notes.md §4`).

Một thiết kế có backup policy nhưng không có **mục tiêu** thì chưa trả lời được
câu hỏi duy nhất mà người ký duyệt quan tâm: *hỏng thì mất gì, và bao giờ chạy
lại được?* "Full backup hàng đêm" là một **phương tiện**; RPO/RTO là **yêu cầu**.
Viết phương tiện mà không viết yêu cầu là để người sau tự đoán xem 24 giờ dữ
liệu mất có chấp nhận được không.

---

## 1. Hai con số phải có, lấy từ `BR-*`/`NF-*`

| Chỉ số | Câu hỏi nghiệp vụ | Sai lầm hay gặp |
|---|---|---|
| **RPO** — Recovery Point Objective | Được phép mất **bao nhiêu dữ liệu** tính theo thời gian? | Ghi "0" cho mọi hệ. RPO = 0 đòi replica đồng bộ, và replica đồng bộ tính phí bằng độ trễ của **mọi** transaction ghi |
| **RTO** — Recovery Time Objective | Được phép **ngừng bao lâu** trước khi nghiệp vụ hỏng thật? | Ghi RTO ngắn hơn thời gian restore đã đo. Chưa đo thì chưa biết |

Hai con số này **không đồng nhất toàn hệ thống**. Sổ cái tiền và bảng log sự
kiện hiếm khi cùng mức. Viết theo nhóm bảng:

| Nhóm bảng | RPO | RTO | Vì sao mức này (`BR-*` / `NF-*`) |
|---|---|---|---|
| Giao dịch tiền | | | |
| Dữ liệu nghiệp vụ chung | | | |
| Log / sự kiện tái tạo được | | | |

> Nếu tài liệu BA không nói, đây là `OPEN QUESTION` — **không** tự điền một con
> số trông hợp lý. Ghi kèm nó chặn cái gì: RPO chặn việc chọn sync/async replica,
> RTO chặn việc chọn failover thủ công hay tự động.

## 2. Backup là phương tiện — phải khớp với RPO

| Phương tiện | RPO đạt được | Điều kiện |
|---|---|---|
| Full backup hàng đêm | tới **24 giờ** | chỉ đủ khi nghiệp vụ chấp nhận mất một ngày |
| Full + incremental | vài giờ | |
| **PITR** (WAL/binlog/redo archive) | vài phút → giây | archive phải đi ra khỏi máy chủ DB; archive nằm cùng đĩa với DB thì không phải backup |
| Replica đồng bộ | ~0 | mỗi commit chờ replica; tính vào ngân sách độ trễ ghi |

Một dòng "Full backup" trong bảng chính sách mà RPO yêu cầu 5 phút là **mâu
thuẫn nội tại của thiết kế**, không phải việc của đội vận hành.

## 3. Replica topology — nói bằng câu, không bằng một chữ "có"

Với mỗi replica, ghi bốn ô:

| Replica | Đồng bộ / bất đồng bộ | Dùng để làm gì (failover / đọc / backup) | Ngân sách độ trễ | Ai đo độ trễ, ngưỡng cảnh báo |
|---|---|---|---|---|

**Ngân sách độ trễ replica** là con số bắt buộc khi có replica đọc. Không có nó
thì mọi truy vấn báo cáo đều "có thể cũ một chút" — một câu không kiểm chứng
được. Có nó thì `VP-*` nào vượt ngân sách sẽ bị phát hiện ở review.

**Read-after-write.** Đây là lỗi hay gặp nhất khi tách đọc/ghi: người dùng ghi
xong, màn hình kế tiếp đọc từ replica và **không thấy dữ liệu mình vừa tạo**.
Với mỗi `PR-*` có dạng "tạo xong → xem ngay", ghi rõ một trong ba cách:

1. đọc từ primary trong cùng phiên/một khoảng thời gian sau khi ghi;
2. chờ LSN/GTID của lần ghi đó (nếu engine hỗ trợ);
3. chấp nhận và **nói rõ trên màn hình** là dữ liệu có độ trễ.

Không chọn cách nào = đã chọn cách thứ tư: lỗi không tái hiện được.

Danh sách bắt buộc phải có: **báo cáo nào KHÔNG chịu được dữ liệu cũ** (thường
là đối soát tiền, kiểm tra hạn mức, chống trùng). Những truy vấn đó chạy trên
primary, ghi thẳng ra chứ đừng dựa vào một role `readonly`.

## 4. Failover — thủ công hay tự động, và ai đứng ra gọi

| Câu hỏi | Nếu không trả lời được |
|---|---|
| Ai/cái gì phát hiện primary chết? | RTO thực tế = thời gian tới khi có người để ý |
| Chuyển đổi tự động hay có người bấm? | tự động cần chống split-brain; thủ công cần runbook + người trực |
| Ứng dụng biết primary mới bằng cách nào? (DNS / VIP / service discovery / pooler) | DDL và connection string đúng nhưng hệ vẫn không lên |
| Sau failover, replica cũ làm gì? | rejoin sai cách là mất dữ liệu lần thứ hai |

Với managed service (RDS Multi-AZ, Cloud SQL HA, Azure SQL), ba câu đầu do nhà
cung cấp trả lời — **vẫn phải ghi ra là ai trả lời**, kèm con số failover time
nhà cung cấp cam kết, vì đó chính là sàn của RTO.

## 5. Restore drill — quy tắc ba trạng thái

Backup chưa restore thử thì **chưa biết là backup**. Đây đúng cùng một quy tắc
mà bộ skill này áp cho DDL (`validate-ddl.sh` exit 2: chưa chạy thì nói là chưa
chạy), chỉ khác đối tượng.

| Trạng thái | Được viết khi | Không được viết là |
|---|---|---|
| `verified` | đã restore vào môi trường sạch, đo được thời gian, đã kiểm dữ liệu | — |
| `partial` | restore được nhưng chưa đo thời gian, hoặc chỉ thử một phần | `verified` |
| **`not tested`** | chưa từng thử | im lặng, hoặc "backup đã cấu hình" |

`not tested` là một câu trả lời **hợp lệ** và phải hiện trong báo cáo Stage 5.
Một chính sách backup ghi đầy đủ kèm `not tested` là trung thực; cùng chính sách
đó không có dòng nào về restore là một khẳng định chưa có bằng chứng.

Drill tối thiểu phải ghi lại: nguồn backup nào, restore vào đâu, **mất bao lâu**
(đây là số duy nhất chứng minh được RTO), và kiểm cái gì để biết dữ liệu đúng
(đếm dòng bảng chính + một `BR-*` kiểm được bằng truy vấn).

## 6. Quy mô ngang — ghi thành giả định, đừng im lặng

Bộ skill này mặc định **một primary ghi** (scale bằng dọc + replica đọc +
partition). Với phần lớn thiết kế đi ra từ tài liệu BA, đó là giả định đúng.

Nhưng nó phải là **giả định được ghi**, không phải sự im lặng. Viết vào
`04-migration-notes.md §4`: *"Giả định: một node ghi. Ngưỡng phải xem lại: `<số
ghi/giây hoặc dung lượng>`."* Khi nào cần nhìn lại:

- `VP-*` cho số ghi/giây vượt quá thứ một node phục vụ được;
- dữ liệu phải nằm ở nhiều vùng vì lý do pháp lý (data residency) — đây là ràng
  buộc **định hình schema** (khoá phải mang được vùng), không phải việc triển khai;
- một tenant lớn tới mức phải tách riêng (xem `modeling-patterns.md §4`).

Sharding khác partition: partition chia trong **một** database và `BR-*` vẫn ép
được trong đó; sharding chia qua **nhiều** database và mọi ràng buộc liên shard
(unique toàn cục, FK, transaction) **mất chỗ ép** — cùng loại mất mát như
partition nhưng nặng hơn một bậc. Nếu thật sự phải shard, liệt kê `BR-*` bị mất
y như cách Stage 4 làm với partition.

## 7. Quan sát được (observability) của chính những thứ trên

Một mục tiêu không đo được thì không phải mục tiêu. Với mỗi dòng ở §1–§5, ghi
**đo bằng gì** và **ngưỡng cảnh báo**:

| Thứ phải theo dõi | Tín hiệu | Ngưỡng |
|---|---|---|
| Tuổi backup gần nhất | thời điểm backup thành công cuối | > RPO ⇒ cảnh báo |
| Độ trễ replica | lag theo giây/byte | > ngân sách §3 |
| Archive WAL/binlog | job archive lỗi, đĩa archive đầy | bất kỳ lỗi nào |
| Ngày restore drill gần nhất | ngày trong `04-migration-notes.md` | > `<chu kỳ đã chốt>` |

## 8. Checklist trước khi chốt Stage 4

- [ ] RPO và RTO có con số, theo nhóm bảng, có trỏ về `BR-*`/`NF-*`
- [ ] Phương tiện backup **đủ** cho RPO đã ghi (không có mâu thuẫn §2)
- [ ] Mỗi replica có đủ bốn ô ở §3, có ngân sách độ trễ
- [ ] Mọi `PR-*` dạng "tạo xong xem ngay" đã chọn một trong ba cách read-after-write
- [ ] Danh sách báo cáo **không** chịu được dữ liệu cũ đã ghi ra
- [ ] Failover: ai phát hiện, ai chuyển, ứng dụng tìm primary mới bằng gì
- [ ] Restore drill có trạng thái `verified / partial / not tested` — không bỏ trống
- [ ] Giả định "một node ghi" được ghi ra kèm ngưỡng phải xem lại
