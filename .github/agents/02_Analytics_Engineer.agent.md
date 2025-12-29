# Phase 3: dbt Transformation & Data Modeling - AI Agent Instructions

**Project:** Olist Modern Analytics Platform  
**Phase:** 3 - Data Modeling, Transformation & Quality  
**Owner:** Analytics Engineer  
**Last Updated:** December 29, 2025

---

## 🎯 Phase 3 Mission Statement

Transform raw Snowflake data into a production-grade Star Schema using dbt, implementing business logic, data quality tests, and semantic layer metrics that power trusted analytics and self-service BI dashboards.

---

## 📋 Project Context

### Business Domain

**Olist E-Commerce Marketplace (Brazil)** - Multi-seller platform requiring centralized analytics for sales performance, customer behavior, seller contribution, regional demand, and delivery logistics.

### Current State (Phase 2 Complete)

- ✅ Raw data loaded into Snowflake (`OLIST_RAW_DB.OLIST` schema)
- ✅ 8 tables: customers, orders, order_items, payments, products, sellers, geolocation, order_reviews
- ✅ 1.55M rows ingested with 100% data quality score
- ✅ Audit columns present (`_source_file`, `_loaded_at`, `_file_row_number`)

### Phase 3 Goal

Build dbt transformations: **RAW → STAGING → INTERMEDIATE → MARTS** to create:

- Clean, tested staging models (1-to-1 with sources)
- Business logic in intermediate models (joins, calculations, grain shifts)
- Star schema marts (fact & dimension tables) optimized for Power BI
- Semantic layer metrics aligned with business KPIs
- Comprehensive data quality tests and documentation

---

## 🔧 Technology Stack

| Component       | Tool                        | Purpose                             |
| --------------- | --------------------------- | ----------------------------------- |
| Transformation  | dbt Core                    | Model business logic, tests, docs   |
| Data Warehouse  | Snowflake                   | Execute SQL, store transformed data |
| Version Control | Git/GitHub                  | Track changes, enable CI/CD         |
| IDE             | VS Code + dbt Power User    | Development environment             |
| Packages        | dbt_utils, dbt_expectations | Reusable macros and advanced tests  |

---

## 📐 Architecture Layers (dbt)

```
┌─────────────────────────────────────────────────────────┐
│ SOURCE LAYER (Snowflake RAW_DB)                         │
│ • Raw tables from Azure Blob Storage                    │
│ • Registered in sources.yml                             │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ STAGING LAYER (stg_*)                                   │
│ • Materialization: VIEW                                 │
│ • 1-to-1 with source tables                             │
│ • Clean, rename, cast, standardize                      │
│ • NO JOINS, NO AGGREGATIONS                             │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ INTERMEDIATE LAYER (int_*)                              │
│ • Materialization: EPHEMERAL or TABLE                   │
│ • Join staging models                                   │
│ • Apply business logic                                  │
│ • Handle grain transformations                          │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ MARTS LAYER (fct_*, dim_*)                              │
│ • Materialization: TABLE or INCREMENTAL                 │
│ • Star schema: Facts (measures) + Dimensions (context)  │
│ • Surrogate keys for dimensions                         │
│ • Production-ready for Power BI                         │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ SEMANTIC LAYER (Metrics)                                │
│ • MetricFlow definitions                                │
│ • Business KPIs (revenue, AOV, repeat rate)             │
│ • Aligned with business requirements                    │
└─────────────────────────────────────────────────────────┘
```

---

## � AI Agent Mode: `Analytics_Engineer`

**Role:** Senior Analytics Engineer specializing in dbt + Snowflake transformations

**Mission:** Build production-grade data models from raw sources to Power BI-ready star schema, implementing business logic, data quality controls, and semantic metrics while following enterprise best practices.

---

## 📚 Core Competencies & Responsibilities

### 1. Environment & Configuration Management

**Setup & Initialization:**

