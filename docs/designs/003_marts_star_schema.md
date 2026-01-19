# 📄 Design Doc: Marts Layer & Star Schema Architecture

**Author:** Ayan Mulaskar
**Status:** 🟢 Approved for Implementation
**Phase:** Phase 4 (Marts & Consumption)
**Related Issue:** [FEAT] Phase 4: Marts Layer Implementation

---

## 1. Context & Business Objectives

### Overview

The transformation of logic-heavy Intermediate models into a high-performance **Kimball Star Schema** optimized for Power BI Import Mode.

### Business Goal

To enable trusted, sub-second analysis of Revenue, Retention, and Logistics KPIs for the Executive Dashboard, solving the current lack of historical context and "Lost Revenue" visibility.

### Problem Statement

Current reporting relies on normalized, joined-at-runtime tables. This causes:

- **Slow Performance:** Dashboard refreshes take >10s due to complex JOINs.
- **Ambiguous Metrics:** No standardized definition for "Canceled Orders" (Lost Revenue).
- **Silent Failures:** Stakeholders cannot distinguish between "No Sales Today" and "Pipeline Failed."

---

## 2. Scope & Constraints

### ✅ In Scope

- **Star Schema:** Implementation of 1 Fact (`fct_order_items`) and 4 Conformed Dimensions.
- **Observability:** "Two Clocks" metadata strategy to decouple Pipeline Health from Data Freshness.
- **Security:** Row-Level Security (RLS) via the Bridge Table Pattern to map Managers to Regions.
- **Governance:** Schema-level Data Contracts (`enforced: true`) and downstream Exposures.

### ❌ Out of Scope

- Real-time streaming (Batch frequency is set to **Daily**).
- Predictive Analytics / Machine Learning models.
- Self-Service access to Raw/Staging layers for business users.

---

## 3. Architecture & Data Flow

**Pattern:** Dimensional Modeling (Kimball Star Schema)

**Flow:**

```
RAW → STAGING → INTERMEDIATE → MARTS → Power BI
```

**Key Principle:** Logic happens in INTERMEDIATE. Marts are for scoping, renaming, and star schema alignment.

---

## 4. Detailed Data Model Design

### 4.1 System & Audit Strategy (The "Heartbeat")

**Table:** `meta_project_status`
**Grain:** Singleton (1 Row)
**Purpose:** Solves the "Frozen Source" problem inherent in the Olist dataset (Data ends in 2018, but Pipeline runs in 2026).

| Column                | Type      | Purpose                                                                |
| --------------------- | --------- | ---------------------------------------------------------------------- |
| `pipeline_last_run_at` | Timestamp | Engineering Clock: Proves the dbt pipeline ran successfully today.     |
| `data_valid_through`   | Date      | Business Clock: Proves the data context (e.g., "Data ends Aug 2018"). |

---

### 4.2 Fact Strategy (`fct_order_items`)

**Source:** `int_sales__order_items_joined`

**Materialization:**
- **Phase :** `incremental` (Append + Update) via `dbt_updated_at` watermark.

**Grain:** One row per Line Item.

**Business Logic:** Retains ALL order statuses (`delivered`, `canceled`, `unavailable`) to enable "Lost Revenue" analysis.

**Metrics:**
- `price_brl` (Gross Revenue)
- `freight_value_brl`

**Quality Flags:**
- `is_verified` (Boolean): True if rows meet strict business rules.
- `quality_issue_reason`: Descriptive error for unverified rows (e.g., "Zero Price").

---

### 4.3 Dimension Strategy (Conformed)

| Dimension        | Grain   | Type   | Key Attributes                                        |
| ---------------- | ------- | ------ | ----------------------------------------------------- |
| `dim_customers`  | Person  | Type 1 | `customer_city`, `is_repeat_buyer`                    |
| `dim_products`   | Product | Type 1 | `category_name_en` (Denormalized), `product_volume`   |
| `dim_sellers`    | Seller  | Type 1 | `seller_city`, `seller_state_code` (RLS Target)       |
| `dim_date`       | Day     | Type 0 | `is_weekend`, `quarter`, `year_month_sort`            |

