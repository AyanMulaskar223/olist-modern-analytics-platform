# 📚 Data Dictionary — dbt MARTS Layer

![Layer](https://img.shields.io/badge/Layer-dbt%20MARTS-1E40AF?style=for-the-badge)
![Pattern](https://img.shields.io/badge/Model-Kimball%20Star%20Schema-EA580C?style=for-the-badge)
![Models](https://img.shields.io/badge/Models-8%20MARTS-0EA5E9?style=for-the-badge)
![Status](https://img.shields.io/badge/Contracts-Enforced-16A34A?style=for-the-badge)

!!! warning "Portfolio Scenario — MARTS Dictionary"
This dictionary documents the dbt MARTS layer for a simulated Digital Transformation portfolio implementation. Definitions are aligned to current dbt model SQL/YAML and intended for governance, handoff, and auditability.

---

## 1. Purpose & Scope

This document is the canonical reference for MARTS-layer structure and semantics.

It defines:

- Fact and dimension responsibilities
- Grain for each MARTS model
- Business rules embedded in SQL transformations
- Source-to-target lineage from INT/STG/SEED to MARTS
- Relationship and key strategy for BI consumption

Scope includes these dbt models:

- `marts.sales.fct_order_items`
- `marts.core.dim_customers`
- `marts.core.dim_products`
- `marts.core.dim_sellers`
- `marts.core.dim_date`
- `marts.core.dim_rls_bridge`
- `security.dim_security_rls`
- `marts.meta.meta_project_status`

---

## 2. Modeling Philosophy (Kimball Approach)

The MARTS layer follows Kimball dimensional modeling:

- One central transactional fact (`fct_order_items`)
- Conformed dimensions reused across analyses
- Explicit surrogate key joins for BI consistency
- “Flag, don’t filter” for data quality transparency

Design decisions applied in this project:

- Keep all order statuses in fact table; metric filtering is handled in semantic/DAX layer.
- Preserve diagnostic flags (`is_verified`, `quality_issue_reason`) instead of removing rows.
- Keep marts SQL simple (heavy transformations done upstream in INTERMEDIATE).

**Visual Reference: dbt Lineage (RAW → STAGING → INTERMEDIATE → MARTS)**

![dbt Lineage DAG](screenshots/03_dbt/lineage_dag.png)

_Figure 1: Complete data transformation lineage showing the star schema pattern with `fct_order_items` as the central fact table and conformed dimensions._

---

## 3. Fact Tables

### 3.1 `fct_order_items`

**Purpose:** Central fact for revenue, order, delivery, retention, and quality reporting.

**Model config (dbt):**

- Materialization: `incremental`
- Unique key: `order_item_sk`
- Schema: `marts`
- On-schema-change: `append_new_columns`

**Business notes:**

- Includes delivered + non-delivered statuses for full funnel analysis.
- Supports recognized revenue and lost revenue patterns downstream.

> **See also:** [Section 5 (Table Grain Definitions)](#5-table-grain-definitions) for explicit grain specification and [Section 8 (Source-to-Target Mapping)](#8-source-to-target-mapping) for upstream lineage.

**Visual Reference: Incremental Materialization Strategy**

![Incremental Model Configuration](screenshots/03_dbt/incremental_model.png)

_Figure 2: Incremental model configuration in dbt showing `unique_key` strategy and on-schema-change behavior for the fact table._

---

## 4. Dimension Tables

> **See also:** [Section 10 (Surrogate Keys & Relationships)](#10-surrogate-keys-relationships) for relationship mappings to the fact table.

### 4.1 `dim_customers`

- Purpose: customer master for segmentation and retention
- Key fields: `customer_sk`, `customer_unique_id`, location attributes

### 4.2 `dim_products`

- Purpose: product catalog with translated category and quality signals
- Key fields: `product_sk`, `product_id`, `product_category`, quality attributes

### 4.3 `dim_sellers`

- Purpose: seller master and geography for performance + security propagation
- Key fields: `seller_sk`, `seller_id`, `seller_state_code`, `seller_city`

### 4.4 `dim_date`

- Purpose: conformed calendar for time-series analysis
- Key fields: `date_day`, year/quarter/month/day attributes, weekend flag

### 4.5 `dim_security_rls`

- Purpose: user-to-access mapping for row-level security entry point
- Key fields: `user_email`, `access_key`, `access_level`

### 4.6 `dim_rls_bridge`

- Purpose: translates `access_key` to `seller_state_code` for filter propagation
- Key fields: `access_key`, `seller_state_code`

### 4.7 `meta_project_status`

- Purpose: pipeline and business data freshness metadata
- Key fields: `pipeline_last_run_at`, `data_valid_through`

---

## 5. Table Grain Definitions

| Model                 | Grain                                                |
| --------------------- | ---------------------------------------------------- |
| `fct_order_items`     | One row per order item (line-level transaction)      |
| `dim_customers`       | One row per unique customer (`customer_sk`)          |
| `dim_products`        | One row per unique product (`product_id`)            |
| `dim_sellers`         | One row per unique seller (`seller_id`)              |
| `dim_date`            | One row per calendar day                             |
| `dim_security_rls`    | One row per (`user_email`, `access_key`) pair        |
| `dim_rls_bridge`      | One row per (`access_key`, `seller_state_code`) pair |
| `meta_project_status` | Singleton (one row)                                  |

---

## 6. Column-Level Definitions

### 6.1 `fct_order_items` (selected columns)

| Column                  | Type            | Definition                          | Rule                               |
| ----------------------- | --------------- | ----------------------------------- | ---------------------------------- |
| `order_item_sk`         | `varchar`       | Surrogate PK for line item          | Unique, not null                   |
| `customer_sk`           | `varchar`       | FK to customer dimension            | Must map to `dim_customers`        |
| `product_sk`            | `varchar`       | FK to product dimension             | Must map to `dim_products`         |
| `seller_sk`             | `varchar`       | FK to seller dimension              | Must map to `dim_sellers`          |
| `order_date_dt`         | `date`          | Order date key                      | Must map to `dim_date.date_day`    |
| `order_id`              | `varchar`       | Natural order key                   | Used for distinct-order metrics    |
| `order_status`          | `varchar`       | Standardized order status (InitCap) | Includes delivered/canceled/etc    |
| `price_brl`             | `numeric(10,2)` | Line-item price in BRL              | Must be `>= 0` (warn threshold)    |
| `freight_value_brl`     | `numeric(10,2)` | Freight value in BRL                | Must be `>= 0` (warn threshold)    |
| `order_sequence_number` | `integer`       | Customer order sequence             | Must be `>= 1`                     |
| `delivery_time_days`    | `integer`       | Delivery duration days              | Nullable for non-delivered orders  |
| `is_delayed`            | `integer`       | Delivery delay flag                 | Accepted values: `0/1`             |
| `is_verified`           | `integer`       | Master quality flag                 | Accepted values: `0/1`             |
| `quality_issue_reason`  | `varchar`       | Quality diagnostic reason           | Populated when quality checks fail |

### 6.2 Core dimensions (selected columns)

| Table           | Column                      | Definition                  |
| --------------- | --------------------------- | --------------------------- |
| `dim_customers` | `customer_sk`               | Surrogate customer key      |
| `dim_customers` | `customer_state_code`       | 2-letter BR state code      |
| `dim_products`  | `product_category`          | English category name       |
| `dim_products`  | `product_category_original` | Portuguese source category  |
| `dim_sellers`   | `seller_state_code`         | RLS target geography code   |
| `dim_date`      | `year_month_number`         | Numeric sort key (`YYYYMM`) |
| `dim_date`      | `is_weekend`                | Weekend indicator (1/0)     |

---

## 7. Business Rules Embedded in Transformations

Rules implemented in MARTS SQL contracts:

- `fct_order_items` keeps all order statuses; no hard delivered-only filter in marts.
- `order_status` is normalized to title case (`initcap`).
- Data-quality attributes are preserved, not dropped.
- Incremental loads refresh by latest `order_date_dt` boundary.

Rules enforced through tests/contracts (YAML):

- Key uniqueness and not-null constraints
- FK relationship checks to dimensions
- Accepted value checks (statuses, binary flags, state codes)
- Numeric range checks for financial and operational metrics

**Visual Reference: dbt Test Suite Results**

![Test Suite Passed](screenshots/03_dbt/test_passed_suite.png)

_Figure 3: Comprehensive test coverage with 100% pass rate across generic and singular tests for data quality validation._

---

## 8. Source-to-Target Mapping

> **Reference:** See [Section 2 (Modeling Philosophy)](#2-modeling-philosophy-kimball-approach) for transformation layer responsibilities.

| MARTS Model           | Upstream Source                   | Mapping Notes                                         |
| --------------------- | --------------------------------- | ----------------------------------------------------- |
| `fct_order_items`     | `int_sales__order_items_joined`   | Pass-through of precomputed metrics and quality flags |
| `dim_customers`       | `int_customers__prep`             | Uses deduplicated customer identity                   |
| `dim_products`        | `int_products__enriched`          | Uses translated categories + quality fields           |
| `dim_sellers`         | `stg_olist__sellers`              | Standardized seller geography                         |
| `dim_date`            | dbt-generated date spine          | Generated `2016-01-01` to `2018-12-31`                |
| `dim_security_rls`    | `seed.security_rls_mapping`       | User access mapping seed                              |
| `dim_rls_bridge`      | `seed.security_rls_mapping`       | Distinct access key bridge                            |
| `meta_project_status` | `fct_order_items` + runtime clock | Pipeline and business “two clocks”                    |

**Visual Reference: dbt Documentation Site**

![dbt Docs Site](screenshots/03_dbt/dbt_docs_site.png)

#### Figure 4: Auto-generated dbt documentation site showing complete model catalog, lineage visualization, and column-level descriptions for all MARTS models.

## 9. Data Types & Naming Standards

Naming standards:

- Fact tables: prefix `fct_`
- Dimensions: prefix `dim_`
- Metadata/ops: prefix `meta_`
- Surrogate keys: suffix `_sk`
- State code attributes: suffix `_state_code`
- Timestamps: suffix `_at`

Data type standards:

- Keys: `varchar`
- Money: `numeric(10,2)`
- Flags: integer `0/1` in marts (cast to boolean in semantic layer where needed)
- Dates: `date`
- Datetimes/audit: `timestamp_ltz` (project uses `timestamp_lptz` in `dim_security_rls` implementation)

---

## 10. Surrogate Keys & Relationships

Primary surrogate keys:

- `fct_order_items.order_item_sk`
- `dim_customers.customer_sk`
- `dim_products.product_sk`
- `dim_sellers.seller_sk`
- `dim_date.date_day` (date PK)

Core star-schema relationships:

- `fct_order_items.customer_sk` → `dim_customers.customer_sk`
- `fct_order_items.product_sk` → `dim_products.product_sk`
- `fct_order_items.seller_sk` → `dim_sellers.seller_sk`
- `fct_order_items.order_date_dt` → `dim_date.date_day`

RLS relationship pattern:

- `dim_security_rls.access_key` → `dim_rls_bridge.access_key`
- `dim_rls_bridge.seller_state_code` → `dim_sellers.seller_state_code`

---

## 11. Audit & Metadata Columns

Standard audit pattern:

- Most marts models include `dbt_updated_at` as load/process timestamp.

Operational metadata table:

- `meta_project_status.pipeline_last_run_at`: pipeline execution timestamp.
- `meta_project_status.data_valid_through`: latest business date in fact (`max(order_date_dt)`).

Purpose:

- Freshness monitoring
- Dashboard footer/system status
- Audit and incident triage support

---

## 12. Change Management & Schema Evolution

> **See also:** [Section 7 (Business Rules)](#7-business-rules-embedded-in-transformations) for contract enforcement through tests.

Current controls:

- dbt model contracts (`contract.enforced: true`) in marts schemas
- Explicit column selection in SQL (no uncontrolled `SELECT *` in marts outputs)
- Incremental strategy with stable unique key for facts
- Pull-request workflow and versioned SQL/YAML assets

Schema evolution policy:

- Additive column changes are preferred.
- Breaking changes require model + YAML updates together.
- Downstream semantic model must validate renamed/removed fields before release.

**Visual Reference: dbt Model Contracts**

![Data Contracts Enforcement](screenshots/03_dbt/data_contracts.png)

_Figure 5: Schema contracts enforced at MARTS layer ensuring column-level type safety and preventing breaking changes from upstream models._

---

## 13. Data Ownership & Stewardship

| Domain               | Primary Owner                    | Stewardship Responsibility                      |
| -------------------- | -------------------------------- | ----------------------------------------------- |
| Snowflake MARTS      | Analytics Engineering            | Model design, contracts, performance            |
| Security mappings    | DataOps / Platform Admin         | Seed maintenance, access governance             |
| Semantic consumption | BI / Analytics Developer         | Measure layer, report behavior, RLS role wiring |
| KPI definitions      | Finance + Operations + Analytics | Business-rule signoff and change control        |

---

## 14. Limitations & Assumptions

Current limitations:

- Date mart range is fixed to dataset window (`2016-01-01` to `2018-12-31`).
- `fct_order_items` uses order date as date key; delivery-date role-playing is a semantic-layer extension.
- Some performance/quality values are operationally monitored outside this dictionary.

Assumptions:

- Upstream INT models remain the source of complex business logic.
- Seed `security_rls_mapping` is maintained as authoritative mapping input.
- BI layer applies final KPI filters (for example delivered-only revenue) where business requires.

---

## 15. Semantic Model Integration (Added)

> **Reference:** [Section 10 (Surrogate Keys & Relationships)](#10-surrogate-keys-relationships) defines the star schema relationships that Power BI implements.

Why this section exists:

- MARTS contracts are only useful if semantic model mappings stay aligned.

Alignment checkpoints:

- `marts.fct_order_items` maps to semantic table `Sales`.
- Surrogate relationships remain 1:\* from dimensions to fact.
- Quality flags (`is_verified`, `quality_issue_reason`) are exposed for verified vs at-risk measures.
- Security chain (`dim_security_rls` + `dim_rls_bridge` + `dim_sellers`) supports dynamic RLS in Power BI.

Release checklist before publish:

1. `dbt build --select marts` passes.
2. Contract/test failures are zero or accepted with documented exceptions.
3. Semantic model refresh validates all mapped columns.
4. KPI regression checks pass for core measures (`Total Revenue`, `Total Orders`, `AOV`, quality metrics).

**Visual Reference: MARTS-to-Semantic Model Relationships**

![Power BI Semantic Model Relationships](screenshots/04_powerbi/lineage_graph_view.png)

_Figure 6: Star schema relationship graph in Power BI showing one-to-many relationships from dimensions to the central `Sales` fact table (mapped from `fct_order_items`)._

**Visual Reference: Power BI Semantic Model Structure**

![Power BI Semantic Model](screenshots/04_powerbi/semantic_model.png)

_Figure 7: Complete semantic model structure in Power BI showing all imported MARTS tables, calculated measures, and field hierarchies ready for dashboard consumption._
