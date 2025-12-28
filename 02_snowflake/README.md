# 02_snowflake/ – Phase 2: Data Acquisition & Raw Layer Setup

## 📋 Overview

This folder contains all SQL scripts required to implement **Phase 2: Data Acquisition & Source Integration** for the Olist Modern Analytics Platform.

**Purpose:**

- Establish Snowflake infrastructure (warehouses, databases, schemas)
- Implement RBAC security model with least-privilege access
- Configure Azure Blob Storage integration
- Load raw data from Azure into Snowflake RAW layer
- Validate data quality and integrity

**Key Principle:** Raw layer = **exact source truth** (no business transformations)

---

## 🏗️ Architecture

```
Azure Blob Storage → Snowflake RAW Layer → dbt (Phase 3) → Power BI (Phase 4)
(Phase 2)
```

### Infrastructure Stack

- **Cloud Platform:** Azure Blob Storage (stolistanalyticsdev.blob.core.windows.net)
- **Data Warehouse:** Snowflake Enterprise Edition
- **Integration Method:** External Stage with Azure Storage Integration
- **File Formats:** CSV, JSON, Parquet
- **Cost Controls:** X-SMALL warehouses, 60s auto-suspend, 100 credit/month limit

---

## 📁 Folder Structure

```
02_snowflake/
├── README.md                          ← You are here
├── 01_setup/
│   ├── 01_infrastructure.sql          ← Warehouses, databases, schemas, resource monitors
│   └── 02_rbac_security.sql           ← Roles, grants, user assignments
├── 02_ingestion/
│   ├── 03_external_stages.sql         ← Storage integration, file formats, external stage
│   └── 04_copy_into_raw.sql           ← Raw tables creation + COPY INTO commands
└── 03_quality_checks/
    └── 05_raw_data_quality_checks.sql ← Data validation queries (NULL, duplicates, integrity)
```

---

## ⚙️ Execution Order

### Prerequisites

1. Snowflake account with ACCOUNTADMIN role
2. Azure Blob Storage account with data files
3. Azure Tenant ID for OAuth integration
4. SnowSQL CLI or Snowflake Web UI

### Step-by-Step Execution

#### **Step 1: Infrastructure Setup**

```bash
# Run as ACCOUNTADMIN
snowsql -f 01_setup/01_infrastructure.sql
```

**What it does:**

- Creates resource monitor: `OLIST_MONTHLY_LIMIT` (100 credits)
- Creates warehouses: `LOADING_WH_XS`, `TRANSFORM_WH_XS`, `REPORTING_WH_XS`
- Creates databases: `OLIST_RAW_DB`, `OLIST_ANALYTICS_DB`, `OLIST_DEV_DB`
- Creates schemas: `LANDING` (staging files), `OLIST` (raw tables)
- Applies cost control tags

**Validation:**

```sql
SHOW WAREHOUSES LIKE '%OLIST%';
SHOW DATABASES LIKE '%OLIST%';
SHOW RESOURCE MONITORS;
```

---

#### **Step 2: RBAC Security**

```bash
snowsql -f 01_setup/02_rbac_security.sql
```

**What it does:**

- Creates 4 functional roles:
  - `LOADER_ROLE` → Data ingestion (Phase 2)
  - `ANALYTICS_ROLE` → dbt transformations (Phase 3)
  - `REPORTER_ROLE` → Power BI consumption (Phase 4)
  - `CI_SERVICE_ROLE` → Automation (GitHub Actions)
- Grants least-privilege access per role
- Assigns user `AYAN` to all roles

**Validation:**

```sql
SHOW GRANTS TO ROLE LOADER_ROLE;
SHOW GRANTS TO USER AYAN;
```

---

#### **Step 3: External Stage Setup**

```bash
# Run as LOADER_ROLE
USE ROLE LOADER_ROLE;
snowsql -f 02_ingestion/03_external_stages.sql
```

**What it does:**

- Creates Azure Storage Integration: `azure_olist_int`
- Defines file formats:
  - `CSV_GENERIC_FMT` (UTF-8, skip header, error handling)
  - `JSON_GENERIC_FMT` (strip outer array)
  - `PARQUET_GENERIC_FMT`
- Creates external stage: `AZURE_STAGE` pointing to Azure Blob

**Critical Step:** After running, execute:

```sql
DESC STORAGE INTEGRATION azure_olist_int;
```

