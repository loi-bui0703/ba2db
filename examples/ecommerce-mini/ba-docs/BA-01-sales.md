# BA-01 — Online sales process (excerpt)

*Fictional document, written to resemble a real BA deliverable — including its
gaps and one internal contradiction.*

## 2. Actors and objects

**2.1 Customer.** A customer registers with an email address and full name. Each
customer is given a customer code by the system. Sales staff search customers by
code or by name.

**2.3 Product.** Each product has a code, a name, a unit price, and a unit of
measure. Prices are adjusted periodically by the merchandising team.

## 3. Ordering

**3.1** A customer creates an order. An order belongs to exactly one customer.
An order must contain at least one product line.

**3.2** Each order line records the product, the quantity, and the price.

**3.3** The price on an order line is the product price **at the moment the
order was placed**. Later price changes must not alter historical orders.

**3.4** Order statuses: draft → confirmed → paid → shipped. An order may be
cancelled while it is still in draft or confirmed state. A paid order cannot be
cancelled; it must go through the refund process (see BA-04, out of scope).

**3.6** The order total is the sum of its lines. Sales staff see the total
immediately when adding a line.

## 4. Delivery

**4.1** Goods are delivered to the address the customer provides when ordering.

## 5. Reporting

**5.1** The sales manager needs a daily revenue report: total value of paid
orders per day, filterable by date range.

**5.2** Expected volume is about 5,000 orders per day, peaking between 18:00 and
21:00. Order data must be retained for 7 years for tax purposes.

## 6. Other requirements

**6.1** All data changes must record who made them and when.

**6.2** Customer personal information must be protected in accordance with
applicable data protection law.

**6.4** Orders are cancellable at any time before shipping.
