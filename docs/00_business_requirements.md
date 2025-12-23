# Business Requirements – Olist Modern Analytics Platform

## 1. Business Domain

**Marketplace & Logistics (E-commerce)**

Olist operates a multi-seller e-commerce marketplace across Brazil, connecting sellers and customers while coordinating order fulfillment, shipment, and delivery through logistics partners.

---

## 2. Business Problem (Current State)

Olist lacks a **centralized, trusted analytics layer** to monitor and analyze:

- Sales performance and revenue trends
- Customer purchasing behavior and retention
- Seller contribution and marketplace health
- Regional demand across Brazil
- Order delivery efficiency and SLAs
- Payment behavior and risk signals

Data is spread across multiple transactional tables and requires ad-hoc joins and manual prep, resulting in:

- Slow reporting and inconsistent refresh cycles
- Inconsistent KPI definitions across teams
- High manual effort to prepare datasets and dashboards
- Limited scalability for new analytics use cases
- Low trust in numbers (no “single source of truth”)

---

## 3. Desired Business Outcomes (Future State)

Build a **single source of truth analytics platform** that enables stakeholders to:

- Track revenue, orders, and growth trends over time
- Identify top-performing product categories, sellers, and regions
- Monitor delivery performance, delays, and bottlenecks
- Understand customer retention (repeat vs new buyers) and cohort behavior
- Analyze payment method adoption and impact on order value
- Reduce time-to-insight by powering standardized dashboards and self-serve analytics

---

## 4. Stakeholders & Users

| Stakeholder / Persona  | Primary Needs                                                   |
| ---------------------- | --------------------------------------------------------------- |
| Executive / Leadership | Weekly/monthly performance, growth, high-level KPIs             |
| Sales / Commercial     | Category and seller performance, marketplace contribution       |
| Operations / Logistics | Delivery time, delays, regional delivery efficiency             |
| Finance                | Revenue reconciliation, payment mix, AOV, reporting consistency |
| Data / Analytics Team  | Reliable models, documented KPIs, scalable datasets             |

---

## 5. Scope

### In Scope

- Curated analytics layer for **orders, payments, customers, sellers, products, delivery**
- Standardized KPI definitions (one version of truth)
- Dimensions and fact tables to support BI dashboards
- Historical reporting (batch)

### Out of Scope (for now)

- Real-time streaming analytics
- Predictive ML models (e.g., demand forecasting)
- External marketing attribution and ad spend integration

---

## 6. Key Business Questions

| ID  | Business Question                                                                 | Analytics Type |
| --- | --------------------------------------------------------------------------------- | -------------- |
| Q1  | How are total revenue and order volume trending over time?                        | Descriptive    |
| Q2  | Which product categories generate the most revenue and orders?                    | Descriptive    |
| Q3  | Which regions and states contribute most to revenue and orders?                   | Descriptive    |
| Q4  | How efficient is order delivery performance across regions?                       | Diagnostic     |
| Q5  | Which sellers contribute the most to revenue and order volume?                    | Descriptive    |
| Q6  | What payment methods are most commonly used and how do they impact order value?   | Diagnostic     |
| Q7  | How many customers are repeat buyers versus new customers?                        | Descriptive    |
| Q8  | Where do order delays occur most frequently (by state, carrier proxy, or seller)? | Diagnostic     |
| Q9  | What is the cancellation/unavailable rate and where is it highest?                | Diagnostic     |

---

## 7. KPI Definitions (Standardized)

### Primary KPIs

- **Total Revenue (BRL)**: Sum of payment values for eligible orders
- **Total Orders**: Count of eligible orders
- **Average Order Value (AOV)**: Total Revenue ÷ Total Orders
- **Average Delivery Time (Days)**: Delivered date − purchase date (average)
- **Repeat Customer Rate**: % of customers with ≥ 2 eligible orders

### Supporting KPIs

- **Orders by Category**
- **Revenue by State**
- **Seller Contribution %**
- **Orders by Payment Type**
- **On-Time Delivery %**
- **Cancellation Rate** (optional but recommended)
- **Unavailable Rate** (optional but recommended)

---

## 8. KPI Mapping (Business → Metric → Data)

| Business Question | KPI                           | Definition                                      | Source Tables                   |
| ----------------- | ----------------------------- | ----------------------------------------------- | ------------------------------- |
| Q1                | Total Revenue                 | Sum(payment_value) for eligible orders          | orders, payments                |
| Q1                | Total Orders                  | Count(orders) for eligible orders               | orders                          |
| Q2                | Revenue by Category           | Revenue grouped by product category             | order_items, products, payments |
| Q3                | Revenue by State              | Revenue grouped by customer state               | customers, orders, payments     |
| Q4                | Avg Delivery Time             | Avg(delivered_date − purchase_date)             | orders                          |
| Q5                | Seller Revenue                | Revenue attributed to seller via order items    | sellers, order_items, payments  |
| Q6                | AOV by Payment                | Avg order value grouped by payment type         | payments, orders                |
| Q7                | Repeat Customer Rate          | % customers with ≥ 2 eligible orders            | orders, customers               |
| Q8                | On-Time Delivery %            | % delivered on/before estimated date            | orders                          |
| Q9                | Cancellation/Unavailable Rate | % orders with status in (canceled, unavailable) | orders                          |

> Note: If payments are recorded at the order level (not item level), seller/category revenue attribution requires allocation logic via `order_items` (e.g., proportional by item price). Define and document the chosen rule.

---

## 9. Assumptions & Constraints

- **Eligibility rule (default):** only `delivered` orders contribute to revenue KPIs
- `canceled` and `unavailable` are excluded from revenue unless explicitly modeled as “lost revenue”
- Dataset represents **historical data** (no live updates)
- Currency assumed to be **Brazilian Real (BRL)**
- Timezone handling: timestamps should be standardized (document chosen timezone)
- Known data quality risks may exist (missing geolocation, duplicates, inconsistent timestamps)

---

## 10. Data Quality & Governance (Requirements)

- KPI definitions must be **documented and versioned**
- Data models must include:
  - Clear grain definitions (order-level, item-level, customer-level)
  - Primary keys and join keys documented
  - Data tests for:
    - Uniqueness (e.g., order_id)
    - Not-null constraints for critical fields
    - Accepted values for statuses
    - Referential integrity between facts/dimensions
- Produce a **data dictionary** for BI users (field meaning, calculation notes)

---

## 11. Success Criteria

- KPI parity: core KPIs match agreed baseline definitions within an acceptable tolerance
- Faster delivery of insights: reduce manual reporting effort and time-to-dashboard
- Adoption: stakeholders use standardized dashboards for recurring reporting
- Reliability: scheduled refresh completes successfully with monitoring/alerting