Copy the `AZURE_CONSENT_URL` and complete OAuth consent in Azure Portal.

**Validation:**

```sql
LIST @OLIST_RAW_DB.LANDING.AZURE_STAGE;
-- Should return list of files from Azure
```

---

#### **Step 4: Data Ingestion**

```bash
# Run as LOADER_ROLE
USE ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH_XS;
snowsql -f 02_ingestion/04_copy_into_raw.sql
```

**What it does:**

- Creates 8 raw TRANSIENT tables with audit columns:
  - `raw_customers`
  - `raw_orders`
  - `raw_order_items` (Parquet)
  - `raw_order_payments`
  - `raw_products`
  - `raw_sellers`
  - `raw_geolocation`
  - `raw_order_reviews` (JSON)
- Loads data using `COPY INTO` with pattern matching
- Adds audit columns: `_source_file`, `_loaded_at`, `_file_row_number`
- Runs inline validation queries (NULL checks, duplicates, referential integrity)

**Expected Results:**

```
raw_customers:       ~99,441 rows
raw_orders:          ~99,441 rows
raw_order_items:     ~112,650 rows
raw_order_payments:  ~103,886 rows
raw_products:        ~32,951 rows
raw_sellers:         ~3,095 rows
raw_geolocation:     ~1,000,000 rows
raw_order_reviews:   ~99,224 rows
```

**Validation:**

```sql
-- Check load history
SELECT * FROM INFORMATION_SCHEMA.LOAD_HISTORY
WHERE SCHEMA_NAME = 'OLIST'
ORDER BY LAST_LOAD_TIME DESC;

-- Verify row counts
SELECT 'raw_customers' AS table_name, COUNT(*) AS row_count FROM OLIST_RAW_DB.OLIST.raw_customers
UNION ALL
SELECT 'raw_orders', COUNT(*) FROM OLIST_RAW_DB.OLIST.raw_orders;
-- ... repeat for all tables
```

---

#### **Step 5: Data Quality Validation**

```bash
# Run as LOADER_ROLE
snowsql -f 03_quality_checks/05_raw_data_quality_checks.sql
```

**What it does:**

- Validates NULL primary/foreign keys (should be 0)
- Checks for duplicate keys (should be 0)
- Detects future timestamps (should be 0)
- Validates date sequences (order date < delivery date)
- Identifies whitespace/case issues
- Flags negative values in amounts
- Detects outliers using IQR method
- Validates referential integrity (orphaned records)
- Checks data freshness (< 24 hours)

**Success Criteria:**

- ✅ NULL_PRIMARY_KEYS = 0
- ✅ DUPLICATE_PRIMARY_KEYS = 0
- ✅ ORPHANED_RECORDS = 0
- ✅ QUALITY_SCORE = 100%

**Known Expected Issues:**

- 9 zero-value payments (legitimate free orders/vouchers)
- 3 "not_defined" payment types (to be mapped in Phase 3)
- 7,981 payment outliers (expected for e-commerce high-value orders)

---

## 🔑 Key Technical Decisions

### 1. **TRANSIENT Tables for RAW Layer**

**Rationale:** Raw data can be reloaded from Azure if lost; reduces storage costs by disabling Fail-safe.

### 2. **Positional Column Mapping (Not MATCH_BY_COLUMN_NAME)**

**Rationale:** Required to add audit columns during COPY INTO (transformations incompatible with MATCH_BY_COLUMN_NAME).

### 3. **Case-Insensitive Pattern Matching `(?i)`**

**Rationale:** Handles varied file naming conventions from Azure (e.g., `customers_dataset` vs `CUSTOMERS_DATASET`).

### 4. **Parquet for Order Items**

**Rationale:** Large fact table benefits from columnar format compression and performance.

### 5. **JSON for Order Reviews**

**Rationale:** Semi-structured reviews with variable fields; JSON preserves flexibility for NLP analysis in Phase 3.

### 6. **Three Audit Columns (Not Four)**

- `_source_file` → Traceability
- `_loaded_at` → Temporal tracking
- `_file_row_number` → Duplicate detection
- ❌ `_load_batch_id` → Removed for simplicity (COPY provides load tracking)

---

## 💰 Cost Controls (DataFinOps)

### Resource Monitor