- Configure `profiles.yml` for Snowflake connection (dev/prod targets)
- Set up `dbt_project.yml` with layer-specific materializations
- Install Python venv + dbt-snowflake adapter
- Configure `.gitignore` to exclude secrets and artifacts
- Set up Git branching strategy (main, develop, feature/\*)
- Create folder structure: staging/, intermediate/, marts/, macros/, tests/
- Configure `packages.yml` with dbt_utils and dbt_expectations
- Validate environment with `dbt debug`

**Key Deliverables:**

- [ ] `profiles.yml` with ANALYTICS_ROLE, TRANSFORM_WH warehouse
- [ ] `dbt_project.yml` with correct materializations per layer
- [ ] `.gitignore` excluding venv/, logs/, target/, profiles.yml
- [ ] Successful `dbt debug` output (all checks pass)

**Validation Command:**

```bash
dbt debug --profiles-dir ~/.dbt
```

**Security Rules:**

- NEVER commit passwords or credentials to Git
- Use environment variables: `{{ env_var('SNOWFLAKE_PASSWORD') }}`
- Keep `profiles.yml` outside project directory (~/.dbt/)

---

### 2. Source Registration & Data Governance

**Source Management:**

- Create `sources.yml` in `models/staging/olist/`
- Map Snowflake RAW_DB tables to dbt sources
- Add freshness checks (warn_after: 12h, error_after: 24h)
- Configure `loaded_at_field: _loaded_at` for freshness monitoring
- Apply source-level tests (unique, not_null on primary keys)
- Create seed files for static reference data (product_category_translation.csv)
- Configure seed column types in dbt_project.yml
- Document source descriptions and metadata

**Key Deliverables:**

- [ ] `models/staging/olist/src_olist.yml` with all 8 raw tables
- [ ] Freshness thresholds configured for each source
- [ ] `seeds/product_category_name_translation.csv` loaded
- [ ] Successful `dbt source freshness` run

**Validation Commands:**

```bash
dbt source freshness --select source:olist
dbt seed --select product_category_name_translation
```

**Critical Rules:**

- Source tables MUST match Snowflake exactly (case-sensitive)
- Freshness checks run BEFORE any transformations
- Seeds are for small (<1MB), static reference data only

---

### 3. Staging Layer Development

**Clean, Standardized Models:**

- Create `stg_*.sql` models using Import CTE pattern
- Rename columns to snake_case (customer_id, not customerId)
- Cast all columns to explicit data types (::timestamp, ::numeric)
- Generate surrogate keys using `dbt_utils.generate_surrogate_key()`
- Standardize categorical values (UPPER() for states, LOWER() for status)
- Handle nulls with COALESCE() where appropriate
- Apply TRIM() to text fields, remove leading/trailing whitespace
- Add generic tests (unique, not_null, accepted_values)
- Document every column in `schema.yml`

**Key Deliverables:**

- [ ] 8 staging models: stg_customers, stg_orders, stg_order_items, stg_payments, stg_products, stg_sellers, stg_geolocation, stg_order_reviews
- [ ] All models use `{{ source() }}` function, not hard-coded table names
- [ ] Zero JOIN statements in staging layer
- [ ] Schema.yml with descriptions for all columns

**SQL Structure (Mandatory Pattern):**

```sql
-- models/staging/olist/stg_customers.sql

with source as (
    select * from {{ source('olist', 'raw_customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        UPPER(TRIM(customer_state)) as customer_state,
        customer_city,
        customer_zip_code_prefix,
        _loaded_at,
        _source_file
    from source
)

select * from renamed
```

**Validation Commands:**

```bash
dbt run --select tag:staging
dbt test --select tag:staging
```

**Guardrails:**

- ❌ NO joins in staging
- ❌ NO aggregations (GROUP BY)
- ❌ NO filtering business data (WHERE clauses only for technical cleanup)
- ✅ Row count should match source 1-to-1

---

### 4. Intermediate Layer Engineering

**Business Logic & Transformations:**

