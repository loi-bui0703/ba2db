# Review Checklist (Stage 5)

Đánh dấu `PASS / FAIL / N-A` + ghi chú cho từng mục. Không PASS thứ chưa kiểm.

**Chạy `bash scripts/check-design.sh <workspace/project>` TRƯỚC khi đánh nhóm 1,
4, 5, 8 và 9.** Nhóm 1–8 xác nhận những gì đã làm; **nhóm 9 đi tìm lỗi mới** —
đó là nhóm duy nhất có thể bác bỏ tám nhóm kia.

## 1. Đầy đủ & truy vết
- [ ] Mọi `DR-*` map được tới ít nhất một bảng/cột/ràng buộc
- [ ] Mọi bảng/cột map ngược được tới ít nhất một `DR-*`
- [ ] Mọi use case `PR-*` thực hiện được trên schema
- [ ] Mọi báo cáo trong `VP-*` truy vấn được
- [ ] Open questions & assumptions đã liệt kê đầy đủ
- [ ] **Không có ID nào mang hai nghĩa** (`D-*` Stage 2 vs `DN-*` Stage 3) — `check-design.sh §3`
- [ ] Mọi ID được tham chiếu đều có dòng định nghĩa — `check-design.sh §4`
- [ ] **Số tự khai khớp số đếm được** (requirement, bảng, cột) — `check-design.sh §5`

## 2. Đúng đắn mô hình
- [ ] Cardinality khớp mô tả nghiệp vụ (kiểm cả hai chiều)
- [ ] Optionality (NULL/NOT NULL) đúng nghiệp vụ, không mặc định bừa
- [ ] Business key có UNIQUE riêng
- [ ] Không có entity bị gộp nhầm / tách thừa
- [ ] Yêu cầu lịch sử/thời điểm đã có cơ chế (snapshot/SCD/history)

## 3. Toàn vẹn
- [ ] Mọi quan hệ có FK khai báo, `ON DELETE` chọn có chủ ý
- [ ] Mọi `BR-*` ép được bằng CHECK/UNIQUE/FK/trigger — hoặc ghi rõ "app-enforced"
- [ ] Enum/trạng thái có ràng buộc giá trị
- [ ] Không có FK mồ côi khả dĩ
- [ ] **Không còn khẳng định `DB (planned)`** — Stage 4 đã kiểm chứng và back-propagate
- [ ] **Không có `BR-*` nào bị hai stage mô tả trái nhau** — `check-design.sh §6`
- [ ] **Vòng đời không mã hoá hai lần không ràng buộc**: bảng có cột status +
      timestamp theo mốc phải có `CHECK` buộc chúng khớp — `check-design.sh §7`
- [ ] Mọi rule app-enforced có mặt trong `05-app-enforced-rules.md` — `check-design.sh §9`

## 4. Chuẩn hóa
- [ ] Đạt 3NF/BCNF hoặc có ghi chú denormalize đủ 4 mục (what/why/sync/risk)
- [ ] Không còn anti-pattern trong `anti-patterns.md`
- [ ] Cột dẫn xuất đã ghi rõ cách duy trì

## 5. Hiệu năng
- [ ] Mỗi index có truy vấn biện minh; FK phía con có index (`validate-ddl.sh --report`)
- [ ] Bảng lớn đã cân nhắc partition + retention
- [ ] Đã ước lượng dung lượng và tăng trưởng
- [ ] **Đã đếm ngân sách UPDATE** cho bảng nóng; không có bộ đếm dùng chung một dòng
- [ ] **Bảng hàng đợi có cơ chế claim** (`SKIP LOCKED`/lease), không chỉ index partial
- [ ] Partition: đã liệt kê `BR-*` mất chỗ ép + job tạo/drop partition
- [ ] **Mật độ ràng buộc từng bảng đã được xem**; mọi bảng < 0.20 có lời giải thích
      (bảng bằng chứng cố tình lỏng, hay lỗ hổng thật?) — `check-design.sh §8`

