# Phase 2: Data Quality Validation Report

**Project:** Olist Modern Analytics Platform  
**Author:** Ayan Mulaskar  
**Date:** December 28, 2025  
**Status:** PASSED - Ready for Phase 3

---

## Executive Summary

Phase 2 data ingestion completed successfully. All 8 tables loaded from Azure Blob Storage into Snowflake RAW layer with 1.55M total rows. No critical issues detected.

**Key Findings:**

- Quality Score: 100% (0 critical issues)
- Load Success Rate: 100%
- Minor issues: 12 records across 2 categories (0.0008% of data)
- All referential integrity checks passed
- Data freshness: < 1 hour

**Recommendation:** Approved for Phase 3. Minor issues documented below for dbt staging layer.

---

## Data Ingestion Summary

| Table              | Rows          | Format  | Source Path        |
| ------------------ | ------------- | ------- | ------------------ |
| raw_customers      | 99,441        | CSV     | customers/\*.csv   |
| raw_orders         | 99,441        | CSV     | order/\*.csv       |
| raw_order_items    | 112,650       | Parquet | items/\*.parquet   |
| raw_order_payments | 103,886       | CSV     | payments/\*.csv    |
| raw_products       | 32,951        | CSV     | products/\*.csv    |
| raw_sellers        | 3,095         | CSV     | sellers/\*.csv     |
| raw_geolocation    | 1,000,163     | CSV     | geolocation/\*.csv |
| raw_order_reviews  | 99,224        | JSON    | reviews/\*.json    |
| **TOTAL**          | **1,550,688** | —       | —                  |

All tables include audit columns: `_source_file`, `_loaded_at`, `_file_row_number`

---

## 🔍 Validation Methodology

### Quality Check Framework

Data quality validation was performed using the script:

- **Location:** `02_snowflake/03_quality_checks/05_raw_data_quality_checks.sql`
- **Execution Time:** ~30 seconds
- \*Validation Methodology

Validation script: `02_snowflake/03_quality_checks/05_raw_data_quality_checks.sql` (execution time: ~30s)

**Checks performed:**

- Primary/foreign key completeness and uniqueness
- Referential integrity (4 relationships validated)
- Date logic (no future timestamps, valid sequences)
- Data format (whitespace, case consistency)
- Business rules (no negative amounts, categorical validation)
- Statistical outliers (IQR method)
- Load freshness (< 24 hour SLA)
  **Requirement:** All primary keys must be populated (NOT NULL)

| Table           | Primary Key Column | NULL Count | Status  |
| --------------- | ------------------ | ---------- | ------- |
| `raw_customers` | `customer_id`      | 0          | ✅ PASS |
| `raw_orders`    | `order_id`         | 0          | ✅ PASS |
| `raw_products`  | `product_id`       | 0          | ✅ PASS |
| `raw_sellers`   | `seller_id`        | 0          | ✅ PASS |

**Result:** ✅ No NULL primary keys detected across all tables.

---
## Validation Results

### Critical Checks - All Passed

**Primary Keys:** No NULLs or duplicates in customer_id, order_id, product_id, seller_id  
**Foreign Keys:** No NULLs in customer_id, order_id, product_id references  
**Business Fields:** No NULLs in order_status, order_purchase_timestamp, payment_value  
**Referential Integrity:** 0 orphaned records across all 4 relationships  
**Date Logic:** No future timestamps, all sequences valid (purchase → approval → delivery)  
**Data Format:** No whitespace issues, no negative amounts

Result: 100% quality score on all critical check
Zero-value payments may represent:

1. Free orders (promotional campaigns, vouchers)
2. Returns/refunds processed through payment system
3. Gift cards or loyalty points redemption
4. Data entry errors

**Recommendation:**

- ✅ **NOT a blocker** – valid business scenario possible
- Phase 3 Action: Create `stg_order_payments` with flag `is_zero_payment`
- Business validation: Cross-reference with order status and payment type
- Document legitimate zero-payment use cases with business stakeholders

**SQL for Investigation (Phase 3):**

