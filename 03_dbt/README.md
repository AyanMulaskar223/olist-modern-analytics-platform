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

## Testing and Data Quality

- Staging: unique, not_null, relationships, accepted_values on all keys and enums; freshness checks on sources.
- Singular tests cover ghost deliveries, timestamp order, negative prices/freight, payment vs order totals, physical dimensions, review score bounds.
- Known flagged issues (kept, not dropped): ghost deliveries (8), arrival-before-shipping (23), missing product dimensions (2), review duplicates (814), missing categories (610).

---

## How to Run

```bash
cd 03_dbt

dbt deps

dbt debug

dbt seed

dbt build --select staging
# run once intermediate models land
# dbt build --select intermediate
```

Linting: `sqlfluff lint models --dialect snowflake`
