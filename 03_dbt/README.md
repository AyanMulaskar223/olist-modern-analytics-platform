# 🧱 dbt Transformations (Phase 3)

**Transforms Olist RAW data into analytics-ready datasets on Snowflake using dbt Core.**

This project implements a modern data stack following the Medallion Architecture pattern: RAW → STAGING → INTERMEDIATE → MARTS. Built with dimensional modeling principles (Kimball), automated testing, and production-grade documentation.

**Status:** Staging ✅ | Intermediate 🚧 | Marts 📋 Planned

**Tech Stack:** dbt Core 1.8+ | Snowflake | SQLFluff | dbt Utils + Expectations packages

---

## Quick Start

```bash
cd 03_dbt
dbt deps                           # Install packages
dbt debug                          # Test connection
dbt seed                           # Load reference data
dbt build --select staging         # Run staging models + tests
dbt build --select intermediate    # Run intermediate models + tests
```

**Linting:** `sqlfluff lint models --dialect snowflake`
**Docs:** `dbt docs generate && dbt docs serve`
**Quality Audit:** `dbt build --select package:dbt_project_evaluator`

---

## 🏆 Project Quality Standards

This project follows dbt best practices validated by the **dbt-project-evaluator** package.

### Audit Status

**Last Run:** January 21, 2026
**Result:** `PASS=76 WARN=5 ERROR=0` ✅
**Grade:** Production-Ready with Documented Exceptions

### What We Fixed

| Check                  | Status            | Action Taken                                                       |
| ---------------------- | ----------------- | ------------------------------------------------------------------ |
| **Source Freshness**   | ✅ **100%**       | Added freshness checks to all 8 sources (1-30 day thresholds)      |
| **Primary Key Tests**  | ✅ **100%**       | All fact/dimension tables have PK tests (composite PKs documented) |
| **Test Coverage**      | ✅ **>90%**       | 279 tests across staging/intermediate/marts layers                 |
| **Naming Conventions** | ✅ **Documented** | `meta_` prefix for ops tables follows enterprise pattern           |
| **No Staging Joins**   | ✅ **PASS**       | All staging models maintain 1:1 grain with sources                 |

### Documented Exceptions

Five warnings remain with **valid business justifications** (see [`seeds/dbt_project_evaluator_exceptions.csv`](seeds/dbt_project_evaluator_exceptions.csv)):

1. **Composite Primary Keys** – 4 models (dim_security_rls, dim_rls_bridge, stg_geolocation, meta_project_status)
2. **Meta Naming** – `meta_project_status` uses intentional `meta_` prefix for operational metadata
3. **Test Directory Structure** – Follows dbt best practice folder organization
4. **Seed-Based Models** – `stg_category_translations` references seed (not source)
5. **Exposure Configuration** – Dashboard correctly references public marts (evaluator false positive)

### How to Run Audit

```bash
cd 03_dbt
dbt build --select package:dbt_project_evaluator
```

View detailed results in generated models under `OLIST_DEV_DB.GOVERNANCE` schema.

---

## Project Map

```
03_dbt/
├── models/
│   ├── staging/olist/        # 9 views (1:1 with RAW)
│   ├── intermediate/         # 4 models (business logic)
│   └── marts/                # Star schema (planned)
├── tests/
│   ├── staging/olist/        # 7 singular tests
│   └── intermediate/         # 4 singular tests
├── seeds/                    # product_category_name_translation.csv
├── dbt_project.yml           # Materialization config
└── profiles.yml              # Snowflake connection
```

---

## Layer Architecture

| Layer        | Purpose                      | Materialization    | Count | Status |
| ------------ | ---------------------------- | ------------------ | ----- | ------ |
| RAW          | Landing zone from Phase 2    | Transient tables   | 8     | ✅     |
| STAGING      | 1:1 with RAW, light cleaning | Views              | 9     | ✅     |
| INTERMEDIATE | Business logic and joins     | Ephemeral or table | 4     | 🚧     |
| MARTS        | Star schema for BI           | Tables             | 0     | 📋     |

