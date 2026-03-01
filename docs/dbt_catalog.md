---
title: dbt Data Catalog
description: Interactive dbt docs — model lineage, column definitions, and 282 automated tests across 22 models and 8 sources.
---

# :material-book-open-page-variant: dbt Data Catalog

<div class="grid cards" markdown>

-   :material-layers-triple:{ .lg .middle } **Medallion Architecture**

    ---

    RAW → Staging → Intermediate → Marts — every transformation fully documented and tested.

-   :material-graph:{ .lg .middle } **22 Models**

    ---

    9 staging views · 4 intermediate tables · 1 fact table · 5 dimensions · 3 seeds

-   :material-test-tube:{ .lg .middle } **282 Automated Tests**

    ---

    `not_null` · `unique` · `relationships` · `accepted_values` · singular business-rule assertions

-   :material-database-arrow-right:{ .lg .middle } **8 Source Tables**

    ---

    1.55M raw rows ingested from Azure Blob Storage via Snowflake `COPY INTO`

</div>

---

<div class="dbt-docs-header" markdown>

[:material-open-in-new: Open in Full Screen](https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/){ .md-button .md-button--primary target="_blank" }
[:material-graph-outline: Explore Lineage DAG](https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/#!/overview?g_v=1){ .md-button target="_blank" }

</div>

<div class="dbt-docs-embed">
  <iframe
    src="https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/"
    title="dbt Data Catalog"
    allowfullscreen
  ></iframe>
</div>

---

## :material-layers-outline: Model Inventory

=== ":material-eye-outline: Staging"

    Light-touch cleaning only — **1:1 with RAW tables**, no business logic applied.

    | Model | Source Table | Key Transforms |
    |:------|:-------------|:---------------|
    | `stg_olist__orders` | `raw_orders` | UPPER status, cast timestamps |
    | `stg_olist__order_items` | `raw_order_items` | Rename columns, cast decimals |
    | `stg_olist__customers` | `raw_customers` | Standardise state codes |
    | `stg_olist__products` | `raw_products` | Cast weight/dimensions |
    | `stg_olist__sellers` | `raw_sellers` | Standardise state codes |
    | `stg_olist__payments` | `raw_payments` | Cast amounts, validate types |
    | `stg_olist__reviews` | `raw_reviews` | Deduplicate, cast timestamps |
    | `stg_olist__geolocation` | `raw_geolocation` | Cast lat/long coordinates |
    | `stg_olist__category_translations` | `raw_category_names` | EN/PT name mapping |

    **Materialization:** `view` — zero storage cost · **Schema:** `STAGING`

=== ":material-cog-outline: Intermediate"

    Business logic, joins, and aggregations — **reusable building blocks** for marts.

    | Model | Purpose |
    |:------|:--------|
    | `int_sales__order_items_joined` | Joins orders + items; adds DQ flags (`is_valid`, `is_delayed`) |
    | `int_products__enriched` | Adds `is_verified` flag, fills missing category translations |
    | `int_customers__prep` | Computes `is_repeat_customer` (≥ 2 delivered orders) |
    | `int_order_reviews` | Deduplicates reviews to one row per order via `MIN(review_score)` |

    **Materialization:** `table` · **Schema:** `INTERMEDIATE`

=== ":material-star-outline: Marts"

    **Star schema (Kimball)** — production-ready for Power BI and SQL consumers.

    **Fact Table**

    | Model | Grain | Rows | Materialization |
    |:------|:------|:-----|:----------------|
    | `fct_order_items` | One row per delivered order line item | ~112K | `incremental` |

    **Dimension Tables**

    | Model | Description | Materialization |
    |:------|:------------|:----------------|
    | `dim_customers` | Customer attributes + `is_repeat_customer` flag | `table` |
    | `dim_products` | Product catalog + English category translations | `table` |
    | `dim_sellers` | Seller attributes + state geography | `table` |
    | `dim_date` | Full calendar spine (2016–2018) with fiscal periods | `table` |
    | `dim_rls_bridge` | Row-level security bridge — state → role mapping | `table` |

    **Schema:** `MARTS` · **Database:** `OLIST_ANALYTICS_DB`

---

## :material-magnify: Key Models to Explore

<div class="grid cards" markdown>

-   :material-table-star:{ .lg .middle } **`fct_order_items`**

    ---

    Core fact table. Grain: one row per delivered order line item. Pre-calculated measures: `order_total`, `freight_value`, `is_delayed`, `days_to_deliver`. Joins to all 5 dimensions.

    [:material-open-in-new: View in catalog](https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/#!/model/model.olist_analytics.fct_order_items){ target="_blank" }

-   :material-account-group:{ .lg .middle } **`dim_customers`**

    ---

    Customer dimension with `customer_unique_id` for cross-order identity resolution. Includes `is_repeat_customer` flag (≥ 2 delivered orders).

    [:material-open-in-new: View in catalog](https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/#!/model/model.olist_analytics.dim_customers){ target="_blank" }

-   :material-package-variant:{ .lg .middle } **`dim_products`**

    ---

    Product catalog enriched with English category translations. Includes `is_verified` quality flag for products with complete dimensions and photos.

    [:material-open-in-new: View in catalog](https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/#!/model/model.olist_analytics.dim_products){ target="_blank" }

-   :material-calendar:{ .lg .middle } **`dim_date`**

    ---

    Full calendar spine covering 2016–2018. Includes day-of-week, week, month, quarter, and year columns for Power BI time intelligence.

    [:material-open-in-new: View in catalog](https://ayanmulaskar223.github.io/ecommerce-logistics-diagnostics/#!/model/model.olist_analytics.dim_date){ target="_blank" }

</div>

---

!!! tip "Navigating the Lineage DAG"
    In the catalog, click any model name → then click **"See Lineage"** to see its full upstream/downstream dependency graph. Use `+model_name` syntax in the search to select a model with all its parents highlighted.
