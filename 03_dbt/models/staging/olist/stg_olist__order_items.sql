{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'order_items']
    )
}}

{#
    PURPOSE: Clean and standardize raw_order_items from Phase 2
    GRAIN: One row per line item per order (order_id + order_item_id)
    SOURCE: raw_order_items (Parquet format, 112,650 rows)

    BUSINESS CONTEXT:
    - Represents individual products sold within an order
    - Same order_id can have multiple line items (1-to-many)

    ADLC COMPLIANCE:
    ✅ Import CTE pattern
    ✅ Explicit type casting
    ✅ Surrogate key generation
    ✅ No JOINs (staging rule)
    ✅ No GROUP BY (preserves grain)
    ✅ No business filtering (no WHERE on business data)

    DATA QUALITY (from Phase 2 validation):
    - 0 NULL values in any column
    - 0 duplicate PKs (order_id + order_item_id)
    - 0 orphaned records (all FKs valid)
    - 0 negative prices/freight
    - 1,966 price outliers + 2,041 freight outliers (NOT filtered - documented only)
#}

-- ============================================================================
-- STEP 1: IMPORT CTE
-- WHY: Separates dependency definition from transformation logic.
--      Makes it easy to swap sources (e.g., for testing with mock data).
--      dbt can trace lineage through source() function references.
-- ============================================================================
with source as (
    select * from {{ source('olist', 'raw_order_items') }}
),
-- ============================================================================
-- STEP 2: RENAMED & TYPED
-- WHY:
--   1. Explicit casting prevents implicit type coercion bugs
--   2. snake_case naming ensures consistency across all models
--   3. Prefixed IDs (order_id vs id) prevent ambiguity in downstream JOINs
--   4. Numeric precision (10,2) matches business requirements (BRL currency)
-- ============================================================================
renamed as (

    select
        -- 🔑 SURROGATE KEY (Primary Key)
        -- Composite natural key (order_id + order_item_id) hashed for uniqueness
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_sk,

        -- 🔑 FOREIGN KEYS (Hashed for Star Schema Joins)
        -- These enable joins to dim_orders, dim_products, and dim_sellers
        {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_sk,
        {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_sk,
        {{ dbt_utils.generate_surrogate_key(['seller_id']) }} as seller_sk,

        -- 🔗 NATURAL KEYS (Preserved for business context)
        trim(order_id)::varchar(32) as order_id,
        order_item_id::integer as order_item_sequence_id, -- Renamed for clarity (1, 2, 3...)

        -- 🔗 FK NATURAL KEYS
        trim(product_id)::varchar(32) as product_id,
        trim(seller_id)::varchar(32) as seller_id,

        -- 💰 MONETARY VALUES (Financial Precision)
        -- Casting to NUMERIC(10,2) to match currency requirements (BRL)
        price::numeric(10, 2) as item_price_brl,
        freight_value::numeric(10, 2) as item_freight_brl,

        -- 📝 AUDIT COLUMNS
        _source_file::varchar as source_file,
        _loaded_at::timestamp_ntz as source_loaded_at_utc

    from source

)

select * from renamed