```sql
-- Identify zero-payment characteristics
SELECT
    op.payment_type,
    o.order_status,
    COUNT(*) AS zero_payment_count
FROM raw_order_payments op
JOIN raw_orders o ON op.order_id = o.order_id
WHERE op.payment_value = 0
GROUP BY op.payment_type, o.order_status;
```

---

### Issue 2: Invalid Payment Type Categories

**Severity:** 🟡 Medium  
**Impact:** Low (0.003% of payments)

| Table                | Column         | Invalid Value | Count | Total Rows | Percentage |
| -------------------- | -------------- | ------------- | ----- | ---------- | ---------- |
| `raw_order_payments` | `payment_type` | `not_defined` | 3     | 103,886    | 0.003%     |

**Expected Values:**

- `credit_card`
- `boleto` (Brazilian payment method)
- `voucher`
- `debit_card`

**Analysis:**
"not_defined" indicates missing or unmapped payment type in source system.

**Recommendation:**

- ✅ **NOT a blocker** – very low occurrence
- Phase 3 Action: In `stg_order_payments`, map `not_defined` to:
  - `'unknown'` (if retaining as separate category)
  - OR investigate source data and manually map if pattern exists
- Add dbt test: `accepted_values` for `payment_type`

**Proposed dbt Transformation:**

```sql
-- stg_order_payments.sql
CASE
    WHEN payment_type = 'not_defined' THEN 'unknown'
    ELSE payment_type
END AS payment_type_clean
```

---

## ℹ️ Data Characteristics (Expected Behavior)

### 1. Mixed Case in State Codes

**Observation:** 27 unique values in `customer_state` column

| Table           | Column           | Unique Values | Status      |
| --------------- | ---------------- | ------------- | ----------- |
| `raw_customers` | `customer_state` | 27            | ✅ Expected |

**Analysis:**

- Brazil has 26 states + 1 federal district (DF) = **27 total** ✅
- Mixed case (e.g., "SP", "Sp", "sp") is expected in raw data
- Will be standardized in Phase 3 using `UPPER()` transformation

**Phase 3 Action:**

```sql
-- stg_customers.sql
UPPER(TRIM(customer_state)) AS customer_state_clean
```

---

### 2. Order Status Variety

**Observation:** 8 unique order statuses

| Table        | Column         | Unique Values | Status      |
| ------------ | -------------- | ------------- | ----------- |
| `raw_orders` | `order_status` | 8             | ✅ Expected |

**Expected Statuses:**

- `delivered`
- `shipped`
- `processing`
- `canceled`
- `unavailable`
- `invoiced`
- `created`
- `approved`

**Analysis:**
Business process allows 8 distinct order states – this is expected e-commerce behavior.

**Phase 3 Action:**

- Add dbt test: `accepted_values` for `order_status`
- Create derived column: `is_completed` (delivered/canceled)
- Create derived column: `is_active` (processing/shipped/approved)

---

### 3. Payment Outliers (High-Value Orders)

**Observation:** 7,981 outliers detected using IQR method

| Table                | Column          | Outlier Count | Total Rows | Percentage |
| -------------------- | --------------- | ------------- | ---------- | ---------- |
| `raw_order_payments` | `payment_value` | 7,981         | 103,886    | 7.7%       |

**Statistical Profile:**

- DIssues Identified

### Minor Issues (Non-Blocking)

**1. Zero-Value Payments**

- Count: 9 records (0.009% of 103,886 payments)
- Likely causes: Vouchers, promotional orders, refunds, loyalty points
- Phase 3 action: Add `is_zero_payment` flag in staging, validate with order_status

**2. Invalid Payment Types**

- Count: 3 records with `payment_type = 'not_defined'` (0.003%)
- Phase 3 action: Map to 'unknown' in staging, add dbt test for accepted_values

### Expected Data Characteristics

**Mixed Case States:** 27 unique values (26 Brazilian states + DF). Will standardize to uppercase in staging.

**Order Statuses:** 8 values (delivered, shipped, processing, canceled, unavailable, invoiced, created, approved). Valid business states.

