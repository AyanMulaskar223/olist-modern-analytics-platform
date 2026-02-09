# 📊 Power BI Analytics Dashboard

**(Olist Modern Analytics Platform)**

---

## 1️⃣ Overview

- **Purpose:** To provide a centralized, governed decision-support system that replaces ad-hoc SQL reporting with self-service analytics.
- **Target Audience:** C-Suite Executives (Strategic View), Regional Managers (Operational View), and Analytics Engineers (Data Quality View).
- **Decisions Enabled:** Real-time monitoring of revenue trends, identification of logistics bottlenecks, and segmentation of high-value sellers.

---

## 2️⃣ Business Questions Covered

This dashboard answers **6 strategic questions** validated by stakeholders:

| ID     | Business Question                              | Analytics Type | Page                  |
| :----- | :--------------------------------------------- | :------------- | :-------------------- |
| **Q1** | How are revenue and orders trending MoM?       | Descriptive    | Overview              |
| **Q2** | Which product categories drive the most value? | Descriptive    | Category & Product    |
| **Q3** | Which regions and states are underperforming?  | Descriptive    | Regional Analysis     |
| **Q4** | Where are logistics bottlenecks occurring?     | Diagnostic     | Logistics & Ops       |
| **Q5** | Who are our top-performing sellers?            | Descriptive    | Seller Performance    |
| **Q6** | Are we retaining customers effectively?        | Descriptive    | Customer Intelligence |

---

## 3️⃣ Data Architecture & Sources

### 3.1 Source Systems

- **Primary Source:** Snowflake Data Warehouse `[PROD]`.
- **Transformation Layer:** dbt (Data Build Tool) `marts` models.

### 3.2 Data Flow

1.  **Snowflake:** Raw data ingestion and modeling.
2.  **dbt:** Transformation into Star Schema facts/dimensions.
3.  **Power BI:** Import Mode ingestion with Incremental Refresh.
4.  **Service:** Published to `Olist Analytics [PROD]` Workspace $\to$ Organizational App.

---

## 4️⃣ Semantic Model Design

### 4.1 Modeling Approach

- **Kimball Star Schema:** Optimized for read-heavy analytical queries.
- **Fact Table:** `Sales` (Granularity: One row per order item).
- **Dimensions:** `Date`, `Product`, `Customer`, `Seller`, `Security Rules`.

### 4.2 Relationships & Grain

- **Grain:** Transaction level (Order Item).
- **Relationships:** Strict **1-to-Many** relationships using surrogate keys (`*_sk`).
- **Referential Integrity:** Enforced in dbt; "Orphaned" rows are flagged, not dropped.

### 4.3 Security Model (RLS)

- **Strategy:** Dynamic Row-Level Security (RLS) based on User Principal Name (UPN).
- **Implementation:** A `Security Bridge` table filters the `Customer` dimension based on the user's assigned region (e.g., "SP Manager" sees only São Paulo data).

---

## 5️⃣ Measures & KPI Strategy

### 5.1 KPI Design Principles

- **Centralization:** All logic resides in a dedicated `_Measures` table; no visual-level calculations.
- **Formatting:** Currency (R$) and percentages enforced globally via Tabular Editor/BPA.

### 5.2 Raw vs Verified Metrics

- **Verified Metrics:** Filter strictly for `order_status = 'delivered'` (Finance View).
- **Raw Metrics:** Include all statuses (Ops View).
- **Impact:** Ensures the CEO sees "Real Revenue" while Ops sees "Potential Pipeline."

---

## 6️⃣ Data Quality & Trust Layer

- **Trust Signals:** Workspace marked as **"Official Source of Truth"** (Certified Dataset).
- **Data Quality Page:** Dedicated audit dashboard monitoring:
  - **Revenue at Risk:** Value of orders with data quality failures.
  - **Catalog Issues:** SKUs missing photos or dimensions.
  - **Logic Errors:** Impossible timestamps (e.g., Delivery Date < Order Date).

---

## 7️⃣ Performance Optimization

### 7.1 Query Folding Strategy

- **Approach:** All Power Query transformation steps (filtering, type casting) are structured to fold back to Snowflake SQL.
- **Validation:** Verified via "View Native Query" to ensure efficient data transfer.

### 7.2 Incremental Refresh

- **Scope:** Applied to the `Sales` fact table.
- **Policy:** Archive 10 Years, Refresh Last 1 Month.
- **Benefit:** Reduces daily refresh time from minutes to seconds by processing only delta changes.

---

## 8️⃣ Report Pages Overview

1.  **Executive Sales Overview:** High-level KPI cards, Revenue Trends, and Top 10 Products.
2.  **Supply Chain & Delivery:** Root Cause Analysis (Decomposition Tree) for delays.
3.  **Customer Intelligence:** Cohort analysis and retention rates.
4.  **Category & Product:** Tree maps and scatter plots for SKU performance.
5.  **Regional Analysis:** Geographic heat maps of revenue and freight costs.
6.  **Seller Performance:** Segmentation of sellers by volume vs. value.
7.  **Data Quality & Integrity:** Technical audit log for Analytics Engineers.
8.  **Detailed Order View:** Granular table for transaction-level inspection.

---

## 9️⃣ User Experience & Design Choices

- **Navigation:** Custom side-navigation bar for seamless page switching.
- **Interactions:** "Drill-through" enabled from State maps to City details.
- **Metric Selectors:** Field Parameters allow users to toggle charts between _Revenue_ and _Orders_ dynamically.
- **Mobile:** Dedicated "Executive Pulse" mobile layout for iOS/Android access.

---

## 🔟 Deployment & Environment Strategy

- **Workspaces:** Separate `[DEV]` (Sandbox) and `[PROD]` (Locked) environments.
- **Schedule:** Automated daily refresh at **06:15 PM IST** (UTC+05:30).
- **Distribution:** Content delivered via the **Olist Analytics App** to ensure a read-only experience for business users.

---

## 1️⃣1️⃣ Validation & Testing

- **BPA:** Passed **Best Practice Analyzer** check with **0 Issues**.
- **Reconciliation:** Total Revenue ($13M) tied out against Snowflake SQL queries.
- **RLS Testing:** "View As Role" used to verify regional isolation (SP vs. RJ).
- **Subscriptions:** Automated email delivery configured and tested.

---

## 1️⃣2️⃣ Screenshots

_(Stored in `/docs/screenshots/`)_

---

## 1️⃣3️⃣ Known Limitations & Assumptions

- **Currency:** All monetary values are in Brazilian Real (BRL).
- **Historical Data:** 2016 Pilot data is excluded from trend analysis to ensure consistent YoY comparisons.
- **Targets:** Revenue targets are estimated based on a flat +10% MoM growth assumption.

---

## 1️⃣4️⃣ Key Learnings & Business Impact

- **Before:** Business users relied on manual CSV dumps and ad-hoc SQL requests.
- **After:** Automated, mobile-ready insights available daily at 6:00 AM.
- **Impact:** Reduced time-to-insight from days to seconds; enabled proactive "Bad News" alerts for revenue drops.

---

## 1️⃣5️⃣ References

- [dbt Documentation](../dbt/README.md)
- [Business Requirements](../docs/business_requirements.md)
- [Architecture Diagram](../docs/architecture.png)
