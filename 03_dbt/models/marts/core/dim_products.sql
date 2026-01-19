{{
    config(
        materialized='table',
        schema='marts',
        tags=['products', 'marts', 'core', 'dimension']
    )
}}

{#
    PURPOSE: Product dimension table for product attributes and category analysis
    GRAIN: One row per unique product (product_id)
    SOURCE: int_products__enriched

    BUSINESS CONTEXT:
    - Provides the product master data for all analytics
    - Each product_sk represents a unique product SKU
    - Category includes English translations for international audience
    - Ready for Power BI relationship: product_sk → fct_order_items

    MARTS LAYER RULES:
    ✅ Star Schema dimension (conformed across all facts)
    ✅ Business-friendly column names (product_category not category_name)
    ✅ Explicit column selection (no SELECT *)
    ✅ Table materialization for fast Power BI queries
    ✅ No complex transformations (logic handled in intermediate)
    ✅ Data quality flags preserved (NOT filtered out)

#}

with products as (

    select * from {{ ref('int_products__enriched') }}

)

select
    -- 🔑 PRIMARY KEY (Surrogate)
    -- Used for Power BI relationships to fact tables
    product_sk,

    -- 🔗 NATURAL KEY (Business Key)
    -- Preserved for debugging and data lineage
    product_id,

    -- 📦 PRODUCT ATTRIBUTES
    -- Business-friendly column names for Power BI
    category_name as product_category,
    category_name_pt as product_category_original,

    -- 🛡️ DATA QUALITY / AUDIT
    -- Quality flags for filtering and diagnostics
    is_verified,
    quality_issue_reason,

    -- ⏰ METADATA
    current_timestamp()::timestamp_ltz as dbt_updated_at

from products