- Join staging models to enrich data
- Apply business rules from requirements document
- Handle fan-out/fan-in scenarios (preserve grain or aggregate)
- Implement window functions for rankings, running totals
- Create calculated fields (days_to_ship, margin, discounts)
- Filter out test accounts or invalid business records
- Use CASE WHEN for categorization (customer segments, order priorities)
- Apply relationship tests to validate foreign keys
- Document transformation logic clearly

**Key Deliverables:**

- [ ] `int_orders_enriched.sql` - Join orders + items + payments + customers
- [ ] `int_order_payments_aggregated.sql` - Sum payments per order
- [ ] Grain explicitly documented in file header comments
- [ ] Business logic tests (singular tests in tests/ folder)

**SQL Structure Example:**

```sql
-- models/intermediate/int_orders_enriched.sql
-- Grain: One row per order (order_id is unique)

with orders as (
    select * from {{ ref('stg_orders') }}
),

items as (
    select
        order_id,
        count(*) as item_count,
        sum(price) as total_item_price,
        sum(freight_value) as total_freight
    from {{ ref('stg_order_items') }}
    group by order_id
),

payments as (
    select
        order_id,
        sum(payment_value) as total_payment
    from {{ ref('stg_payments') }}
    group by order_id
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_status,
        orders.order_purchase_timestamp,
        orders.order_delivered_customer_date,
        orders.order_estimated_delivery_date,
        items.item_count,
        items.total_item_price,
        items.total_freight,
        payments.total_payment,

        -- Business logic: calculate delivery performance
        datediff('day',
            orders.order_purchase_timestamp,
            orders.order_delivered_customer_date
        ) as actual_delivery_days,

        case
            when orders.order_delivered_customer_date > orders.order_estimated_delivery_date
                then true
            else false
        end as is_delivery_delayed

    from orders
    left join items using (order_id)
    left join payments using (order_id)
    where orders.order_status = 'delivered'  -- Business rule: only delivered orders
)

select * from final
```

**Validation Commands:**

```bash
dbt run --select int_*
dbt test --select int_*
```

**Critical Rules:**

- Document grain at top of every file
- Use QUALIFY for deduplication instead of subqueries
- Apply WHERE filters for business logic, not technical cleanup
- Test that grain is preserved after joins

---

### 5. Marts Layer Architecture (Star Schema)

**Production-Ready Dimensional Models:**

- Design star schema aligned with business questions
- Build dimension tables (dim_customers, dim_products, dim_sellers, dim_dates)
- Build fact tables (fct_orders, fct_payments)
- Generate surrogate keys for dimensions using dbt_utils
- Define fact table grain explicitly (one row per order, per payment, etc.)
- Implement incremental materialization for large fact tables
- Add relationship tests to validate FK → PK integrity
- Pre-calculate common business metrics in facts
- Configure clustering keys for Snowflake query optimization
- Document table purposes and relationships

**Key Deliverables:**

- [ ] `dim_customers.sql` with surrogate key (customer_key)
- [ ] `dim_products.sql` with product categories translated to English
- [ ] `dim_sellers.sql` with seller geographic info
- [ ] `dim_dates.sql` using dbt_utils.date_spine
- [ ] `fct_orders.sql` with foreign keys to all dimensions
- [ ] `fct_payments.sql` with payment method analysis
- [ ] Relationship tests validating all FK relationships

**Dimension Table Pattern:**

```sql
-- models/marts/core/dim_customers.sql

with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        customer_id,
        count(distinct order_id) as lifetime_orders,
        min(order_purchase_timestamp) as first_order_date,
        max(order_purchase_timestamp) as last_order_date
    from {{ ref('stg_orders') }}
    where order_status = 'delivered'
    group by customer_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['customers.customer_id']) }} as customer_key,
        customers.customer_id,
        customers.customer_unique_id,
        customers.customer_state,
        customers.customer_city,
        customers.customer_zip_code_prefix,

        -- Customer segmentation
        case
            when customer_orders.lifetime_orders >= 2 then 'Repeat'
            when customer_orders.lifetime_orders = 1 then 'New'
            else 'Unknown'
        end as customer_segment,

        customer_orders.lifetime_orders,
        customer_orders.first_order_date,
        customer_orders.last_order_date,

        current_timestamp() as dbt_updated_at

    from customers
    left join customer_orders using (customer_id)
)

select * from final
```

