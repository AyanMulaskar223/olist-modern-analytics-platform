# 🧱 dbt Transformations – Phase 3

## Overview

This folder contains dbt models that transform raw Olist e-commerce data into analytics-ready datasets. Built using dbt Core with Snowflake, following the Medallion architecture pattern (RAW → STAGING → INTERMEDIATE → MARTS).

**Current Status:** Phase 3 Staging Layer ✅ Complete

---

## 📂 Project Structure

```
03_dbt/
├── models/
│   ├── staging/olist/           # ✅ COMPLETE (9 models)
│   ├── intermediate/            # 📋 Planned
│   └── marts/                   # 📋 Planned
├── tests/staging/olist/         # ✅ COMPLETE (7 singular tests)
├── seeds/                       # Product category translations
├── macros/                      # Custom dbt macros
└── dbt_project.yml              # Project configuration
```

---

## 🎯 Staging Layer (Phase 3A)

### Purpose of the

1:1 mapping with RAW tables. Light cleaning, type casting, and standardization only. No business logic or aggregations.

### Models Implemented

| Model                              | Grain                  | Source             | Rows    | Status |
| ---------------------------------- | ---------------------- | ------------------ | ------- | ------ |
| `stg_olist__orders`                | Order                  | raw_orders         | 99,441  | ✅     |
| `stg_olist__customers`             | Customer (order-level) | raw_customers      | 99,441  | ✅     |
| `stg_olist__order_items`           | Line item              | raw_order_items    | 112,650 | ✅     |
| `stg_olist__payments`              | Payment transaction    | raw_order_payments | 103,886 | ✅     |
| `stg_olist__products`              | Product                | raw_products       | 32,951  | ✅     |
| `stg_olist__sellers`               | Seller                 | raw_sellers        | 3,095   | ✅     |
| `stg_olist__reviews`               | Review                 | raw_order_reviews  | 99,224  | ✅     |
| `stg_olist__geolocation`           | Coordinate             | raw_geolocation    | ~19K    | ✅     |
| `stg_olist__category_translations` | Category               | seed file          | 71      | ✅     |

### Design Principles

**✅ DO:**

- Import → Renamed → Final CTE pattern
- Explicit type casting (`::varchar`, `::timestamp_ntz`)
- Generate surrogate keys with `dbt_utils.generate_surrogate_key()`
- Flag data quality issues (e.g., `is_ghost_delivery`)
- Preserve RAW layer grain (no filtering, no aggregation)

**❌ DON'T:**

- Join tables (save for intermediate layer)
- Apply business rules (e.g., filtering to delivered orders only)
- Remove outliers (flag them instead)
- Aggregate data

### Key Transformations

- **Null Handling:** Impute with safe defaults (e.g., `'outros'` for missing categories, `0` for dimensions)
- **Standardization:** UPPER() for state codes, INITCAP() for city names, LPAD() for zip codes
- **Deduplication:** Remove duplicates in reviews (814 rows) and geolocation (SELECT DISTINCT)
- **JSON Parsing:** Flatten nested review data, convert 'NaN' strings to NULL

---

## 🧪 Data Quality Testing

### Test Coverage

**Generic Tests** (in `_stg_olist__models.yml`):

- `unique` + `not_null` on primary keys
- `relationships` for foreign key integrity
- `accepted_values` for status/category enums
- Total: ~50 generic tests across all models

**Singular Tests** (in `tests/staging/olist/`):

1. `assert_delivered_orders_have_delivery_date` – Validates 8 ghost deliveries (documented issue)
2. `assert_no_future_order_dates` – Prevents time travel bugs
3. `assert_no_negative_prices_or_freight` – Financial integrity check
4. `assert_order_timestamps_logical_sequence` – Validates order lifecycle
5. `assert_payment_amounts_match_order_totals` – Reconciliation (warn-level)
6. `assert_product_dimensions_physically_possible` – Logistics validation (warn-level)
7. `assert_review_scores_within_valid_range` – Rating system validation (1-5 scale)

### Known Data Quality Issues (Flagged, Not Removed)