```sql
OLIST_MONTHLY_LIMIT:
- Quota: 100 credits/month
- Notify at: 75%, 90%, 100%
- Action: SUSPEND at 100%
```

### Warehouse Sizing

```sql
LOADING_WH_XS:
- Size: X-SMALL (1 credit/hour)
- Auto-suspend: 60 seconds
- Auto-resume: TRUE
- Estimated cost: ~$2/hour (on-demand)
```

### Storage Optimization

- RAW tables: TRANSIENT (Time Travel = 1 day, Fail-safe = 0 days)
- Staged files: Auto-purge after successful load
- Expected monthly storage: ~5 GB = ~$0.50/month

### Cost Tracking

```sql
-- View query costs
SELECT
    QUERY_TAG,
    SUM(CREDITS_USED_CLOUD_SERVICES) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG = 'PHASE_2_INGESTION'
GROUP BY QUERY_TAG;
```

---

## 🔐 Security Model

### RBAC Hierarchy

```
ACCOUNTADMIN (admin only)
    ↓
SYSADMIN (infrastructure)
    ↓
┌──────────────┬──────────────┬──────────────┬──────────────┐
LOADER_ROLE   ANALYTICS_ROLE  REPORTER_ROLE  CI_SERVICE_ROLE
(Phase 2)     (Phase 3)       (Phase 4)      (Automation)
```

### LOADER_ROLE Privileges

```sql
Database Level:  USAGE on OLIST_RAW_DB
Schema Level:    USAGE, CREATE on OLIST_RAW_DB.OLIST
Warehouse:       USAGE on LOADING_WH_XS
Tables:          INSERT, SELECT on OLIST_RAW_DB.OLIST.*
File Formats:    USAGE on CSV_GENERIC_FMT, JSON_GENERIC_FMT, PARQUET_GENERIC_FMT
Stage:           USAGE, READ on AZURE_STAGE
```

---

## 🧪 Testing & Validation

### Pre-Deployment Checklist

- [ ] Azure Tenant ID configured in 03_external_stages.sql
- [ ] User `AYAN` exists in Snowflake account
- [ ] ACCOUNTADMIN role accessible
- [ ] Azure Blob Storage accessible (LIST @stage works)
- [ ] File naming conventions match COPY patterns

### Post-Deployment Validation

```sql
-- 1. Verify all tables exist
SHOW TABLES IN SCHEMA OLIST_RAW_DB.OLIST;

-- 2. Check row counts
SELECT COUNT(*) FROM OLIST_RAW_DB.OLIST.raw_orders; -- Should be ~99,441

-- 3. Validate audit columns
SELECT
    _source_file,
    _loaded_at,
    _file_row_number
FROM OLIST_RAW_DB.OLIST.raw_customers
LIMIT 5;

-- 4. Check load errors
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OLIST_RAW_DB.OLIST.raw_orders',
    START_TIME => DATEADD(hours, -24, CURRENT_TIMESTAMP())
))
WHERE STATUS = 'LOAD_FAILED';

-- 5. Run quality checks
-- Execute 05_raw_data_quality_checks.sql and verify QUALITY_SCORE = 100%
```

---

## 🐛 Troubleshooting

### Issue: "Stage does not exist"

**Cause:** Database/schema name mismatch
**Fix:**

```sql
-- Verify correct naming
SHOW STAGES IN SCHEMA OLIST_RAW_DB.LANDING;
-- Ensure all references use OLIST_RAW_DB (not RAW_DB)
```

### Issue: "Insufficient privileges to operate on schema"

**Cause:** Missing RBAC grants
**Fix:**

```sql
USE ROLE ACCOUNTADMIN;
GRANT CREATE ON SCHEMA OLIST_RAW_DB.OLIST TO ROLE LOADER_ROLE;
GRANT USAGE ON FILE FORMAT OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT TO ROLE LOADER_ROLE;
```

### Issue: "Copy executed with 0 files processed"

**Cause:** Pattern mismatch with actual file names/paths
**Fix:**

```sql
-- Test pattern matching
LIST @OLIST_RAW_DB.LANDING.AZURE_STAGE PATTERN='(?i).*/customers/.*_dataset.*\.csv';
-- Adjust PATTERN in 04_copy_into_raw.sql to match actual file structure
```

### Issue: "VALIDATE() - Invalid argument"

**Cause:** VALIDATE with '\_LAST' not supported
**Fix:**

