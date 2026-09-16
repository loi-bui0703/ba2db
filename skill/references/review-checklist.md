# Review Checklist (Stage 5)

Đánh dấu `PASS / FAIL / N-A` + ghi chú cho từng mục. Không PASS thứ chưa kiểm.

## 1. Đầy đủ & truy vết
- [ ] Mọi `DR-*` map được tới ít nhất một bảng/cột/ràng buộc
- [ ] Mọi bảng/cột map ngược được tới ít nhất một `DR-*`
- [ ] Mọi use case `PR-*` thực hiện được trên schema
- [ ] Mọi báo cáo trong `VP-*` truy vấn được
- [ ] Open questions & assumptions đã liệt kê đầy đủ

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

## 4. Chuẩn hóa
- [ ] Đạt 3NF/BCNF hoặc có ghi chú denormalize đủ 4 mục (what/why/sync/risk)
- [ ] Không còn anti-pattern trong `anti-patterns.md`
- [ ] Cột dẫn xuất đã ghi rõ cách duy trì

## 5. Hiệu năng
- [ ] Mỗi index có truy vấn biện minh; FK phía con có index
- [ ] Bảng lớn đã cân nhắc partition + retention
- [ ] Đã ước lượng dung lượng và tăng trưởng

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

## 8. Tài liệu & đặt tên
- [ ] Đặt tên nhất quán theo `naming-conventions.md`, không dùng từ khóa SQL
- [ ] Data dictionary đầy đủ mọi cột, có mô tả EN/VI
- [ ] ERD khớp với DDL (không lệch phiên bản)
- [ ] Tên bảng/cột đều tiếng Anh
