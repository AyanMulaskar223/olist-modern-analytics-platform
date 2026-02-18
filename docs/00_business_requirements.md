# 🎯 Phase 1: Business Requirements Document (BRD)

![Project Status](https://img.shields.io/badge/Phase-1%20Complete-success?style=for-the-badge)
![Data Stack](https://img.shields.io/badge/Stack-Modern%20Data%20Stack-blue?style=for-the-badge)
![Domain](https://img.shields.io/badge/Domain-E--commerce%20Analytics-orange?style=for-the-badge)

---

## 📊 Executive Summary

Olist's fragmented analytics ecosystem prevents leadership from making fast, confident data-driven decisions. Sales, Finance, and Operations teams report conflicting revenue numbers, lack visibility into delivery bottlenecks, and spend 4+ days monthly reconciling spreadsheets.

This Modern Data Stack initiative establishes a **single source of truth** using Snowflake, dbt, and Power BI to standardize KPIs, reduce insight latency from **weekly** to **daily**, and enable self-service analytics for 4 key stakeholder groups.

**Success Criteria:**

- ✅ 100% revenue reconciliation with Finance audit trail
- ✅ <2 second dashboard load time for 95% of visuals
- ✅ Zero critical data quality failures in production
- ✅ 3-page executive app deployed with RLS regional filtering

**Timeline:** Phase 1-5 (Dec 2025 – Feb 2026) | improved decision velocity by 5x (Projected)

---

## 1️⃣ Business Context

### 1.1 Domain Overview

Olist operates a multi-seller e-commerce marketplace in Brazil, connecting small merchants ("Sellers") to major marketplaces. The platform orchestrates a complex ecosystem of **Orders, Payments, Logistics, and Reviews**, acting as the connective tissue between decentralized sellers and centralized demand.

### 1.2 The Business Problem (The "Trust Gap")

As Olist scaled, its data ecosystem fragmented into siloed operational stores. Reporting became reactive, relying on manual CSV exports and fragile ad-hoc SQL scripts.

- **Pain Point 1:** Sales, Finance, and Ops teams report different revenue numbers for the same period.
- **Pain Point 2:** No visibility into "Lost Revenue" due to logistics failures or catalog errors.
- **Pain Point 3:** Regional managers lack sub-second access to performance data, relying on stale weekly PDFs.

### 1.3 Strategic Vision

To transition from "Start-up" to "Scale-up," Olist must shift from gut-feel decision-making to precision analytics. This project establishes a **Modern Data Stack (MDS)**—utilizing Snowflake, dbt, and Power BI—to deliver a **Single Source of Truth (SSOT)**.

---

## 2️⃣ Stakeholders & User Personas

| User Persona           | Role Focus         | Key Pain Point                                                     | Decisions Enabled                                                                 |
| :--------------------- | :----------------- | :----------------------------------------------------------------- | :-------------------------------------------------------------------------------- |
| **C-Level Executives** | Strategy & Growth  | "I don't know if we are profitable on a unit-economics basis."     | Allocate capital to high-growth categories; Pivot strategy based on YoY trends.   |
| **Ops Managers**       | Logistics & SLA    | "I find out about delivery bottlenecks 3 days too late."           | Re-route orders from failing hubs; Switch logistics partners in high-fail states. |
| **Sales Managers**     | Seller Performance | "I can't identify which sellers are hurting our brand reputation." | Offboard high-risk sellers; Create "Gold Tier" rewards for top performers.        |
| **Finance Team**       | Revenue Audit      | "I spend 4 days a month reconciling spreadsheets."                 | Close books faster with "Verified Revenue" vs. "Revenue at Risk" visibility.      |

---

## 3️⃣ Objectives & Success Criteria

### Primary Objectives

1. **Metric Standardization:** Enforce strict, code-based definitions for "Realized Revenue" and "Delivery Delay" to eliminate metric drift.
2. **Latency Reduction:** Reduce "Time-to-Insight" from **Weekly** (Manual) to **Daily** (Automated T-1 Refresh).
3. **Self-Service:** Empower non-technical managers to slice data by Region/Category without SQL requests.

### Success Metrics (Definition of Done)

![Quality Badge](https://img.shields.io/badge/Data%20Quality-100%25%20Target-brightgreen)
![Performance Badge](https://img.shields.io/badge/Query%20Time-%3C2s-blue)
![Trust Badge](https://img.shields.io/badge/Reconciliation-100%25-success)

- **Trust:** 100% numerical reconciliation between Finance "Gold Numbers" and Dashboard Revenue.
  - 📸 _Validation:_ [UAT Revenue Reconciliation](screenshots/04_powerbi/uat_revenue_reconciliation.png)
- **Performance:** Dashboard report pages load in **< 2 seconds** for 95% of queries.
  - 📸 _Validation:_ [Performance Analyzer Results](screenshots/04_powerbi/performance_analyzer_excutive_page.png)
- **Data Quality:** Zero critical failures (Duplicates, Null Primary Keys) allowed in the Production pipeline.
  - 📸 _Validation:_ [dbt Test Suite (100% Pass Rate)](screenshots/03_dbt/test_passed_suite.png)

---

## 4️⃣ Key Business Questions (KBQs)

The dashboard is designed to answer these specific strategic questions:

| ID     | Business Question                                | Analytics Type | Value Add                                                      |
| :----- | :----------------------------------------------- | :------------- | :------------------------------------------------------------- |
| **Q1** | How are revenue and orders trending MoM/YoY?     | Descriptive    | Identifying growth stagnation early to adjust marketing spend. |
| **Q2** | Which product categories drive the most margin?  | Descriptive    | Prioritizing inventory and seller onboarding efforts.          |
| **Q3** | Where is the demand concentrated geographically? | Descriptive    | Optimizing logistics hub locations and shipping routes.        |
| **Q4** | How efficient is our delivery network?           | Diagnostic     | Pinpointing failing carrier routes (e.g., "SP to RJ").         |
| **Q5** | Who are our "Whale" sellers vs. "Churn" risks?   | Descriptive    | Focused account management for top 1% of sellers.              |
| **Q6** | Are we retaining customers (Loyalty)?            | Descriptive    | Shifting strategy from "Acquisition" to "Retention" (LTV).     |

---

## 5️⃣ KPI Definitions & Logic

| KPI                       | Business Definition                       | Technical Logic / Calculation                                                        |
| :------------------------ | :---------------------------------------- | :----------------------------------------------------------------------------------- |
| **Total Revenue**         | Gross value of delivered items.           | `SUM(price)` where `order_status = 'delivered'`                                      |
| **Total Orders**          | Count of distinct valid orders.           | `COUNT(DISTINCT order_id)` where `order_status <> 'canceled'`                        |
| **Avg Order Value (AOV)** | Average spend per order.                  | `Total Revenue` ÷ `Total Orders`                                                     |
| **Delivery Delay Rate %** | % of orders arriving late.                | `COUNT(late_orders)` ÷ `COUNT(delivered_orders)` where `delivered_at > estimated_at` |
| **On-Time Delivery %**    | % of orders arriving on/before promise.   | `1 - Delay Rate %`                                                                   |
| **Revenue at Risk**       | Value of orders with data quality issues. | `SUM(price)` where `is_verified = False`                                             |

---

## 6️⃣ Business Rules & Data Logic

These rules govern how raw data is translated into business insights:

### 📋 Core Business Rules

| Rule                    | Definition                                                                                                                                                       | Enforcement Location      |
| :---------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------ |
| **Revenue Recognition** | Revenue is strictly recognized only when `order_status = 'delivered'`. Shipped or Invoiced orders are tracked for Operations but excluded from Financial totals. | `stg_orders.sql`          |
| **Efficiency Rule**     | A delivery is flagged "Late" strictly if `order_delivered_customer_date > order_estimated_delivery_date`. Weekends/Holidays are included (Customer View).        | `int_orders_enriched.sql` |
| **Identity Rule**       | A "Customer" is defined by `customer_unique_id` (The Human), NOT `customer_id` (The Transaction).                                                                | `dim_customers.sql`       |
| **Verification Rule**   | We apply a **"Trust, Don't Trash"** philosophy. Records with quality issues are **Flagged** (`is_verified = False`) rather than deleted.                         | All STAGING layer models  |

**📸 Implementation Evidence:**

- [Data Contracts in dbt](screenshots/03_dbt/data_contracts.png) - Business rules codified as tests
- [Trust Indicators in Power BI](screenshots/04_powerbi/trust_tooltip_ux.png) - User-facing verification flags

---

## 7️⃣ Data Scope & Granularity

### Analytical Grain

```
📊 Fact Grain: One row per Order Line Item
```

**Justification:** Analysis requires slicing by Product Category and Seller Location. A grain of "Order Header" would obscure multi-category orders.

### Assumptions & Limitations

| Constraint           | Value                                    |
| :------------------- | :--------------------------------------- |
| **Historical Range** | Sep 2016 – Oct 2018 (Dataset Limitation) |
| **Currency**         | BRL (Brazilian Real)                     |
| **Timezone**         | UTC (Pipeline) / UTC-3 (Reporting)       |

---

## 8️⃣ Non-Functional Requirements (NFRs)

### 8.1 Data Quality & Trust

![Data Quality](https://img.shields.io/badge/Quality%20Threshold-95%25%20Pass%20Rate-critical)

- **Constraint:** The pipeline must halt if >5% of daily volume fails validation.
- **Visibility:** All "Raw" vs. "Verified" data discrepancies must be visible in a dedicated "Data Audit" page.

**📸 Implementation Screenshots:**

- [Data Quality Audit Dashboard](screenshots/04_powerbi/data_quality_audit.png) - Anomaly visibility
- [dbt Test Results](screenshots/03_dbt/test_passed_suite.png) - Automated validation pipeline

### 8.2 Security & Access (RLS)

![Security](https://img.shields.io/badge/Security-RLS%20Enabled-red)

- **Regional Restriction:** Managers must only see data for their specific States (e.g., "SP Manager" sees only `customer_state = 'SP'`).
- **Implementation:** Dynamic RLS via Bridge Table (`User Email` → `Access Key` → `State Code`).

**📸 Implementation Screenshots:**

- [Snowflake RBAC Configuration](screenshots/02_snowflake/RBAC.png) - Role-based access control
- [Power BI RLS Validation](screenshots/04_powerbi/uat_rls_validation.png) - Regional data filtering test

### 8.3 Performance

![Performance](https://img.shields.io/badge/SLA-Daily%20Refresh%20by%2005%3A00-blue)

- **Refresh:** Data must be refreshed daily by 05:00 AM local time.
- **Interactivity:** Visuals must render in < 2 seconds.

**📸 Implementation Screenshots:**

- [Incremental Refresh Strategy](screenshots/04_powerbi/incremental_refresh.png) - Optimized data refresh
- [Query Folding Evidence](screenshots/04_powerbi/query_folding.png) - Native query pushdown to Snowflake

---

## 🔟 Out of Scope (Phase 1)

| Feature                    | Status          |
| :------------------------- | :-------------- | --- |
| **Sentiment Analysis**     | ⏸️ Deferred     |
| **Predictive Forecasting** | ⏸️ Deferred     |
| **Real-Time Streaming**    | ❌ Not Required |     |

---

## 1️⃣1️⃣ Deliverables Checklist

### ✅ Phase 1 Deliverables

- [x] **Semantic Model:** Certified Power BI Dataset (`.pbip`) with Star Schema architecture.
  - 📸 [Semantic Model Diagram](screenshots/04_powerbi/semantic_model.png)
  - 📸 [Data Lineage View](screenshots/04_powerbi/lineage_graph_view.png)
- [x] **Executive App:** 3-Page Dashboard (Overview, Logistics Deep Dive, Data Audit).
  - 📸 [Executive Overview](screenshots/04_powerbi/org_app_view.png)
  - 📸 [Supply Chain Analysis](screenshots/04_powerbi/supply_chain_analysis.png)
  - 📸 [Data Quality Audit](screenshots/04_powerbi/data_quality_audit.png)
- [x] **Documentation:**
  - [Architecture Diagram](01_architecture.md)
  - [Data Dictionary](02_data_dictionary.md)
  - 📸 [dbt Documentation Site](screenshots/03_dbt/dbt_docs_site.png)

---