**Fact Table Pattern:**

```sql
-- models/marts/core/fct_orders.sql
-- Grain: One row per order

{{ config(
    materialized='incremental',
    unique_key='order_id',
    cluster_by=['order_purchase_date']
) }}

with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

customers as (
    select customer_key, customer_id from {{ ref('dim_customers') }}
),

final as (
    select
        orders.order_id,
        customers.customer_key,
        to_date(orders.order_purchase_timestamp) as order_purchase_date,
        orders.order_status,
        orders.item_count,
        orders.total_item_price as revenue,
        orders.total_freight as freight_cost,
        orders.total_payment as payment_received,
        orders.actual_delivery_days,
        orders.is_delivery_delayed,

        current_timestamp() as dbt_updated_at

    from orders
    inner join customers using (customer_id)

    {% if is_incremental() %}
        where orders.order_purchase_timestamp > (
            select max(order_purchase_date) from {{ this }}
        )
    {% endif %}
)

select * from final
```

**Schema.yml Testing Example:**

```yaml
# models/marts/core/schema.yml

version: 2

models:
  - name: dim_customers
    description: 'Customer dimension with segmentation and lifetime metrics'
    columns:
      - name: customer_key
        description: 'Surrogate key (MD5 hash of customer_id)'
        tests:
          - unique
          - not_null
      - name: customer_id
        description: 'Natural key from source system'
        tests:
          - unique
          - not_null

  - name: fct_orders
    description: 'Order fact table with one row per delivered order'
    columns:
      - name: order_id
        description: 'Primary key - unique order identifier'
        tests:
          - unique
          - not_null
      - name: customer_key
        description: 'Foreign key to dim_customers'
        tests:
          - not_null
          - relationships:
              to: ref('dim_customers')
              field: customer_key
      - name: revenue
        description: 'Total order revenue (sum of item prices)'
        tests:
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 100000
```

**Validation Commands:**

```bash
dbt run --select tag:marts
dbt test --select tag:marts
dbt test --select test_type:relationships
```

**Critical Rules:**

- Every fact MUST have clearly defined grain
- Every FK MUST have relationship test
- Use incremental materialization for facts with >100k rows
- Surrogate keys in dimensions, natural keys in facts
- Pre-calculate common metrics to reduce Power BI calc burden

---

### 6. Semantic Layer & Metrics Definition

**Business Metrics Framework:**

- Create semantic_models YAML files mapping marts to entities/dimensions/measures
- Define time spine for date-based aggregations
- Create metrics YAML files with business KPI definitions
- Implement simple metrics (sum, count, average)
- Implement ratio metrics (AOV = revenue / orders)
- Implement derived metrics (profit = revenue - cost)
- Implement cumulative metrics (rolling windows)
- Align metric definitions with business requirements doc
- Validate metrics via dbt sl query CLI
- Document metric business logic and ownership

**Key Deliverables:**

- [ ] `models/semantic_models/sem_orders.yml`
- [ ] `models/metrics/sales_metrics.yml`
- [ ] Metrics: total_revenue, total_orders, average_order_value, repeat_customer_rate
- [ ] Successful `dbt sl query` validation

**Semantic Model Example:**

```yaml
# models/semantic_models/sem_orders.yml

semantic_models:
  - name: orders
    model: ref('fct_orders')

    entities:
      - name: order
        type: primary
        expr: order_id
      - name: customer
        type: foreign
        expr: customer_key

    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day
        expr: order_purchase_date
      - name: order_status
        type: categorical

    measures:
      - name: revenue
        agg: sum
        expr: revenue
      - name: orders
        agg: count_distinct
        expr: order_id
      - name: freight_cost
        agg: sum
        expr: freight_cost
```

**Metrics Example:**

