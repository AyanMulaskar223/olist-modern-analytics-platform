# Design Doc: Marts Layer & Star Schema Architecture

**Author:** [Your Name]
**Status:** Draft
**Phase:** Phase 4 (Marts Implementation)
**Related Issue:** [FEAT] Phase 4: Marts Layer (Star Schema)

---

## 1. Context & Business Objectives

**Overview:**
Transformation of logic-heavy intermediate models into a Kimball Star Schema optimized for downstream consumption.

**Business Goal:**
Enable high-performance, trusted analysis of Revenue, Retention, and Logistics for the Executive Dashboard.

**Stakeholders:**
Executive Leadership (CEO/CFO), Regional Sales Managers.

**Problem Statement:**
Current reporting is based on normalized tables requiring complex joins, leading to slow query performance (>10s) and inconsistent metric definitions.

---

## 2. Scope & Constraints

### ✅ In Scope:

- Implementation of Kimball Star Schema (1 Fact, 4 Conformed Dimensions)
- Row-Level Security (RLS) enforcement via the Bridge Table pattern
- Incremental Materialization strategy for fact tables
- Data Contracts enforcement at the schema level

### ❌ Out of Scope:

- Real-time streaming (Batch frequency set to Hourly)
- Machine Learning / Predictive analytics features
- Self-Service access to Raw/Staging layers

---

## 3. Architecture & Data Flow

- **Design Pattern:** Dimensional Modeling (Star Schema)
- **Data Flow:** Staging (Raw) → Intermediate (Clean/Joined) → Marts (Business Entities) → Power BI (Import)

![Marts Data Model Star Schema](../architecture/marts_data_model.png)

---

## 4. Detailed Data Model Design

### 4.1 System & Audit Tables

**Table: meta_project_status**

- **Grain:** 1 Row (Singleton)
- **Purpose:** High-frequency observability for Power BI dashboards
- **Columns:**
  - pipeline_run_at (Timestamp of last dbt build)
  - dbt_version (Audit info)
  - status (System health flag)

### 4.2 Fact Strategy (fct_order_items)

- **Source:** int_sales\_\_order_items_joined
- **Materialization:** incremental
- **Partition Key:** order_date_dt
- **Business Logic:** Includes ALL order statuses (delivered, canceled, unavailable) to support "Lost Revenue" analysis.
- **Key Columns:**
  - **Primary Key:** order_item_sk (Surrogate Key)
  - **Foreign Keys:** customer_sk, product_sk, seller_sk, order_date_dt
  - **Degenerate Dims:** order_id (For Count Distinct), order_status (For Lost Revenue analysis)
- **Metrics:**
  - price_brl (Revenue)
  - freight_value_brl (Shipping Cost)
- **Quality Flags (The "Raw vs. Verified" Strategy):**
  - is_verified (Boolean): True if data meets strict quality rules (e.g., price > 0)
  - quality_issue_reason (String): If unverified, explains why (e.g., "Negative Price")
- **Strategy:** We expose "Bad Data" with a flag rather than dropping it, allowing the business to measure the "Cost of Poor Quality."

### 4.3 Dimension Strategy

**Standard Dimensions:**

- **dim_customers**
  - Keys: customer_sk, customer_unique_id
  - Attributes: customer_city, customer_state (Location denormalized for performance)
- **dim_products**
  - Keys: product_sk, product_id
  - Attributes: category_name_en (English translation), product_weight_g, product_photos_qty
- **dim_sellers**
  - Keys: seller_sk, seller_id
  - Attributes: seller_city, seller_state_code (RLS Target)
- **dim_date**
  - Keys: date_day (PK)
  - Attributes: year, month_name, is_weekend, year_month_number (Sort Key)

#### **Grain Table**

| Table               | Grain                                  | Primary Key   | Notes                                 |
| ------------------- | -------------------------------------- | ------------- | ------------------------------------- |
| meta_project_status | Singleton (one row)                    | -             | System/audit info                     |
| fct_order_items     | 1 row per order item (all statuses)    | order_item_sk | Fact table                            |
| dim_customers       | 1 row per unique customer              | customer_sk   | Conformed dimension                   |
| dim_products        | 1 row per unique product               | product_sk    | Conformed dimension                   |
| dim_sellers         | 1 row per unique seller                | seller_sk     | Conformed dimension                   |
| dim_date            | 1 row per day                          | date_day      | Date dimension                        |
| dim_security_rls    | 1 row per user principal               | upn           | RLS mapping                           |
| dim_rls_bridge      | 1 row per (access_group, seller_state) | composite key | Bridge for RLS (many-to-many support) |

---

## 4.4 Security Implementation (Bridge Pattern)

- **Challenge:** A Many-to-Many relationship exists where one Sales Manager may oversee multiple Seller Regions.
- **Solution:** Decoupled Security Model.
  - **dim_security_rls:** Maps User Principal Name (UPN) to Access_Group_ID
  - **dim_rls_bridge:** Maps Access_Group_ID to Seller_State_Code
  - **Filter Flow:** User → Security Dim → Bridge → Seller Dim → Fact

---

## 5. Power BI Readiness

- **Column Naming:** All columns aliased to business-friendly terms (e.g., product_category_name_en → Category, price_brl → Revenue)
- **Hidden Columns:** Surrogate Keys (\_sk) and System Flags (dbt_updated_at, dbt_valid_from) are hidden in downstream views
- **Performance:** Model strictly enforces One-to-Many relationships to enable high-performance Star Join optimization in Power BI VertiPaq engine

---

## 6. Data Governance & Contracts

- **Schema Enforcement:** contract: {enforced: true} enabled in \_models. yml
- **FinOps Strategy:** meta_project_status table allows Power BI to check freshness without scanning the 100M row Fact table

---

## 7. Testing & Observability Plan

### 7.1 dbt Generic Tests (Schema Level)

- **Standard tests applied in schema.yml:**
  - Uniqueness: unique on all \*\_sk columns
  - Completeness: not_null on all Keys and Metrics
  - Referential Integrity: relationships ensuring every fct.customer_sk exists in dim_customers
  - Constraints: accepted_values for order_status

### 7.2 dbt Singular Tests (Business Logic)

- **Custom SQL tests in tests/ folder:**
  - Logic: assert_delivered_after_ordered.sql (Ensures delivery_date ≥ order_date)
  - Financial: assert_positive_revenue.sql (Ensures price_brl is not negative unless flagged)
  - SLA: assert_freshness_24h.sql (Ensures data is not stale)

---

## 8. Risks & Trade-offs

- **Trade-off:** Star Schema vs. OBT (One Big Table)
- **Decision:** Star Schema was chosen over OBT
- **Reasoning:** While OBT offers faster initial query speed for simple aggregates, the Bridge Table RLS requirement necessitates a normalized dimension structure. Star Schema provides the best balance of Security flexibility and Query Performance.

---

## 9. Rollout Plan

- Deploy Dimensions: dim_customers, dim_products, dim_sellers, dim_date
- Deploy Security: dim_security_rls, dim_rls_bridge
- Deploy Fact: fct_order_items (Full Refresh)
- Deploy Meta: meta_project_status
- Run Tests: `dbt test --select marts`
- Documentation: Generate dbt docs
