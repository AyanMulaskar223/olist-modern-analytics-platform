# Phase 2 Data Quality Validation Report

**Project:** Olist Modern Analytics Platform
**Author:** Ayan Mulaskar
**Date:** December 28, 2025
**Status:** PASSED

---

## Executive Summary

Phase 2 data ingestion is complete. We successfully loaded 8 tables totaling 1.55M rows from Azure Blob Storage into Snowflake's RAW layer. The validation process identified no critical data quality issues that would block progression to Phase 3.

**Key Findings:**

- Quality Score: 100% on critical checks
- All tables loaded without failures
- 12 records flagged for review (0.0008% of total data)
- Referential integrity verified across all table relationships
- Data loaded within the last hour, meeting freshness requirements

**Recommendation:** The data is ready for Phase 3 transformations. Minor data characteristics flagged below will be addressed in the dbt staging layer.

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

## Validation Methodology

The validation script (`02_snowflake/03_quality_checks/05_raw_data_quality_checks.sql`) ran in approximately 30 seconds and performed the following checks:

- Primary and foreign key completeness and uniqueness
- Referential integrity across 4 table relationships
- Date logic validation (future timestamps, event sequences)
- Text formatting issues (whitespace, inconsistent casing)
- Business rule validation (negative amounts, valid categories)
- Statistical outlier detection using IQR method
- Data freshness verification (24-hour SLA)

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

- Promotional campaigns or voucher redemptions
- Return/refund transactions processed through the payment system
- Loyalty points or gift card payments
- Potential data entry errors

These records will be flagged with an `is_zero_payment` indicator in the staging layer. Further investigation with business stakeholders will determine if these represent legitimate business scenarios.

**2. Undefined Payment Types**

Count: 3 records (0.003% of 103,886 total payments)

Three payment records contain the value 'not_defined' where we expect one of four valid payment types: credit_card, boleto, voucher, or debit_card. This suggests missing or incomplete data from the source system.

In Phase 3, these records will be mapped to 'unknown' in the staging layer. A dbt test will be added to validate that all future payment types match the expected list of accepted values.
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

| Table  | Column       | Unique Values                                                                      | Status   |
| ------ | ------------ | ---------------------------------------------------------------------------------- | -------- |
| orders | order_status | delivered, shipped, processing, canceled, unavailable, invoiced, created, approved | Expected |

### Expected Data Characteristics

Several data patterns were identified that, while they may appear as anomalies, actually represent normal business characteristics. These do not require remediation.

### Mixed Case State Codes

The customer_state column contains 27 unique values with inconsistent casing (e.g., "SP", "Sp", "sp"). This count is correct—Brazil has 26 states plus one federal district (DF). The mixed casing is typical of raw operational data and will be standardized to uppercase in the staging layer.

### Order Status Variety

Eight distinct order statuses are present in the data: delivered, shipped, processing, canceled, unavailable, invoiced, created, and approved. This reflects the actual order lifecycle in the e-commerce system. The staging layer will add derived flags for analytical purposes (such as is_completed and is_active).

### High-Value Transactions

Using the IQR method, 7,981 payment transactions (7.7% of total payments) were flagged as statistical outliers. This is expected for e-commerce data, where high-value purchases of electronics, furniture, or bulk orders create a long-tail distribution. These records represent legitimate transactions and will be retained but flagged for analytical segmentation.

```

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

## References

### Related Documentation

- Business Requirements (00_business_requirements.md)
- Architecture Overview (01_architecture.md)
- Azure Storage Setup (02_azure_storage_setup.md)
- Data Dictionary (03_data_dictionary.md)
- ADLC Framework (06_adlc_framework.md)
- Snowflake Implementation (../02_snowflake/README.md)

### Quality Check Scripts

Primary validation: `02_snowflake/03_quality_checks/05_raw_data_quality_checks.sql`
Extended validation: `context/05_raw_data_quality_checks_EXTENDED.sql`

### Snowflake Objects

- Database: OLIST_RAW_DB
- Schema: OLIST_RAW_DB.OLIST
- Warehouse: LOADING_WH_XS
- Stage: OLIST_RAW_DB.LANDING.AZURE_STAGE

---

## Appendix: Validation Queries

The following queries can be run to validate data quality after any future loads:

**Health Check:**

```sql
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS unique_orders,
       SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_pks
FROM OLIST_RAW_DB.OLIST.raw_orders;
```

**Zero Payment Investigation:**

```sql
SELECT op.order_id, op.payment_type, o.order_status
FROM OLIST_RAW_DB.OLIST.raw_order_payments op
JOIN OLIST_RAW_DB.OLIST.raw_orders o ON op.order_id = o.order_id
WHERE op.payment_value = 0;
```

---

## Phase 3 Remediation Plan

The following actions will be taken in Phase 3 to address the identified data characteristics:

**Data Standardization:**

- Uppercase all state codes: `UPPER(TRIM(customer_state))`
- Lowercase all order statuses: `LOWER(TRIM(order_status))`
- Map 'not_defined' payment types to 'unknown'

**Business Logic Additions:**

- Create `is_zero_payment` flag for analytical purposes
- Implement order value categorization (low/medium/high/premium)
- Flag statistical outliers for segmentation

**dbt Tests:**

- Add `unique` and `not_null` tests on all primary and foreign keys
- Implement `relationships` tests for referential integrity
- Create `accepted_values` tests for order_status and payment_type

---

## Next Steps

Phase 3 development will proceed with the following tasks:

1. Load product category translation seed file
2. Build staging models with data cleaning logic
3. Implement comprehensive dbt tests
4. Create intermediate models with business logic
5. Design star schema marts for Power BI consumption

---

**Report Status:** Final