**Payment Outliers:** 7,981 high-value transactions (7.7% of payments). Normal for e-commerce - electronics, furniture, bulk orders. Will flag but not remove. Source to Target Mapping

| Source (Azure Blob) | Target (Snowflake RAW) | Load Method         | Validation  |
| ------------------- | ---------------------- | ------------------- | ----------- |
| `customers/*.csv`   | `raw_customers`        | COPY INTO (CSV)     | ✅ Verified |
| `order/*.csv`       | `raw_orders`           | COPY INTO (CSV)     | ✅ Verified |
| `items/*.parquet`   | `raw_order_items`      | COPY INTO (Parquet) | ✅ Verified |
| `payments/*.csv`    | `raw_order_payments`   | COPY INTO (CSV)     | ✅ Verified |
| `products/*.csv`    | `raw_products`         | COPY INTO (CSV)     | ✅ Verified |
| `sellers/*.csv`     | `raw_sellers`          | COPY INTO (CSV)     | ✅ Verified |
| `geolocation/*.csv` | `raw_geolocation`      | COPY INTO (CSV)     | ✅ Verified |
| `reviews/*.json`    | `raw_order_reviews`    | COPY INTO (JSON)    | ✅ Verified |

### Audit Trail Verification

✅ All tables include:

- `_source_file` → Full Azure blob path
- `_loaded_at` → Load timestamp (UTC)
- `_file_row_number` → Source file row number

**Validation Query:**

```sql
SELECT
    _source_file,
    MIN(_loaded_at) AS first_load,
    MAX(_loaded_at) AS last_load,
    COUNT(*) AS row_count
FROM OLIST_RAW_DB.OLIST.raw_orders
GROUP BY _source_file;
```

---

## 💰 Cost & Performance Metrics

### Ingestion Performance

| Metric                   | Value                      |
| ------------------------ | -------------------------- |
| **Total Rows Loaded**    | 1,550,688                  |
| **Total Data Size**      | ~850 MB (compressed)       |
| **Warehouse Used**       | LOADING_WH_XS (X-SMALL)    |
| **Total Execution Time** | ~8 minutes                 |
| **Credits Consumed**     | ~0.13 credits (~$0.03 USD) |
| **Average Load Rate**    | ~193,836 rows/minute       |

### Quality Check Performance

| Metric                 | Value                        |
| ---------------------- | ---------------------------- |
| **Validation Queries** | 24 checks                    |
| **Execution Time**     | ~30 seconds                  |
| **Warehouse Used**     | LOADING_WH_XS                |
| **Credits Consumed**   | ~0.008 credits (~$0.002 USD) |

**Total Phase 2 Cost:** **~$0.032 USD** ✅ (Well under budget)

---

## 🎯 Sign-Off & Approval

### Phase 2 Completion Checklist

- [x] **Infrastructure deployed** (warehouses, databases, schemas)
- [x] **RBAC configured** (4 functional roles assigned)
- [x] **Azure Storage Integration established** (external stage validated)
- [x] **8 raw tables created** with audit columns
- [x] **1,550,688 rows loaded** successfully from Azure Blob
- [x] **100% quality score achieved** (0 critical issues)
- [x] **Data freshness validated** (< 24 hours)
- [x] **Cost controls active** (resource monitors, auto-suspend)
- [x] **Minor issues documented** for Phase 3 remediation
- [x] **Data lineage established** (source to target mapping)

### Approval Status

| Role                     | Name          | Decision    | Date       | Signature |
| ------------------------ | ------------- | ----------- | ---------- | --------- |
| **Analytics Engineer**   | Ayan Mulaskar | ✅ Approved | 2025-12-28 | AM        |
| **Data Lead**            | [Pending]     | 🔄 Review   | —          | —         |
| **Business Stakeholder** | [Pending]     | 🔄 Review   | —          | —         |

### Approval Comments

**Ayan Mulaskar (Analytics Engineer):**