**Design Principles:**

- **Immutable RAW:** Never transform source data in place
- **No JOINs in Staging:** Preserve 1:1 grain with source tables
- **Flag, Don't Filter:** Keep all rows, mark data quality issues
- **Grain Preservation:** No aggregation until Marts layer

---

## RAW Layer

![Status](https://img.shields.io/badge/Materialization-Transient_Table-blue) ![Grain](https://img.shields.io/badge/Grain-Source_Native-orange)

### 📖 Layer Philosophy

The RAW layer is the immutable landing zone for data from Phase 2 (Snowflake ingestion). Its ONE job: **store source data exactly as received with minimal audit metadata**.

Three core principles:

1. **Immutability** - Once loaded, RAW data never changes (append-only or full refresh)
2. **Source Fidelity** - Preserve original column names, data types, and structure from Azure Blob
3. **Audit Trail** - Add only `_loaded_at` and `_source_file` for lineage tracking

This layer is NOT for consumption. It exists solely to provide a recoverable source-of-truth if upstream systems change or data needs reprocessing.

### 📂 Folder Structure

Located in Snowflake (not dbt models). Defined as sources in [`models/staging/olist/_sources.yml`](models/staging/olist/_sources.yml):

```
OLIST_RAW_DB.OLIST/
├── raw_orders                    # 99,441 rows
├── raw_order_items               # 112,650 rows
├── raw_customers                 # 99,441 rows
├── raw_products                  # 32,951 rows
├── raw_sellers                   # 3,095 rows
├── raw_order_payments            # 103,886 rows
├── raw_order_reviews             # 99,224 rows (JSON source)
└── raw_geolocation               # 1M+ rows
```

**Storage:** `TRANSIENT` tables (no Fail-safe, 50% cost savings)
**Retention:** Time Travel enabled for 1 day

### 🧠 Key Patterns & Decisions

**Problem #1: Mixed Source Formats**
Data arrives in CSV, Parquet, and JSON from Azure Blob Storage.

**Solution:** Use Snowflake's `COPY INTO` with format-specific file formats:

- CSV: `CSV_GENERIC_FMT` (handles quotes, nulls, dates)
- Parquet: `PARQUET_FMT` (schema auto-detection)
- JSON: `JSON_FMT` (stores as VARIANT column)

All loads are idempotent using `FORCE = FALSE` to skip already-loaded files.

**Problem #2: Schema Drift Risk**
Olist could change column names or types in future data drops.

**Solution:**

- Explicit column mapping in COPY INTO (no `SELECT $1, $2, $3` shortcuts)
- Phase 2 validation queries catch schema mismatches before dbt runs
- dbt source freshness tests alert on stale data

**Problem #3: Case Sensitivity**
Snowflake lowercases identifiers, but JSON preserves original casing.

**Solution:** Quote all column names in dbt sources: `"order_id"` instead of `order_id`. Staging layer normalizes to snake_case.

**Problem #4: Cost Control**
Fact tables are large (112K+ rows for order_items) and query costs add up.

**Solution:**

- Use TRANSIENT tables (no 7-day Fail-safe = 50% cheaper)
- Auto-suspend warehouse after 60 seconds idle
- Tag all queries with `QUERY_TAG = 'PHASE_2_RAW_INGESTION'` for cost attribution

### 🛠️ Model Reference

| Table                | Rows    | Source Format | Load Pattern | Key Columns                             |
| -------------------- | ------- | ------------- | ------------ | --------------------------------------- |
| `raw_orders`         | 99,441  | CSV           | Full refresh | order_id (PK), customer_id (FK)         |
| `raw_order_items`    | 112,650 | Parquet       | Full refresh | order_id + order_item_id (PK)           |
| `raw_customers`      | 99,441  | CSV           | Full refresh | customer_id (PK), customer_unique_id    |
| `raw_products`       | 32,951  | CSV           | Full refresh | product_id (PK), product_category_name  |
| `raw_sellers`        | 3,095   | CSV           | Full refresh | seller_id (PK), seller_state            |
| `raw_order_payments` | 103,886 | CSV           | Full refresh | order_id (FK), payment_sequential       |
| `raw_order_reviews`  | 99,224  | JSON          | Full refresh | review_id (PK stored in VARIANT)        |
| `raw_geolocation`    | 1M+     | CSV           | Full refresh | geolocation_zip_code_prefix (composite) |

**Common Metadata Columns (all tables):**

- `_loaded_at` (TIMESTAMP_NTZ): Phase 2 ingestion timestamp
- `_source_file` (VARCHAR): Original Azure Blob path for lineage

### 🧪 Testing Strategy

**Source Tests (in `_sources.yml`):**

- **`unique`**: Primary keys (order_id, product_id, seller_id, customer_id)
- **`not_null`**: All primary keys and mandatory foreign keys
- **`relationships`**: Foreign key integrity (order_id → customers, products, sellers)
- **`accepted_values`**: Enums (order_status, payment_type, state codes)

**Source Freshness Checks:**

- **Orders:** Warn after 1 day, error after 2 days (critical path)
- **Customers/Products:** Warn after 7 days, error after 14 days (slower-moving)

**Data Quality Validation (Phase 2 scripts):**

- Row count reconciliation (Azure Blob vs Snowflake)
- NULL value profiling per column
- Duplicate detection on primary keys
- Date range validation (orders within 2016-2018)

**Known Data Quality Issues (from Phase 2):**

- Missing delivery dates: 2,965 orders (valid for non-delivered status)
- Duplicate geolocation coords: 1M+ rows deduplicated to 19K unique zip codes
- JSON review duplicates: 814 duplicate review_ids (same customer, multiple reviews)

These are documented but NOT fixed in RAW. Staging layer will flag them.

---

## Staging Layer

![Status](https://img.shields.io/badge/Materialization-View-blue) ![Grain](https://img.shields.io/badge/Grain-1:1_with_Source-orange)

### 📖 Layer Philosophy

The staging layer is the foundation of the dbt project. Its ONE job: **clean and standardize raw data without changing grain or applying business logic**.

Three core principles:

1. **1:1 Mapping** - Every RAW table gets exactly one staging model (no joins, no aggregations)
2. **Type Safety** - Cast everything explicitly (VARCHAR, NUMERIC, TIMESTAMP_NTZ) to prevent downstream surprises
3. **Flag, Don't Filter** - Identify data quality issues with boolean flags, but keep all rows for analysis

This layer does the boring-but-critical work: fix typos, standardize casing, trim whitespace, cast types, generate surrogate keys. No business decisions happen here.

### 📂 Folder Structure

Organized by **data source** (all models come from one source: Olist):

```
models/staging/olist/
├── _sources.yml                      # Source definitions pointing to RAW tables
├── _stg_olist__models.yml            # Tests and documentation
├── stg_olist__orders.sql             # Master transaction record
├── stg_olist__order_items.sql        # Line items (products per order)
├── stg_olist__customers.sql          # Customer master data
├── stg_olist__products.sql           # Product catalog
├── stg_olist__sellers.sql            # Seller master data
├── stg_olist__payments.sql           # Payment transactions
├── stg_olist__reviews.sql            # Customer reviews (JSON source)
├── stg_olist__geolocation.sql        # Lat/long reference data
└── stg_olist__category_translations.sql  # English translations (seed)
```

### 🧠 Key Patterns & Decisions

**Problem #1: Olist's Source Typos**
The source CSV has `lenght_cm` instead of `length_cm`. Also, category names have inconsistent capitalization.

**Solution:** Rename columns to correct spelling in staging, standardize text with `INITCAP()` for cities and `UPPER()` for state codes. Document the fix in YAML so future analysts know it wasn't our mistake.

**Problem #2: Missing Data Semantics**
Some NULL values are legitimate (orders not yet delivered), others are data quality issues (products missing dimensions).

**Solution:** Create explicit boolean flags:

- `is_ghost_delivery` (delivered_at exists but shipped_at is NULL)
- `is_missing_dimensions` (weight/size NULL for products)
- `is_arrival_before_shipping` (impossible logistics timeline)

Keep the rows, flag the issues, let business decide how to handle them.

**Problem #3: JSON Reviews in CSV World**
Reviews come from JSON, everything else is CSV/Parquet. Need consistent output.

**Solution:** Parse JSON in staging with `PARSE_JSON()` and `GET()`, flatten to tabular structure. Add `is_duplicate_review` flag since 814 reviews have duplicate IDs (same customer reviewed same order multiple times).

**Problem #4: Non-Unique "Unique" IDs**
Olist's `customer_unique_id` isn't actually unique. Same person, multiple addresses → multiple IDs.

**Solution:** Generate two keys:

- `customer_sk` (hash of `order_customer_id` - truly unique per order)
- `user_sk` (hash of `customer_unique_id` - persistent person identity)

Intermediate layer will resolve the identity using `user_sk`.

### 🛠️ Model Reference

| Model                              | Rows    | Grain                              | Key Fixes                                      |
| ---------------------------------- | ------- | ---------------------------------- | ---------------------------------------------- |
| `stg_olist__orders`                | 99,441  | One row per order                  | Timestamp casting, quality flags (ghost, etc.) |
| `stg_olist__order_items`           | 112,650 | One row per product per order      | Surrogate key generation                       |
| `stg_olist__customers`             | 99,441  | One row per order-customer pairing | Dual keys (customer_sk + user_sk)              |
| `stg_olist__products`              | 32,951  | One row per product                | NULL imputation ('outros'), dimension flags    |
| `stg_olist__sellers`               | 3,095   | One row per seller                 | Location standardization                       |
| `stg_olist__payments`              | 103,886 | One row per payment transaction    | Installment handling                           |
| `stg_olist__reviews`               | 99,224  | One row per review                 | JSON parsing, duplicate flags                  |
| `stg_olist__geolocation`           | 1M+     | One row per zip-lat-long combo     | Deduplication for centroid calculation         |
| `stg_olist__category_translations` | 71      | One row per category               | Portuguese → English mapping                   |

**Common Patterns Across All Models:**

- **Surrogate Keys:** Generated via `dbt_utils.generate_surrogate_key([natural_key])`
- **Audit Columns:** `source_filename`, `source_loaded_at_utc` preserved from Phase 2
- **Text Cleaning:** `TRIM()`, `UPPER()`, `INITCAP()` applied consistently
- **Type Safety:** No implicit casting—everything explicit in SELECT

### 🧪 Testing Strategy

**Generic Tests (50+ across all models):**

- **`unique`**: Every primary key and surrogate key
- **`not_null`**: All keys, status fields, and mandatory business fields
- **`relationships`**: Foreign keys validated against parent tables
- **`accepted_values`**: Order status, payment types, state codes (27 Brazilian states)

**Singular Tests (7 business logic checks in `tests/staging/olist/`):**

1. **`assert_delivered_orders_have_delivery_date`**
   - **What:** If `order_status = 'DELIVERED'`, then `delivered_at` must exist
   - **Why:** Catch incomplete status updates

2. **`assert_no_future_order_dates`**
   - **What:** All order timestamps ≤ today
   - **Why:** Prevent data entry errors or timezone issues

3. **`assert_no_negative_prices_or_freight`**
   - **What:** `item_price_brl >= 0` and `item_freight_brl >= 0`
   - **Why:** Negative values break revenue calculations

4. **`assert_order_timestamps_logical_sequence`**
   - **What:** `ordered_at ≤ approved_at ≤ shipped_at ≤ delivered_at`
   - **Why:** Impossible timelines indicate data corruption

5. **`assert_payment_amounts_match_order_totals`**
   - **What:** SUM(payments) per order = SUM(items) per order (within 1 cent tolerance)
   - **Why:** Accounting integrity check

6. **`assert_product_dimensions_physically_possible`**
   - **What:** Length/width/height ≤ 300 cm, weight ≤ 100 kg
   - **Why:** Catch data entry errors (e.g., extra zeros)

7. **`assert_review_scores_within_valid_range`**
   - **What:** Review scores BETWEEN 1 AND 5
   - **Why:** Olist uses 1-5 star scale

**Known Flagged Issues (Kept, Not Removed):**

- Ghost deliveries: 8 orders
- Arrival before shipping: 23 orders
- Missing product dimensions: 2 products
- Review duplicates: 814 reviews
- Missing categories: 610 products

These are flagged for analysis but NOT filtered out. Business users can exclude them in reports if needed.

---

## Intermediate Layer

![Status](https://img.shields.io/badge/Materialization-Ephemeral-blue) ![Grain](https://img.shields.io/badge/Grain-Order_Item-orange)

### 📖 Layer Philosophy

The intermediate layer bridges staging and marts by implementing business logic without sacrificing grain. Three core jobs:

1. **Identity Resolution** - Link transactional IDs to persistent customer identities
2. **Business Logic Consolidation** - Centralize complex joins, window functions, and calculations
3. **Quality Compression** - Consolidate multiple flags into actionable diagnostics

All transformations preserve the natural grain of the source entities (one row per order item, one row per person, etc.). No aggregation happens here—that's reserved for marts.

### 📂 Folder Structure

Organized by **business domain** to scale as the project grows:

```
models/intermediate/
├── sales/                           # Revenue and transaction logic
│   ├── int_sales__order_items_joined.sql
│   └── int_customers__prep.sql
├── products/                        # Catalog and inventory logic
  └── int_products__enriched.sql

```

### 🧠 Key Patterns & Decisions

**Problem #1: Olist's Customer Identity Quirk**
Every order creates a new `customer_id`, making repeat customer analysis impossible at the staging level.

**Solution:** Implement "baton pass" identity resolution:

- `stg_orders.customer_id` (transactional) → `stg_customers.user_sk` (persistent person) → `customer_sk` (dimension key)
- Result: LTV and frequency analysis now work correctly in Power BI

**Problem #2: Retention Sequencing**
Need to classify orders as "new" or "repeat" at point-in-time (when order was placed, not retrospectively).

**Solution:** `ROW_NUMBER() OVER (PARTITION BY user_sk ORDER BY ordered_at ASC)` in `int_sales__order_items_joined`. Pre-filter ensures canceled/empty orders don't burn sequence numbers.

**Problem #3: Quality Flag Explosion**
Passing 4+ boolean flags downstream clutters Power BI and creates confusion.

**Solution:** Compress into two fields:

- `is_verified` (1/0): One-click filter for clean records
- `quality_issue_reason` (VARCHAR): Diagnostic for root cause analysis

### 🛠️ Model Reference

| Model                           | Purpose                      | Grain                 | Materialization |
| ------------------------------- | ---------------------------- | --------------------- | --------------- |
| `int_sales__order_items_joined` | Foundation for fact table    | One row per line item | Ephemeral       |
| `int_customers__prep`           | Deduplicated customer master | One row per person    | View            |
| `int_products__enriched`        | Bilingual product catalog    | One row per product   | Ephemeral       |

**Key Transformations:**

- **Sales Model:** Identity resolution, retention sequence, delivery SLA flags, quality compression
- **Customer Model:** Latest address selection via `ROW_NUMBER()`, location deduplication
- **Product Model:** English translation mapping (Portuguese fallback), quality flag consolidation
- **Date Model:** Continuous calendar 2016-2020, `YYYYMM` sort keys, weekend flags

### 🧪 Testing Strategy

Two custom singular tests enforce business logic integrity:

1. **`assert_int_sales_retention_sequence_integrity`**
   - **What:** Every customer must have an order with `sequence_number = 1`
   - **Why:** If someone starts at #2, identity resolution broke
   - **Impact:** Protects repeat customer KPIs from silent corruption

2. **`assert_int_sales_dq_flags_consistent`**
   - **What:** If `is_verified = 0`, then `quality_issue_reason` must be populated
   - **Why:** No silent failures—always explain what's wrong
   - **Impact:** Maintains trust in data quality metadata

**Performance Note:** Default materialization is ephemeral (zero storage cost). If Snowflake costs spike or queries slow down, promote `int_sales__order_items_joined` to table materialization—the window functions are the main bottleneck.

---

Here is the polished, professional version of your **Marts Layer** section.

I have enhanced the formatting to make it more scannable for recruiters, emphasized the "Senior Engineering" decisions, and aligned the **Meta** section with the "Two Clocks" strategy we just finalized.

---

## 💎 Marts Layer

![alt text](https://img.shields.io/badge/Status-Production_Ready-success?style=flat-square)
![alt text](https://img.shields.io/badge/Materialization-Table/Incremental-blue?style=flat-square)
![alt text](https://img.shields.io/badge/Architecture-Star_Schema-orange?style=flat-square)

### 📖 Layer Philosophy

The marts layer is the **Consumption Zone**. Its single purpose is to package intermediate logic into a clean **Star Schema** optimized for Power BI Import Mode.

**Core Design Principles:**

1. **Logic Already Happened:** No window functions, no complex `JOIN`s, no `CASE` statements. This layer strictly selects and renames.
2. **Load Everything:** We do not filter "Bad Data" here. We flag it (`is_verified = 0`). This allows the BI tool to report on "Data Quality" rather than hiding it.
3. **Star Schema Alignment:** A central fact table (`fct_`) surrounded by denormalized dimensions (`dim_`). No snowflakes. This reduces JOIN complexity in the BI layer.

---

### 📂 Folder Structure

Organized by **Business Domain** to match the downstream Power BI workspace structure:

```text
models/marts/
├── core/                          # 🌍 Shared Dimensions (The "Conformed" Layer)
│   ├── dim_customers.sql          # Customer Master (Merged Profiles)
│   ├── dim_products.sql           # Product Catalog (English/Portuguese merged)
│   ├── dim_sellers.sql            # Seller Master
│   ├── dim_date.sql               # Date Intelligence (2016-2020)
│   ├── dim_security_rls.sql       # RLS: User-to-State Mapping
│   └── dim_rls_bridge.sql         # RLS: State-to-Seller Bridge
├── sales/                         # 💰 Sales Domain
│   └── fct_order_items.sql        # The Transactional Fact Table
└── meta/                          # ⚙️ System Observability
    └── meta_project_status.sql    # The "Heartbeat" Table (Pipeline Health)

```

---

### 🧠 Key Architecture Decisions

This section highlights the "Senior" engineering choices made to solve specific business problems.

#### **Problem #1: "Where is the Lost Revenue?"**

The business needed to calculate "Cancellation Rate" and "Lost Revenue."

- **❌ Junior Approach:** Filter `WHERE order_status = 'delivered'` in SQL to get clean data.
- **✅ Senior Solution:** Load **ALL** statuses (delivered, canceled, unavailable) into `fct_order_items`. logic is pushed to DAX measures:
- `Total Revenue` = `CALCULATE(SUM(price), status = 'delivered')`
- `Lost Revenue` = `CALCULATE(SUM(price), status = 'canceled')`

#### **Problem #2: The "Duplicate Customer" Issue**

Olist generates a new `customer_id` for every single order, breaking retention analysis.

- **✅ Senior Solution:** We use `customer_sk` (a persistent surrogate key generated in the Intermediate layer) for all Fact-to-Dimension joins. The original transactional `order_id` is kept only as a degenerate dimension for drill-through.

#### **Problem #3: Performance vs. Normalization**

Product Category translations lived in a separate table, inviting a Snowflake Schema.

- **✅ Senior Solution:** We flattened the hierarchy in SQL. English and Portuguese names are joined into `dim_products`. Power BI sees one wide, denormalized dimension, reducing query cost during report rendering.

#### **Problem #4: The "Pipeline Black Box"**

Stakeholders didn't know if the dashboard data was fresh or stuck.

- **✅ Senior Solution:** Created `meta_project_status`, a singleton table tracking two distinct clocks:

1. **Pipeline Time:** When dbt last ran successfully.
2. **Business Time:** The latest order date in the system (handling the 2018 historical cutoff).

---

### 🛠️ Model Reference

#### **Facts (Sales Domain)**

| Model                 | Grain                 | Materialization | Key Measures                     |
| --------------------- | --------------------- | --------------- | -------------------------------- |
| **`fct_order_items`** | One row per Line Item | `incremental`   | `price_brl`, `freight_value_brl` |

#### **Dimensions (Core Domain)**

| Model                  | Grain                   | Key Attributes                                |
| ---------------------- | ----------------------- | --------------------------------------------- |
| **`dim_customers`**    | One row per **Person**  | `customer_city`, `is_repeat_buyer`            |
| **`dim_products`**     | One row per **Product** | `category_name_english`, `product_volume_cm3` |
| **`dim_sellers`**      | One row per **Seller**  | `seller_city`, `seller_state`                 |
| **`dim_date`**         | One row per **Day**     | `is_weekend`, `quarter_text`                  |
| **`dim_security_rls`** | One row per **Manager** | `state_code` (Security Filter)                |

#### **Metadata (Observability)**

| Model                     | Grain                 | Purpose                                               |
| ------------------------- | --------------------- | ----------------------------------------------------- |
| **`meta_project_status`** | **Singleton** (1 Row) | Powers the "Data Current Through" footer in Power BI. |

---

### 🧪 Testing Strategy (The Safety Net)

We employ a "Defense in Depth" strategy using both Generic and Singular tests.

#### **1. Generic Tests (YAML)**

Applied to every model to ensure structural integrity.

- **`unique`**: Applied to all Surrogate Keys (`_sk`).
- **`not_null`**: Applied to PKs and FKs.
- **`relationships`**: Ensures referential integrity (no Orphan records).
- **`accepted_values`**: Validates Order Status and Payment Types.

#### **2. Singular Tests (Business Logic)**

Seven custom SQL tests (`tests/marts/`) act as our "Business Logic Unit Tests."

| Domain    | Test Name                            | The Logic                                       | Why it matters?                                              |
| --------- | ------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------ |
| **Core**  | `mart_dim_date_completeness`         | Checks for missing dates (2016-2020).           | Prevents "Time Intelligence" breaks in Power BI.             |
| **Core**  | `mart_rls_seller_state_coverage`     | Ensures all 27 Brazilian states exist in RLS.   | Prevents silent data loss for Regional Managers.             |
| **Sales** | `mart_fct_order_items_metric_ranges` | `price >= 0`, `freight >= 0`.                   | Catches impossible negative values before the CEO sees them. |
| **Sales** | `mart_fct_order_items_quality_flags` | If `is_verified=0`, `reason` must be populated. | Enforces "Root Cause" documentation for bad data.            |

---

### 🏃 How to Run

```bash
# 1. Install dependencies
dbt deps

# 2. Test connection
dbt debug

# 3. Build the specific layer (recommended)
dbt build --select marts

# 4. Run data quality tests only
dbt test --select marts

```
