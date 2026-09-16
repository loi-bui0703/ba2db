# 01 — Data Requirements · Yêu cầu dữ liệu

Project: `<slug>` · Sources: BA-01…BA-nn · Total requirements: `<n>`

> Mọi mục đều có `Source`. Không có nguồn → phải nằm ở §OPEN QUESTIONS.

## S1. Business context (`BC-*`)

| ID | Statement (EN) | Diễn giải (VI) | Source |
|---|---|---|---|
| BC-001 | | | BA-01 §1.2 |

## S2. Candidate entities (`EN-*`)

| ID | Entity | Definition (EN) | Định nghĩa (VI) | Synonyms | Business key | Source | Confidence |
|---|---|---|---|---|---|---|---|
| EN-001 | customer | | | khách hàng, client | customer_code | BA-01 §2.1 | high |

## S3. Attributes (`AT-*`)

| ID | Entity | Attribute | Type (business) | Required | Sample / domain | Source | Confidence |
|---|---|---|---|---|---|---|---|
| AT-001 | customer | full_name | text | yes | "Nguyễn Văn A" | BA-01 §2.1 | high |

## S4. Relationships (`RL-*`)

| ID | A | Verb | B | Cardinality | Optionality | Note | Source |
|---|---|---|---|---|---|---|---|
| RL-001 | customer | places | order | 1:N | order bắt buộc có customer | | BA-01 §3.1 |

## S5. Business rules & constraints (`BR-*`)

```
BR-001
Statement (EN):
Diễn giải (VI):
Enforceable as: CHECK | UNIQUE | FK | trigger | application
Source:            Confidence:
Impacts:
```

## S6. Process / lifecycle (`PR-*`)

| ID | Use case | Data effect (C/R/U/D) | Entities touched | Source |
|---|---|---|---|---|
| PR-001 | Tạo đơn hàng | C | order, order_line | BA-02 §4.1 |

## S7. Volume & performance (`VP-*`)

| ID | Item | Estimate | Frequency | Retention | Source |
|---|---|---|---|---|---|
| VP-001 | order | 5.000/ngày | peak 18:00–21:00 | 7 năm | BA-03 §2 |

**Hot queries / reports:**

| ID | Query or report | Filters | Sort | Expected latency | Source |
|---|---|---|---|---|---|
| VP-010 | | | | | |

## S8. Non-functional & compliance (`NF-*`)

| ID | Requirement (EN) | Yêu cầu (VI) | Design impact | Source |
|---|---|---|---|---|
| NF-001 | | | | |

## S9. Unclassified / insight (`XX-`)

> Phát hiện có ảnh hưởng tới dữ liệu nhưng không khớp S1–S8. Giữ nguyên chữ của
> tài liệu, không diễn giải lại cho vừa khuôn. Rỗng = đáng nghi, phải giải thích.

| ID | Finding (EN) | Phát hiện (VI) | Why it matters for the data model | Source | Confidence |
|---|---|---|---|---|---|
| XX-001 | | | | | |

---

## CONFLICTS · Mâu thuẫn giữa các tài liệu

| # | Topic | Version A (source) | Version B (source) | Needs decision by |
|---|---|---|---|---|

## OPEN QUESTIONS

| # | Question (EN) | Câu hỏi (VI) | Impact | Assumed default |
|---|---|---|---|---|

## ASSUMPTIONS
| # | Assumption | Why | Risk if wrong |
|---|---|---|---|