**Design Decision:** All dimensions are **Type 1** (overwrite) except `dim_date` which is **Type 0** (static). No history tracking needed for this use case.

---

## 5. Security Implementation (The Bridge Pattern)

### Challenge

A **Many-to-Many** relationship exists between Managers (Users) and Regions (Data).

- One Manager oversees Many States.
- One State contains Many Sellers.

### Solution: Decoupled Security Model

**Architecture:**

1. **`dim_security_rls`**: Maps User Email (`alice@olist.com`) → Access Group.
2. **`dim_rls_bridge`**: Explodes Access Group → Permitted State Codes.

**Power BI Flow:**

```
User → dim_security_rls → dim_rls_bridge → dim_sellers → fct_order_items
```

**Why Bridge Table?**
- Prevents Cartesian explosion in the fact table.
- Centralizes security logic (add new manager = 1 row in `dim_security_rls`).
- Supports dynamic security (regional manager promoted to national = update access group, not rebuild fact).

---

## 6. Power BI Readiness & Exposures

### Lineage

Defined in `models/exposures.yml`. Links Marts to the **"Olist Executive Dashboard"** node in the dbt graph.

### Usability

All Surrogate Keys (`_sk`) and System Flags (`dbt_updated_at`) are **Hidden** in the Power BI Semantic Model to prevent user confusion.

### Performance

Model strictly enforces **One-to-Many** relationships, allowing the VertiPaq engine to maximize compression and query speed.

---

## 7. Data Governance & Testing

### 7.1 Data Contracts

**Enforcement:** `contract: {enforced: true}` enabled on all Marts.

**Benefit:** Prevents upstream schema changes (e.g., column renames) from silently breaking the Power BI dashboard.

---

### 7.2 Testing Strategy (Defense in Depth)

#### Generic Tests (Schema)

- `unique`, `not_null` on all Primary Keys (`_sk`).
- `relationships` (Referential Integrity) on all Foreign Keys.

#### Singular Tests (Business Logic)

- **`mart_fct_order_items_metric_ranges`**: Asserts `price_brl >= 0`.
- **`mart_dim_date_completeness`**: Asserts no missing dates in the 2016-2020 range.
- **`mart_rls_seller_state_coverage`**: Asserts all 27 Brazilian states are mapped in RLS.

---

## 8. Risks & Trade-offs

| Decision           | Alternative       | Reason for Choice                                                                                                                                                                                               |
| ------------------ | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Star Schema**    | One Big Table (OBT) | Security: The RLS requirement (filtering Sellers by State) requires a normalized `dim_sellers` table. OBT would require massive data duplication to support this security model.                                |
| **Surrogate Keys** | Natural Keys      | Integrity: Olist `customer_id` resets per order. Persistent SKs allow us to track Unique Customers across multiple orders.                                                                                      |
| **Meta Table**     | LocalNow() in BI  | Accuracy: Power BI functions only measure report refresh time. The Meta Table accurately measures Data refresh time, preventing "False Positives" when pipelines fail.                                          |

---

## 9. Rollout Plan

**Implementation Steps:**

1. **Core Dimensions:** Deploy `dim_customers`, `dim_products`, `dim_sellers`, `dim_date`.
2. **Security Layer:** Deploy `dim_security_rls`, `dim_rls_bridge`.
3. **Fact Table:** Deploy `fct_order_items` (Full Refresh).
4. **Observability:** Deploy `meta_project_status`.
5. **Validation:** Run `dbt test --select marts`.
6. **Documentation:** Generate Lineage Graph with Exposures.

**Rollback Strategy:**

If issues arise post-deployment, revert to previous git tag and redeploy with `dbt build --full-refresh --select marts`.

---

## 10. References

- **Kimball Methodology:** [The Data Warehouse Toolkit](https://www.kimballgroup.com/)
- **dbt Best Practices:** [dbt Discourse - Marts Layer](https://discourse.getdbt.com/)
- **Power BI RLS Patterns:** [Microsoft Docs - Row-Level Security](https://docs.microsoft.com/en-us/power-bi/admin/service-admin-rls)

---

**Last Updated:** January 2026
**Version:** 1.0