| Issue                      | Count | Flag Column                  | Action              |
| -------------------------- | ----- | ---------------------------- | ------------------- |
| Ghost deliveries           | 8     | `is_ghost_delivery`          | Documented in test  |
| Arrival before shipping    | 23    | `is_arrival_before_shipping` | Flagged for review  |
| Missing product dimensions | 2     | `is_missing_dimensions`      | Imputed to 0        |
| Review duplicates          | 814   | N/A                          | Deduped via QUALIFY |
| Missing product categories | 610   | N/A                          | Imputed to 'outros' |

---

## 🚀 Quick Start

### Prerequisites

- Snowflake account with ANALYTICS_ROLE permissions
- dbt Core 1.7+ installed
- Environment variables configured:
  ```bash
  export SNOWFLAKE_ACCOUNT="your_account"
  export SNOWFLAKE_USER="your_user"
  export SNOWFLAKE_PASSWORD="your_password"
  ```

### Setup

```bash
cd 03_dbt

# Install dbt packages
dbt deps

# Test connection
dbt debug

# Load seed data
dbt seed

# Build staging models + run tests
dbt build --select staging

# Generate documentation
dbt docs generate && dbt docs serve
```

### Development Workflow

```bash
# Run single model
dbt run --select stg_olist__orders

# Run model + tests
dbt build --select stg_olist__orders

# Run all staging tests
dbt test --select staging

# Lint SQL
sqlfluff lint models/staging --dialect snowflake
```

---

## 📊 Materialization Strategy

| Layer            | Materialization         | Reasoning                                     |
| ---------------- | ----------------------- | --------------------------------------------- |
| **Staging**      | `view`                  | Zero storage cost, always fresh, fast compile |
| **Intermediate** | `ephemeral` / `table`   | TBD in Phase 3B                               |
| **Marts**        | `table` / `incremental` | TBD in Phase 3C                               |

---

## 🎓 dbt Learning Resources

- [Import CTE Pattern](https://docs.getdbt.com/best-practices/how-we-structure/2-staging#use-source-for-raw-data)
- [Surrogate Keys](https://github.com/dbt-labs/dbt-utils#generate_surrogate_key)
- [Testing Best Practices](https://docs.getdbt.com/docs/build/data-tests)
- [Snowflake Performance](https://docs.getdbt.com/reference/resource-configs/snowflake-configs)

---

## 📋 Next Steps (Phase 3B/C)

### Intermediate Layer

- [ ] `int_orders_enriched` – Join orders + items + payments + customers
- [ ] `int_customers_aggregated` – Calculate repeat customer flags, CLV
- [ ] `int_logistics_enriched` – Add geolocation, delivery SLA calculations

### Marts Layer (Star Schema)

- [ ] `fct_orders` – Order-level fact (delivered orders only)
- [ ] `fct_order_items` – Line-item fact (for product analysis)
- [ ] `dim_customers` – Customer dimension (SCD Type 1)
- [ ] `dim_products` – Product dimension (with category translations)
- [ ] `dim_sellers` – Seller dimension
- [ ] `dim_date` – Date dimension (using dbt_date package)

### DataOps (Phase 5)

- [ ] CI/CD pipeline with GitHub Actions
- [ ] Slim CI for PR validation
- [ ] dbt Cloud or Airflow orchestration
- [ ] Data freshness monitoring

---

## 📚 Documentation

**Business Context:** See [`docs/00_business_requirements.md`](../docs/00_business_requirements.md)
**Data Dictionary:** See [`docs/03_data_dictionary.md`](../docs/03_data_dictionary.md)
**Architecture:** See [`docs/01_architecture.md`](../docs/01_architecture.md)
**Phase 2 Validation:** See [`docs/04_data_quality_report.md`](../docs/04_data_quality_report.md)

---

## 🛠️ Troubleshooting

**Issue:** `dbt debug` fails with connection error
**Fix:** Verify environment variables and Snowflake role permissions

**Issue:** Tests fail on relationship validation
**Fix:** Ensure Phase 2 RAW data is loaded (`02_snowflake/02_ingestion/04_copy_into_raw.sql`)

**Issue:** `sqlfluff` linting errors
**Fix:** Run `sqlfluff fix models/staging --dialect snowflake` for auto-corrections

**Issue:** dbt can't find seed file
**Fix:** Ensure `product_category_name_translation.csv` exists in `seeds/` folder

---

**Maintainer:** Ayan Mulaskar
**Last Updated:** January 2026
**Phase Status:** 3A (Staging) ✅ Complete | 3B (Intermediate) 📋 Planned
