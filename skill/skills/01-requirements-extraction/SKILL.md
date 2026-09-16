---
name: db-design-01-requirements-extraction
description: Stage 1 — read the BA documents and extract every data-relevant requirement into numbered, traceable sections (entities, attributes, rules, volumes, NFRs).
stage: 1
inputs: 00-intake-report.md, BA documents
outputs: 01-data-requirements.md, 01-glossary.md
---

# Stage 1 — Data Requirements Extraction

Đây là giai đoạn quan trọng nhất: chất lượng thiết kế không bao giờ vượt quá
chất lượng của bước trích xuất này.

## Cách đọc / How to read

Đọc **hai lượt**:

Đọc **ba lượt**, theo đúng thứ tự này:

- **Lượt 1 — sweep (mở):** đọc toàn bộ tài liệu, đánh dấu mọi danh từ nghiệp vụ,
  biểu mẫu, trạng thái, phép đếm, báo cáo. **Chưa phân loại, chưa mở checklist.**
  Mục đích của lượt này là để tài liệu nói, không để khuôn mẫu nói.
- **Lượt 2 — classify (đóng):** đưa từng phát hiện vào section, gán ID, ghi
  nguồn `BA-xx §mục`. Quét thêm theo `references/extraction-checklist.md` —
  12 nhóm tín hiệu — để bắt những thứ lượt 1 bỏ sót.
- **Lượt 3 — challenge (mở lại):** đọc lại tài liệu và tự hỏi *"tài liệu này nói
  điều gì về dữ liệu mà 9 section chưa chứa nổi?"*. Bất cứ thứ gì trả lời được
  đều phải vào `S9` — **không được ép nó vào section gần đúng, cũng không được bỏ.**

## Section là **sàn tối thiểu**, không phải trần

Danh sách dưới đây là *mức bao phủ tối thiểu phải đạt*, không phải giới hạn
những gì được nghĩ tới. Hai quy tắc đi kèm:

1. **Không ép khuôn.** Một phát hiện không khớp section nào → vào `S9`, giữ
   nguyên chữ của tài liệu. Ép nhầm chỗ tệ hơn để ngoài phân loại.
2. **Đủ section không có nghĩa là xong.** Điều kiện dừng là *đã đọc hết tài
   liệu*, không phải *mỗi section đã có vài dòng*.

## Các section phải sinh ra

| Section | ID prefix | Nội dung |
|---|---|---|
| S1. Business context | `BC-` | Mục tiêu hệ thống, actor, phân hệ |
| S2. Candidate entities | `EN-` | Danh từ nghiệp vụ + định nghĩa + đồng nghĩa |
| S3. Attributes | `AT-` | Thuộc tính của từng entity + kiểu + bắt buộc? + ví dụ giá trị |
| S4. Relationships | `RL-` | Quan hệ + lực lượng (cardinality) + tính bắt buộc (optionality) |
| S5. Business rules & constraints | `BR-` | Ràng buộc, công thức, hợp lệ hóa, trạng thái & chuyển trạng thái |
| S6. Process / lifecycle | `PR-` | Use case ảnh hưởng dữ liệu: tạo/sửa/xóa/duyệt gì |
| S7. Volume & performance | `VP-` | Số lượng, tần suất, truy vấn nóng, báo cáo, retention |
| S8. Non-functional & compliance | `NF-` | Multi-tenancy, audit, PII, i18n, timezone, backup, tích hợp |
| **S9. Unclassified / insight** | `XX-` | **Mọi phát hiện có ảnh hưởng tới dữ liệu nhưng không khớp S1–S8**: đặc thù ngành, ràng buộc pháp lý lạ, giả định ngầm của nghiệp vụ, mâu thuẫn quy trình, chất lượng dữ liệu cũ, thói quen vận hành thực tế… |

> `S9` rỗng ở một tài liệu BA thật là **dấu hiệu đáng nghi**, không phải dấu hiệu
> tốt: hoặc tài liệu quá sơ sài, hoặc lượt 3 đã bị làm qua loa. Nếu `S9` rỗng,
> nói rõ điều đó ở gate thay vì lặng lẽ bỏ qua.

Mỗi mục ghi theo khuôn:

```
DR-013 | S5 | Business rule
Statement (EN): An invoice cannot be voided after it has been paid.
Diễn giải (VI): Hóa đơn đã thanh toán thì không được hủy.
Source: BA-02 §4.3.1
Confidence: high | medium | low
Impacts: invoice.status, payment
```

## Quy tắc chất lượng

- **Không suy diễn im lặng.** Suy luận hợp lý thì ghi `Confidence: medium` +
  một dòng `Assumption:`.
- **Mâu thuẫn thì giữ cả hai** và đưa vào `CONFLICTS`, không tự chọn bên.
- **Đồng nghĩa phải gộp**: "khách hàng", "client", "buyer" → một entity, ghi
  các biến thể vào `01-glossary.md`.
- **Danh từ không phải lúc nào cũng là entity**: phân biệt entity / attribute /
  giá trị enum / thuật ngữ UI. Xem `references/extraction-checklist.md §B`.
- Mọi ID phải liên tục và duy nhất — đây là khóa để truy vết ở Stage 5.
- **Khuôn mẫu phục vụ nội dung, không ngược lại.** Một `BR-*` cần 5 dòng giải
  thích thì viết 5 dòng; đừng nén nghiệp vụ phức tạp vào một ô bảng cho gọn.

## Artifact

- `workspace/<project>/01-data-requirements.md` ← `templates/01-requirements/01-data-requirements.md`
- `workspace/<project>/01-glossary.md` ← `templates/01-requirements/01-glossary.md`

## Gate

Báo cáo: số requirement theo section (kể cả `S9`), danh sách `CONFLICTS`, danh
sách `OPEN QUESTIONS` xếp theo mức độ ảnh hưởng tới thiết kế, và **những gì
lượt 3 tìm thêm được so với lượt 2** — nếu lượt 3 không tìm thêm gì, nói rõ. Xin xác nhận, cập nhật
`STATE.md`, rồi sang Stage 2.
