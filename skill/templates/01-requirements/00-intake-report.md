# 00 — Intake Report · Biên bản tiếp nhận

Project: `<project-slug>` · Date: `<YYYY-MM-DD>` · Author: `<agent/人>`

## 1. Document inventory · Kiểm kê tài liệu

| ID | Path | Type | Coverage | Quality |
|---|---|---|---|---|
| BA-01 | | SRS | | complete |

## 2. Scope · Phạm vi

**In scope:**
- 

**Out of scope:**
- 

## 3. Target platform · Nền tảng đích

| Item | Value |
|---|---|
| DBMS + version | **`undecided` — quyết định ở Stage 1B** (`01b-dbms-decision.md`) |
| Workload | OLTP / OLAP / mixed |
| Expected users | |
| Peak volume | |
| Retention | |
| Legacy system | none / `<mô tả>` |

> Stage 0 **không chọn** DBMS. Ở đây chỉ ghi lại *ràng buộc nền tảng* để
> Stage 1B lập luận. Điền một engine vào đây là chọn trước khi có dữ kiện.

### 3.1 Platform constraints · Ràng buộc nền tảng (đầu vào cho Stage 1B)

| Ràng buộc | Giá trị / "chưa biết" |
|---|---|
| Engine đội vận hành đang chạy | |
| Cloud / managed service đã chốt | |
| Giới hạn giấy phép & chi phí | |
| Framework, ORM, migration runner | |
| Ràng buộc tuân thủ & vị trí dữ liệu | |

## 4. Non-functional flags

| Flag | Y/N | Note |
|---|---|---|
| Multi-tenant | | |
| Audit trail | | |
| Soft delete | | |
| PII / encryption | | |
| i18n / multi-language | | |
| Timezone handling | | |
| External integrations | | |

## 5. Assumptions · Giả định đã chọn

| # | Assumption (EN) | Giả định (VI) | Risk if wrong |
|---|---|---|---|
| A-01 | | | |

## 6. Open questions · Câu hỏi mở

| # | Question (EN) | Câu hỏi (VI) | Blocks stage | Owner |
|---|---|---|---|---|
| Q-01 | | | 1 | BA |