> Phase 2 data ingestion completed successfully with excellent data quality (100% score). All critical integrity checks passed. Minor issues (12 records, 0.0008% of data) are well-documented and will be addressed in Phase 3 dbt transformations. Ready to proceed with staging layer development.

---

## 📚 References

### Related Documentation

- [Business Requirements](./00_business_requirements.md) – KPIs and business rules
- [Architecture Overview](./01_architecture.md) – System design
- [Azure Storage Setup](./02_azure_storage_setup.md) – Source configuration
- [Data Dictionary](./02_data_dictionary.md) – Column definitions
- [ADLC Framework](./05_adlc_framework.md) – Development lifecycle
- [Snowflake README](../02_snowflake/README.md) – Phase 2 implementation details

### Quality Check Scripts

- **Primary:** `02_snowflake/03_quality_checks/05_raw_data_quality_checks.sql`
- **Extended:** `context/05_raw_data_quality_checks_EXTENDED.sql` (100% column coverage)

### Snowflake Objects

- **Database:** `OLIST_RAW_DB`
- **Schema:** `OLIST_RAW_DB.OLIST`
- **Warehouse:** `LOADING_WH_XS`
- **Stage:** `OLIST_RAW_DB.LANDING.AZURE_STAGE`

---

## 📝 Appendix: Validation Queries

### Quick Health Check (Run Anytime)

```sql
-- Overall quality summary
SELECT
    'raw_orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_pks,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_pks,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_fks,
    ROUND((1 - (SUM(CASE WHEN order_id IS NULL OR customer_id IS NULL THEN 1 ELSE 0 END) / COUNT(*))) * 100, 2) AS quality_score_pct
FROM OLIST_RAW_DB.OLIST.raw_orders;
```

### Data Freshness Check

````sql
-- Quality Score

**Calculation:** `(1 - Critical Issues / Total Rows) × 100`

Critical issues = NULL keys + duplicates + orphaned records + invalid dates

Result: **100%** (0 critical issues across 1.55M rows)

Note: Zero payments and invalid payment types classified as data characteristics, not critical issues.Phase 3 Remediation Plan

**Data Cleaning:**
- Standardize state codes to uppercase: `UPPER(TRIM(customer_state))`
- Standardize order statuses to lowercase: `LOWER(TRIM(order_status))`
- Map 'not_defined' payment types to 'unknown'

**Business Logic:**
- Add `is_zero_payment` flag
- Create order value categories (low/medium/high/premium)
- Flag high-value outliers for analysis

**dbt Tests:**
- `unique` and `not_null` on all keys
- `relationships` for foreign keys
- `accepted_values` for order_status and payment_type

---

## Cost & Performance

| Metric | Value |
|--------|-------|
| Rows loaded | 1,550,688 |
| Data size | ~850 MB compressed |
| Execution time | ~8 minutes |
| Credits used | 0.13 (~$0.03) |
| Quality checks | 30 seconds, 0.008 credits |
| **Total cost** | **~$0.03** |Appendix

### Quick Validation Queries

**Health check:**
```sql
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS unique_orders,
       SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_pks
FROM OLIST_RAW_DB.OLIST.raw_orders;
````

**Investigate zero payments:**

```sql
SELECT op.order_id, op.payment_type, o.order_status
FROM OLIST_RAW_DB.OLIST.raw_order_payments op
JOIN OLIST_RAW_DB.OLIST.raw_orders o ON op.order_id = o.order_id
WHERE op.payment_value = 0;
```

### References

- Quality check script: `02_snowflake/03_quality_checks/05_raw_data_quality_checks.sql`
- Extended validation: `context/05_raw_data_quality_checks_EXTENDED.sql`
- Implementation details: `02_snowflake/README.md`

---

## Next Steps

1. Load dbt seeds: `dbt seed`
2. Create staging models with data cleaning
3. Implement dbt tests (not_null, unique, relationships, accepted_values)
4. Build intermediate layer with business logic
5. Create star schema marts for Power BI

---

**Status:** Phase 2 Complete - Approved for Phase 3  
**Author:** Ayan Mulaskar  
**Version:** 1.0