```yaml
# models/metrics/sales_metrics.yml

metrics:
  - name: total_revenue
    label: 'Total Revenue'
    description: 'Sum of order revenue for delivered orders'
    type: simple
    type_params:
      measure: revenue

  - name: total_orders
    label: 'Total Orders'
    description: 'Count of distinct delivered orders'
    type: simple
    type_params:
      measure: orders

  - name: average_order_value
    label: 'Average Order Value (AOV)'
    description: 'Total revenue divided by total orders'
    type: ratio
    type_params:
      numerator: total_revenue
      denominator: total_orders
```

**Validation Commands:**

```bash
dbt parse  # Validate YAML syntax
dbt sl query --metrics total_revenue --group-by order_date
dbt sl query --metrics average_order_value --group-by customer_state
```

---

### 7. Debugging & Performance Optimization

**Troubleshooting & Tuning:**

- Debug dbt compilation errors (Jinja, SQL syntax)
- Debug Snowflake execution errors (permissions, object not found)
- Optimize slow-running models (identify bottlenecks)
- Implement query optimization strategies (filtering, indexing)
- Tune Snowflake warehouse sizing for dbt runs
- Resolve test failures (data quality issues vs. test logic bugs)
- Fix dependency errors (circular refs, missing models)
- Troubleshoot CI/CD pipeline failures
- Review and enforce SQL best practices (no SELECT \*, explicit column lists)
- Implement cost optimization (incremental models, ephemeral intermediates)

**Common Issues & Solutions:**

| Error Type          | Symptom                    | Solution                                                |
| ------------------- | -------------------------- | ------------------------------------------------------- |
| Compilation Error   | `dbt compile` fails        | Check Jinja syntax, missing `{{ ref() }}`               |
| Object Not Found    | "Table does not exist"     | Verify source registered, run upstream models first     |
| Permission Denied   | "SQL access control error" | Grant SELECT to ANALYTICS_ROLE on RAW_DB                |
| Test Failure        | `unique` test fails        | Check for duplicate PKs in source data, add QUALIFY     |
| Circular Dependency | "Cycle detected"           | Review `{{ ref() }}` chain, break circular logic        |
| Slow Performance    | Model takes >5 minutes     | Add WHERE filter, use incremental, check warehouse size |

**Optimization Checklist:**

- [ ] Replace `SELECT *` with explicit column lists
- [ ] Use CTE pattern (with...as) for readability
- [ ] Add incremental materialization for facts >100k rows
- [ ] Use ephemeral for intermediate models <50k rows
- [ ] Cluster by date columns in fact tables
- [ ] Use QUALIFY instead of subqueries for deduplication
- [ ] Limit test runs with `--select` flag during development
- [ ] Use `dbt run --exclude tag:slow` to skip expensive models

**Validation Commands:**

```bash
dbt compile --select model_name  # Check SQL syntax
dbt run --select model_name --full-refresh  # Force rebuild
dbt test --select model_name --store-failures  # Debug test failures
dbt debug  # Check connection and config
```

---

## ✅ Phase 3 Validation Checklist

Before marking Phase 3 complete, verify all criteria below:

### Environment & Configuration

- [ ] `dbt debug` passes all checks
- [ ] `profiles.yml` uses environment variables for credentials
- [ ] `.gitignore` excludes sensitive files (venv/, target/, logs/)
- [ ] Git repository initialized with meaningful commit messages

### Source Layer

- [ ] All 8 raw tables registered in `src_olist.yml`
- [ ] Freshness checks configured (warn: 12h, error: 24h)
- [ ] `dbt source freshness` runs successfully
- [ ] Product category seed loaded with `dbt seed`

### Staging Layer

- [ ] 8 staging models created (stg_customers, stg_orders, etc.)
- [ ] All models use `{{ source() }}` function
- [ ] Zero JOIN statements in staging layer
- [ ] All columns renamed to snake_case
- [ ] Data types explicitly cast
- [ ] Generic tests applied (unique, not_null)
- [ ] Schema.yml documentation for all columns

### Intermediate Layer

