# 01 — Data Requirements · Yêu cầu dữ liệu

Project: `ecommerce-mini` · Sources: BA-01 · Total requirements: 24

## S2. Candidate entities (`EN-*`)

| ID | Entity | Definition (EN) | Định nghĩa (VI) | Synonyms | Business key | Source | Confidence |
|---|---|---|---|---|---|---|---|
| EN-001 | customer | A person who places orders | Người đặt hàng | buyer | customer_code | BA-01 §2.1 | high |
| EN-002 | product | An item offered for sale | Mặt hàng được bán | item | product_code | BA-01 §2.3 | high |
| EN-003 | order | A purchase request by one customer | Yêu cầu mua của một khách | — | order_code | BA-01 §3.1 | high |
| EN-004 | order_line | One product within an order | Một dòng hàng trong đơn | line item | (order, line_no) | BA-01 §3.2 | high |

## S3. Attributes (`AT-*`)

| ID | Entity | Attribute | Type | Required | Sample | Source | Confidence |
|---|---|---|---|---|---|---|---|
| AT-001 | customer | customer_code | code | yes | CU000123 | BA-01 §2.1 | high |
| AT-002 | customer | full_name | text | yes | Nguyễn Văn A | BA-01 §2.1 | high |
| AT-003 | customer | email | email | yes | a@example.com | BA-01 §2.1 | high |
| AT-010 | product | unit_price | money | yes | 150000 | BA-01 §2.3 | high |
| AT-011 | product | uom | code | yes | pcs | BA-01 §2.3 | high |
| AT-020 | order | status | enum | yes | paid | BA-01 §3.4 | high |
| AT-021 | order | total_amount | money | yes | 450000 | BA-01 §3.6 | high |
| AT-022 | order | delivery_address | text | yes | — | BA-01 §4.1 | **medium** |
| AT-030 | order_line | quantity | decimal | yes | 3 | BA-01 §3.2 | high |
| AT-031 | order_line | unit_price | money | yes | 150000 | BA-01 §3.3 | high |

> `AT-022` is `medium`: §4.1 says the address is "provided when ordering" but
> never says whether it is stored on the customer, on the order, or both.
> **Assumption:** stored on the order, because §3.3 establishes the principle
> that an order captures its own state at the time it was placed.

## S4. Relationships (`RL-*`)

| ID | A | Verb | B | Cardinality | Optionality | Source |
|---|---|---|---|---|---|---|
| RL-001 | customer | places | order | 1:N | an order must have a customer; a customer may have zero orders | BA-01 §3.1 |
| RL-002 | order | contains | order_line | 1:N | an order must have ≥1 line | BA-01 §3.1 |
| RL-003 | product | appears in | order_line | 1:N | a line must name a product | BA-01 §3.2 |

## S5. Business rules (`BR-*`)

```
BR-001
Statement (EN): An order cannot be cancelled once it has been paid.
Diễn giải (VI): Đơn đã thanh toán thì không được hủy.
Enforceable as: trigger — depends on the previous status, not just the new one
Source: BA-01 §3.4    Confidence: high
Impacts: order.status
```

```
BR-002
Statement (EN): The unit price on an order line is the product price at the time
                the order was placed, and must not change afterwards.
Diễn giải (VI): Đơn giá trên dòng hàng là giá tại thời điểm đặt, không đổi về sau.
Enforceable as: snapshot column — order_line.unit_price must NOT be a lookup
Source: BA-01 §3.3    Confidence: high
```

```
BR-003
Statement (EN): An order must contain at least one line.
Diễn giải (VI): Một đơn phải có ít nhất một dòng hàng.
Enforceable as: application — a DB CHECK cannot span rows of a child table
Source: BA-01 §3.1    Confidence: high
```

```
BR-004
Statement (EN): Order status follows draft → confirmed → paid → shipped.
Diễn giải (VI): Trạng thái đơn đi theo draft → confirmed → paid → shipped.
Enforceable as: enum + trigger for transitions
Source: BA-01 §3.4    Confidence: high
```

```
BR-005
Statement (EN): The order total equals the sum of its lines.
Diễn giải (VI): Tổng đơn bằng tổng các dòng hàng.
Enforceable as: stored column maintained by trigger (see VP-010)
Source: BA-01 §3.6    Confidence: high
```

## S7. Volume & performance (`VP-*`)

| ID | Item | Estimate | Frequency | Retention | Source |
|---|---|---|---|---|---|
| VP-001 | order | 5,000/day | peak 18:00–21:00 | 7 years | BA-01 §5.2 |
| VP-002 | order_line | ~15,000/day | assumed 3 lines/order | 7 years | derived, **low** |
| VP-010 | Daily revenue report | filter `status='paid'` + date range | daily | — | BA-01 §5.1 |

## S8. Non-functional (`NF-*`)

| ID | Requirement | Design impact | Source |
|---|---|---|---|
| NF-001 | Record who changed what and when | audit columns on every table | BA-01 §6.1 |
| NF-002 | Protect customer personal data | mark PII; encrypt or restrict email/name | BA-01 §6.2 |

## S9. Unclassified / insight (`XX-*`)

| ID | Finding | Phát hiện | Why it matters | Source | Confidence |
|---|---|---|---|---|---|
| XX-001 | §3.4 defers refunds to BA-04, which is out of scope, but a paid order that cannot be cancelled must still have *some* terminal state | Hoàn tiền bị đẩy sang BA-04 ngoài phạm vi, nhưng đơn đã thanh toán vẫn cần một trạng thái kết thúc nào đó | The status enum may be incomplete; designing it as closed today could force a migration when BA-04 lands | BA-01 §3.4 | medium |
| XX-002 | Prices are "adjusted periodically" but no price history is requested anywhere | Giá "được điều chỉnh định kỳ" nhưng không chỗ nào yêu cầu lưu lịch sử giá | BR-002's snapshot satisfies the ordering case, but any future question like "what was this product's price last March" would be unanswerable | BA-01 §2.3 | medium |

---

## CONFLICTS

| # | Topic | Version A | Version B | Needs decision by |
|---|---|---|---|---|
| C-01 | When can an order be cancelled? | §3.4: only in `draft` or `confirmed`; a paid order cannot be cancelled | §6.4: "cancellable at any time before shipping" — which would include `paid` | BA owner |

**Not resolved by the agent.** §3.4 is the more specific statement and is
implemented, but §6.4 is preserved here verbatim so the BA can rule on it.

## OPEN QUESTIONS

| # | Question (EN) | Câu hỏi (VI) | Impact | Assumed default |
|---|---|---|---|---|
| Q-01 | Can a customer have more than one delivery address? | Một khách hàng có thể có nhiều địa chỉ giao hàng không? | Stage 2 — a `customer_address` entity or not | Address stored on the order only; **no separate address entity created** |
| Q-02 | Is `email` unique per customer? | Email có duy nhất theo khách hàng không? | Stage 3 — a UNIQUE constraint | Assumed unique |
| Q-03 | What happens to a paid order that the customer wants to return? | Đơn đã thanh toán mà khách muốn trả thì sao? | Stage 3 — completeness of the status enum | Out of scope per §3.4; enum left extensible |

## ASSUMPTIONS

| # | Assumption | Why | Risk if wrong |
|---|---|---|---|
| A-01 | ~3 lines per order | No figure given; needed for VP-002 sizing | Sizing estimate off; index plan unaffected |
| A-02 | Single currency (VND) | No multi-currency requirement appears anywhere | A `currency_code` column would have to be added to every money column |
