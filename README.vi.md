<div align="center">

# ba2db

**Biến tài liệu BA thành bản thiết kế database hoàn chỉnh, truy vết được.**

[![CI](https://github.com/loi-bui0703/ba2db/actions/workflows/ci.yml/badge.svg)](https://github.com/loi-bui0703/ba2db/actions/workflows/ci.yml)
[![npm](https://img.shields.io/npm/v/ba2db?color=blue)](https://www.npmjs.com/package/ba2db)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen)](https://nodejs.org)
[![Zero dependencies](https://img.shields.io/badge/dependencies-0-success)](./package.json)

Một bộ agent skill — không phải service. Dùng được với Claude Code, Cursor,
Codex, Copilot, OpenCode, hoặc bất kỳ agent nào đọc được file.

[English](./README.md) · [Tiếng Việt](./README.vi.md)

</div>

---

## Vấn đề

Bảo một AI agent "thiết kế database cho đống yêu cầu này", ba mươi giây sau bạn
có DDL. Các bảng trông rất hợp lý. Một số trong đó mô tả một nghiệp vụ **không
tồn tại**, và bạn chỉ phát hiện ra khi integration test.

Lỗi không nằm ở kiến thức của model. Lỗi nằm ở chỗ không có gì ép agent phải
**đọc trước khi thiết kế**, phải **nói rõ mỗi bảng đến từ đâu**, và phải **thừa
nhận những gì tài liệu chưa bao giờ nói**.

## ba2db làm gì

Thay một cú nhảy lớn bằng sáu giai đoạn có cổng chặn, mỗi giai đoạn sinh ra
artifact mà giai đoạn sau dùng làm đầu vào:

```
Tài liệu BA
    │
    ├─ 0  Tiếp nhận & chốt phạm vi   → có gì trong tay, thiết kế cho cái gì
    ├─ 1  Trích xuất yêu cầu          → 9 section, ID đánh số, mục nào cũng có nguồn
    ├─ 2  Mô hình khái niệm           → ERD mà người làm nghiệp vụ đọc và duyệt được
    ├─ 3  Thiết kế logic              → bảng, khóa, kiểu dữ liệu, data dictionary
    ├─ 4  Thiết kế vật lý             → DDL chạy được, kế hoạch index, ghi chú migration
    └─ 5  Review & bàn giao           → ma trận truy vết, findings, câu hỏi còn mở
                                        │
                                        ▼
                        Bản thiết kế bạn bảo vệ được từng dòng
```

Ba nguyên tắc làm nên độ tin cậy:

| Nguyên tắc | Tác dụng |
|---|---|
| **Không bịa nghiệp vụ** | Mọi entity/attribute/rule ghi nguồn `BA-xx §mục`. Thiếu thì vào `OPEN QUESTIONS`, không đoán bừa. |
| **Truy vết hai chiều** | Requirement không có bảng = *thiếu việc*. Bảng không có requirement = *bịa ra*. Cả hai đều bị báo là lỗi. |
| **Cổng chặn mỗi giai đoạn** | Agent dừng lại, tóm tắt, chờ bạn. Sai sót bị bắt ở ERD, không phải ở DDL. |

## Cài đặt

```bash
npx ba2db install
```

Lệnh này tự nhận diện agent bạn đang dùng, hỏi cài vào đâu, rồi cài:

```
Detected:
  ✓ Claude Code  /Users/you/.claude
  ✓ Cursor       /Users/you/.cursor

Which host do you want to install into?
  ● 1) Claude Code
    2) Cursor

✓ Installed ba2db for Claude Code (global)
  skill → /Users/you/.claude/skills/ba2db
```

<details>
<summary><b>Các cách cài khác</b></summary>

**Không hỏi đáp (dùng trong script/CI)**

```bash
npx ba2db install --host claude-code --global --yes
```

**Máy không có Node**

```bash
curl -fsSL https://raw.githubusercontent.com/loi-bui0703/ba2db/main/install.sh | bash
```

**Từ bản clone**

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cd ba2db && ./install.sh --host cursor --project
```

**Thủ công, cho mọi agent khác**

```bash
npx ba2db prompt     # in ra prompt để copy-paste
```

</details>

### Host được hỗ trợ

| Host | Cách cài | Phạm vi |
|---|---|---|
| Claude Code | thư mục skill | global · project |
| Cursor | `.cursor/rules/ba2db.mdc` → trỏ tới skill | global · project |
| Codex / AGENTS.md | chèn block vào `AGENTS.md` | project |
| GitHub Copilot | chèn block vào `copilot-instructions.md` | project |
| OpenCode | `.opencode/rules/ba2db.md` | project |
| Agent khác | prompt copy-paste | — |

File rule luôn **trỏ tới** skill chứ không sao chép nội dung. Một nguồn sự thật
duy nhất, nên không bao giờ có chuyện host này lệch phiên bản với host kia.

Thiếu host bạn dùng? [Mở host request](https://github.com/loi-bui0703/ba2db/issues/new?template=host-request.yml)
— thêm một host chỉ là thêm một entry trong `src/hosts.mjs`.

## Sử dụng

```bash
npx ba2db init my-project          # tạo workspace
cp ~/Downloads/*.docx workspace/my-project/ba-docs/
```

Rồi nói với agent:

```
Thiết kế database từ tài liệu BA trong workspace/my-project/ba-docs/.
DBMS đích: PostgreSQL 16.
```

Agent nạp skill, chạy Stage 0, rồi dừng chờ bạn xác nhận. Kết quả là mười một
artifact:

```
workspace/my-project/
├── 00-intake-report.md              phạm vi, giả định, câu hỏi mở
├── 01-data-requirements.md          9 section, mục nào cũng có nguồn
├── 01-glossary.md                   thuật ngữ, từ đồng nghĩa, chỗ nhập nhằng
├── 02-conceptual-erd.md             ERD Mermaid + danh mục entity
├── 03-logical-schema.md             bảng, khóa, quyết định chuẩn hóa
├── 03-data-dictionary.md            mọi cột, có kiểu và có nguồn
├── 04-schema.sql                    DDL chạy được
├── 04-index-plan.md                 mỗi index có một truy vấn thật biện minh
├── 04-migration-notes.md            triển khai, phân quyền, backup, PII
├── 05-review-report.md              findings theo mức độ, câu hỏi còn mở
└── 05-traceability-matrix.md        requirement ⇄ schema, cả hai chiều
```

Xem [`examples/ecommerce-mini/`](./examples/ecommerce-mini/) để biết một lần
chạy hoàn chỉnh trông như thế nào.

## Skill này biết những gì

Tám tài liệu tra cứu, **chỉ nạp khi cần** — nên mỗi giai đoạn chỉ tốn context
cho đúng phần nó dùng:

| Tài liệu | Nội dung |
|---|---|
| `extraction-checklist.md` | 12 nhóm tín hiệu cần quét; cách phân biệt entity với attribute |
| `naming-conventions.md` | Quy ước đặt tên, kiểu dữ liệu chuẩn theo từng DBMS, cột audit bắt buộc |
| `normalization.md` | 1NF→BCNF, và bốn thứ phải ghi ra trước khi denormalize |
| `modeling-patterns.md` | SCD/versioning, multi-tenant, party model, cây phân cấp, i18n, state machine |
| `anti-patterns.md` | EAV, polymorphic FK, god table, float cho tiền… tổng 16 mục |
| `indexing-and-performance.md` | Chọn index, thứ tự cột composite, partition, ước lượng dung lượng |
| `dbms-notes.md` | Khác biệt PostgreSQL · MySQL 8 · SQL Server · Oracle |
| `review-checklist.md` | 8 nhóm kiểm tra nghiệm thu cuối |

## CLI

```
npx ba2db <command>

  install        Cài vào agent đã nhận diện được
  uninstall      Gỡ ra — không đụng tới rule của bạn
  list           Xem ba2db đang được cài ở đâu
  doctor         Kiểm tra bản cài còn đủ và nguyên vẹn
  init <slug>    Tạo workspace thiết kế
  prompt         In prompt copy-paste
  hosts          Liệt kê host hỗ trợ, đánh dấu host có trên máy này
```

## Các quyết định thiết kế

<details>
<summary><b>Vì sao không có server, không MCP, không dependency?</b></summary>

Bài toán cần giải là **kỷ luật** của agent, không phải **trí nhớ** hay **công
cụ**. Kỷ luật thì viết bằng chữ. Thêm một runtime vào đây không mua được gì mà
mất tính di động, thêm ma sát khi cài, và mở rộng bề mặt supply chain.

Nên: chỉ Markdown và shell, zero dependency npm, không gọi mạng, không telemetry.
Chạy được offline, trên mọi model, và bạn đọc hết source trong một buổi chiều.
</details>

<details>
<summary><b>Vì sao chín section — cấu trúc cứng vậy có làm agent tư duy hẹp không?</b></summary>

Có, nếu danh sách đó đóng. Ba cơ chế giữ cho nó mở:

- **`S9 — Unclassified / insight`** hứng mọi thứ không khớp S1–S8. `S9` rỗng ở
  một tài liệu BA thật bị coi là **đáng nghi**, không phải là sạch sẽ.
- **Ba lượt đọc**: lượt 1 đọc mở và *đóng checklist lại*, lượt 2 mới phân loại,
  lượt 3 là lượt *challenge* — tự hỏi tài liệu còn nói gì mà chín section chưa
  chứa nổi.
- **Checklist là lưới an toàn, không phải khung tư duy** — nó có hẳn một mục
  liệt kê năm dấu hiệu checklist đang làm hại (mọi entity đều đúng 4–5 attribute,
  không có mục nào `Confidence: low`…).

Cấu trúc *có* làm agent hẹp lại. Đó là đánh đổi có chủ ý: một phát hiện bị xếp
nhầm section thì cứu được; một bảng bịa ra đầy tự tin thì không.
</details>

<details>
<summary><b>Vì sao tài liệu song ngữ nhưng code luôn tiếng Anh?</b></summary>

Tên bảng/cột tiếng Việt làm hỏng tooling, ORM và autocomplete của mọi developer
phía sau. Nhưng **phần giải thích** bằng tiếng Việt mới là thứ giúp một BA người
Việt thực sự duyệt được mô hình. Nên: tài liệu EN/VI; định danh `snake_case` và
toàn bộ SQL luôn tiếng Anh.
</details>

## Đóng góp

Issue báo **thiết kế tệ mà skill sinh ra** là thứ giá trị nhất bạn có thể gửi —
đó là lúc sản phẩm hỏng, và nó sửa được. Xem [CONTRIBUTING.md](./CONTRIBUTING.md).

```bash
git clone https://github.com/loi-bui0703/ba2db.git
cd ba2db && node test/run.mjs     # zero deps, không cần build
```

## Giấy phép

[MIT](./LICENSE) © loi-bui0703