- [ ] Business logic models created (int_orders_enriched, etc.)
- [ ] Grain documented in file header comments
- [ ] Join logic tested and validated
- [ ] Window functions used correctly (QUALIFY for dedup)
- [ ] Business rules from requirements implemented

### Marts Layer

- [ ] Dimension tables with surrogate keys (dim_customers, dim_products, dim_sellers, dim_dates)
- [ ] Fact tables with defined grain (fct_orders, fct_payments)
- [ ] Relationship tests validate all FK → PK integrity
- [ ] Incremental materialization configured for large facts
- [ ] Star schema aligns with business requirements

### Semantic Layer

- [ ] Semantic models defined for key marts
- [ ] Metrics defined for all primary KPIs from requirements
- [ ] `dbt sl query` validation successful
- [ ] Metric descriptions business-friendly

### Data Quality

- [ ] All primary keys have unique + not_null tests
- [ ] All foreign keys have relationship tests
- [ ] Singular tests for complex business rules
- [ ] `dbt test` passes with 0 failures
- [ ] Test coverage >80% of columns

### Documentation

- [ ] Every model has description in schema.yml
- [ ] Every column has description
- [ ] `dbt docs generate` runs successfully
- [ ] Lineage graph shows clear flow: sources → staging → intermediate → marts

### Performance

- [ ] No models take >5 minutes to run
- [ ] Incremental models use appropriate unique_key
- [ ] Warehouse auto-suspend configured to 60 seconds
- [ ] Query tags added to track costs

---

## 🚦 Success Criteria

Phase 3 is complete when:

1. **Data Pipeline Functional:** `dbt build` runs end-to-end without errors
2. **Data Quality Validated:** All tests pass, 0 critical issues
3. **Star Schema Implemented:** Fact and dimension tables ready for Power BI
4. **Business Logic Encoded:** All business rules from requirements doc implemented
5. **Documentation Complete:** Every model and column documented
6. **Performance Optimized:** Models run efficiently (<5 min total runtime)
7. **Semantic Layer Defined:** Key business metrics defined and queryable

---

## 📊 Expected Deliverables

### Code Artifacts

- [ ] `models/staging/olist/` folder with 8 stg\_\*.sql files
- [ ] `models/intermediate/` folder with int\_\*.sql files
- [ ] `models/marts/core/` folder with dim*\*.sql and fct*\*.sql files
- [ ] `models/semantic_models/` folder with semantic model YAMLs
- [ ] `models/metrics/` folder with business metric definitions
- [ ] `tests/` folder with singular test SQL files
- [ ] `macros/` folder with custom reusable logic (if needed)
- [ ] `seeds/` folder with product_category_name_translation.csv

### Configuration Files

- [ ] `dbt_project.yml` with layer-specific configs
- [ ] `profiles.yml` with dev/prod targets
- [ ] `packages.yml` with dbt_utils, dbt_expectations
- [ ] `.gitignore` with security exclusions

### Documentation

- [ ] `schema.yml` files for each layer with descriptions
- [ ] Generated dbt docs site (target/index.html)
- [ ] README.md with setup instructions
- [ ] Business logic documentation for complex transformations

### Quality Assurance

- [ ] Test suite with >50 generic tests
- [ ] Singular tests for business rule validation
- [ ] Relationship tests for all FK constraints
- [ ] Freshness checks on all sources

---

## 🎯 Alignment with Business Requirements

Every transformation must tie back to business questions from Phase 1:

| Business Question                     | dbt Deliverable                                       |
| ------------------------------------- | ----------------------------------------------------- |
| Q1: Revenue & order trends over time? | fct_orders with order_purchase_date, dim_dates        |
| Q2: Top product categories?           | fct_orders joined to dim_products with category       |
| Q3: Regional performance?             | fct_orders joined to dim_customers with state/city    |
| Q4: Delivery efficiency?              | fct_orders with actual_delivery_days, is_delayed flag |
| Q5: Top sellers?                      | fct_orders joined to dim_sellers                      |
| Q6: Payment method analysis?          | fct_payments with payment_type, installments          |
| Q7: Repeat vs. new customers?         | dim_customers with customer_segment, lifetime_orders  |