```sql
-- Use COPY_HISTORY instead
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OLIST_RAW_DB.OLIST.raw_orders'
));
```

### Issue: High credit consumption

**Cause:** Warehouse not suspending
**Fix:**

```sql
ALTER WAREHOUSE LOADING_WH_XS SET AUTO_SUSPEND = 60;
-- Verify warehouse is suspended when idle
SHOW WAREHOUSES;
```

---

## 📊 Data Quality Results (Phase 2 Completion)

### Summary

- **Total Tables:** 8
- **Total Rows Loaded:** ~1,550,688
- **Load Success Rate:** 100%
- **Data Quality Score:** 100%
- **Critical Issues:** 0
- **Minor Issues:** 12 (documented for Phase 3)

### Known Data Characteristics

✅ **All Critical Checks Passed:**

- No NULL primary/foreign keys
- No duplicate keys
- No orphaned records
- No future timestamps
- No invalid date sequences

⚠️ **Minor Issues (Non-Blocking):**

- 9 zero-value payments (0.009% of payments) → To investigate in Phase 3
- 3 "not_defined" payment types (0.003% of payments) → To map in Phase 3
- 7,981 payment outliers (expected for e-commerce)

---

## 🔄 Idempotency & Re-runs

All scripts are designed to be **re-runnable**:

```sql
-- Infrastructure scripts use OR REPLACE
CREATE OR REPLACE WAREHOUSE LOADING_WH_XS;

-- Ingestion scripts use FORCE=TRUE for full reloads
COPY INTO OLIST_RAW_DB.OLIST.raw_customers
FROM @AZURE_STAGE
FILES = ('...')
FORCE = TRUE; -- Set to TRUE for re-ingestion
```

**Best Practice for Production:**

- Initial load: `FORCE = FALSE` (default)
- Re-load: `FORCE = TRUE` (loads all files, even if previously loaded)
- Incremental: Remove `FILES` parameter, rely on Snowflake load tracking

---

## 📚 Documentation References

### Internal

- [Business Requirements](../docs/00_business_requirements.md)
- [Architecture Overview](../docs/01_architecture.md)
- [Azure Storage Setup](../docs/02_azure_storage_setup.md)
- [Data Dictionary](../docs/02_data_dictionary.md)
- [ADLC Framework](../docs/05_adlc_framework.md)

### External

- [Snowflake COPY INTO Documentation](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table)
- [Azure Storage Integration](https://docs.snowflake.com/en/user-guide/data-load-azure)
- [Snowflake Best Practices](https://docs.snowflake.com/en/user-guide/best-practices)

---

## ✅ Phase 2 Completion Criteria

- [x] Infrastructure deployed (warehouses, databases, schemas)
- [x] RBAC configured with 4 functional roles
- [x] Azure Storage Integration established
- [x] External stage validated (LIST command working)
- [x] 8 raw tables created with audit columns
- [x] Data loaded successfully from Azure Blob
- [x] Row counts validated (~1.5M total rows)
- [x] Data quality checks passed (100% quality score)
- [x] Cost controls active (resource monitors, auto-suspend)
- [x] Documentation complete (this README)

**Status:** ✅ **PHASE 2 COMPLETE - READY FOR PHASE 3 (dbt)**

---

## 👤 Maintainer

**Ayan Mulaskar**

- Role: Analytics Engineer
- Phase: Phase 2 – Data Acquisition & Ingestion
- Date: December 2025

---

## 📝 Change Log

| Date       | Version | Author | Change                                               |
| ---------- | ------- | ------ | ---------------------------------------------------- |
| 2025-12-28 | 1.0     | Ayan   | Initial Phase 2 setup complete                       |
| 2025-12-28 | 1.1     | Ayan   | Fixed RBAC grants for LOADER_ROLE                    |
| 2025-12-28 | 1.2     | Ayan   | Updated COPY patterns for Azure folder structure     |
| 2025-12-28 | 1.3     | Ayan   | Added case-insensitive pattern matching              |
| 2025-12-28 | 1.4     | Ayan   | Removed \_load_batch_id audit column                 |
| 2025-12-28 | 1.5     | Ayan   | Moved product_category_name_translation to dbt seeds |
| 2025-12-28 | 2.0     | Ayan   | Phase 2 validated and complete                       |

---

**End of Phase 2 Documentation**