## 6. Bảo mật & tuân thủ
- [ ] Đã đánh dấu cột PII; có phương án mã hóa/masking
- [ ] Audit trail đáp ứng `NF-*`
- [ ] Multi-tenant: `tenant_id` nằm trong mọi unique/index chính
- [ ] Không lưu mật khẩu/bí mật dạng rõ

## 7. Vận hành
- [ ] DDL chạy được (đã thử) hoặc ghi rõ **chưa thử**
- [ ] Thứ tự tạo bảng đúng phụ thuộc FK; script chạy lại được
- [ ] Có kế hoạch migration nếu có hệ thống cũ
- [ ] Backup/retention/role & quyền đã ghi
- [ ] **Khẳng định ràng buộc đã chạy thật** (`--assert`), không chỉ DDL chạy được
- [ ] **Đăng ký job vận hành** đầy đủ 4 ô, và mọi job "không hồi phục được" có
      cơ chế phát hiện thiếu
- [ ] **Ngân sách khả chuyển** đã ghi; risk của assumption engine đánh giá theo
      số `BR-*` phụ thuộc tính năng độc quyền (≥3 ⇒ High)

## 8. Tài liệu & đặt tên
- [ ] Đặt tên nhất quán theo `naming-conventions.md`, không dùng từ khóa SQL
- [ ] Data dictionary đầy đủ mọi cột, có mô tả EN/VI
- [ ] ERD khớp với DDL (không lệch phiên bản) — nếu lệch thì **sinh lại**, đừng ghi chú
- [ ] Tên bảng/cột đều tiếng Anh
- [ ] Không còn placeholder của template trong artifact — `check-design.sh §2`
- [ ] `01b-dbms-decision.md` có ứng viên **bị loại và lý do**, không chỉ có kết luận

## 9. Lượt đọc đối kháng (adversarial pass)

Tám nhóm trên xác nhận thiết kế **đã làm những gì nó nói**. Nhóm này hỏi ngược:
**thiết kế này sai ở đâu mà chưa ai thấy?** Đây là nhóm duy nhất tạo ra finding
mới, và là nhóm hay bị làm qua loa nhất vì nó đòi phản đối chính mình.

Điều kiện đạt: **tìm được ít nhất 3 cách làm dữ liệu sai mà schema vẫn chấp
nhận** — hoặc chứng minh được là đã thử và không tìm ra (nói rõ đã thử hướng nào).

- [ ] **Ba dòng dữ liệu sai được chấp nhận**: viết đúng câu `INSERT`/`UPDATE` đó ra
- [ ] **Hai cách biểu diễn cùng một sự thật**: cột nào có thể bất đồng với cột nào?
- [ ] **Job không chạy**: với mỗi job ở `04-migration-notes.md §7`, dữ liệu sai thế nào?
- [ ] **Hai tiến trình đồng thời**: hai request cùng lúc có vượt được hạn mức /
      tạo bản ghi trùng / lấy trùng việc trong hàng đợi không?
- [ ] **Đọc rule đúng câu chữ**: rule nào áp dụng nguyên văn thì cho kết quả vô
      nghĩa cho một nhóm dữ liệu? (kênh không bao giờ báo thành công, khách
      không có địa chỉ, kỳ đầu tiên chưa có kỳ trước…)
- [ ] **Bảng nào được bảo vệ ít nhất lại là bảng bận nhất?** Nếu có, đó là quyết
      định hay là sơ suất — và được ghi ở đâu?
- [ ] **Tự review có trần**: `check-design.sh` có bắt được gì mà review không thấy?
      Nếu có → ghi vào findings, và nói rõ review đã bỏ sót.

> **Ai nên chạy nhóm 9.** Cùng một agent vừa thiết kế vừa review thì có trần
> năng lực đã biết: nó bảo vệ lựa chọn của chính mình. Nếu host hỗ trợ subagent,
> hãy chạy nhóm này bằng **một agent riêng, chỉ được đưa `04-schema.sql` +
> `01-data-requirements.md`, không đưa các artifact giải thích lý do** — mất phần
> biện minh chính là điều làm nó nhìn ra lỗ hổng. Xem `agents/README.md`.