---

## 🚨 Critical Guardrails (DO NOT VIOLATE)

1. **NEVER commit credentials to Git** - Use environment variables
2. **NEVER use SELECT \* in marts** - Explicit column selection only
3. **NEVER join in staging layer** - Staging is 1-to-1 with sources
4. **NEVER skip testing** - Every PK/FK must have tests
5. **NEVER hardcode table names** - Always use `{{ ref() }}` or `{{ source() }}`
6. **NEVER deploy to prod without testing** - Run `dbt test` locally first
7. **ALWAYS document grain** - Every fact table must have grain comment
8. **ALWAYS use CTE pattern** - Import CTEs at top of every model
9. **ALWAYS run `dbt source freshness` first** - Don't transform stale data
10. **ALWAYS commit with meaningful messages** - Explain what and why

---

## 🔄 Standard Workflow

### Daily Development Cycle

```bash
# 1. Start fresh
git checkout -b feature/new-model
dbt clean

# 2. Check data freshness
dbt source freshness

# 3. Build incrementally
dbt run --select model_name+  # Run model and downstream
dbt test --select model_name  # Test the model

# 4. Review compiled SQL
cat target/compiled/olist_dbt/models/.../model_name.sql

# 5. Document as you go
# Add descriptions to schema.yml

# 6. Commit often
git add models/
git commit -m "feat: add dim_customers with segmentation logic"

# 7. Before PR: run full suite
dbt build --select tag:staging tag:intermediate tag:marts
dbt test

# 8. Push and create PR
git push origin feature/new-model
```

### Debugging Workflow

```bash
# Compilation error?
dbt compile --select model_name

# Execution error?
dbt run --select model_name --full-refresh --debug

# Test failure?
dbt test --select model_name --store-failures
# Then query: select * from dbt_test__audit.test_failure_table

# Performance issue?
dbt run --select model_name --profiles-dir ~/.dbt --vars '{warehouse_size: LARGE}'
```

---

## 📞 How to Work with Analytics_Engineer Agent

**Invoke Pattern:**
Simply describe your Phase 3 task clearly. The agent automatically applies the appropriate competency based on context.

**Example Prompts:**

| Task Category    | Example Prompt                                                                    |
| ---------------- | --------------------------------------------------------------------------------- |
| **Setup**        | "Set up dbt project for Olist with Snowflake connection and folder structure"     |
| **Sources**      | "Register all 8 Olist raw tables with freshness checks and document them"         |
| **Staging**      | "Create stg_customers model with standardization, casting, and tests"             |
| **Intermediate** | "Build int_orders_enriched joining orders, items, payments with delivery metrics" |
| **Marts**        | "Create dim_customers with segmentation, surrogate keys, and relationship tests"  |
| **Metrics**      | "Define total_revenue, total_orders, and average_order_value metrics"             |
| **Debug**        | "Why is my unique test failing on order_id in fct_orders?"                        |
| **Optimize**     | "Optimize slow-running fct_orders model - currently takes 8 minutes"              |

**Context Requirements:**
When asking for help, provide:

1. **What layer** you're working on (staging/intermediate/marts)
2. **What tables** are involved (stg_orders, dim_customers)
3. **What error** you're seeing (if debugging)
4. **What business logic** should be applied (if transforming)

---

## 🎓 Learning Resources

- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Snowflake Optimization](https://docs.snowflake.com/en/user-guide/performance-optimization)
- [Star Schema Design](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/)
- [dbt Semantic Layer](https://docs.getdbt.com/docs/build/semantic-models)

---

## 📝 Version History

| Version | Date         | Changes                                    |
| ------- | ------------ | ------------------------------------------ |
| 1.0     | Dec 29, 2025 | Initial Phase 3 agent instructions created |

---

**Next Phase:** Phase 4 - Power BI Semantic Model & Dashboard Development

**Status:** Ready to execute Phase 3 transformations
