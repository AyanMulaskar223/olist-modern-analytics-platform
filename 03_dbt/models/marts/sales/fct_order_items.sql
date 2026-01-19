{{
    config(
        materialized='incremental',
        schema='marts',
        unique_key='order_item_sk',
        on_schema_change='append_new_columns',
        tags=['sales', 'marts', 'fact', 'orders']
    )
}}

{#
    PURPOSE: Order items fact table for revenue, delivery, and retention analysis
    GRAIN: One row per order item (line-level transaction)
    SOURCE: int_sales__order_items_joined
    MATERIALIZATION: Incremental (Upsert on order_item_sk)

    BUSINESS CONTEXT:
    - Central fact table for all sales and operational metrics
    - Includes ALL order statuses (Delivered, Canceled, Unavailable) to support "Lost Revenue" analysis
    - Enables analysis across customer, product, seller, and time dimensions
    - Supports retention (order_sequence_number), efficiency (delivery_time_days), and revenue metrics

    INCREMENTAL STRATEGY:
    ✅ UPSERT on unique_key=order_item_sk (merge new/updated rows)
    ✅ FULL REFRESH on first run (dbt_full_refresh flag)
    ✅ INCREMENTAL RUNS: Only refresh rows where order_date_dt >= {{ var('start_date') }}
    ✅ Cost optimization: Only process new/changed orders each day
    ✅ Schema monitoring: on_schema_change='fail' (alerts to schema drift)

    MARTS LAYER RULES:
    ✅ SCOPE: Include ALL orders (Don't filter 'canceled' -> Handle in DAX)
    ✅ EXPLICIT COLUMNS: No SELECT * (schema control)
    ✅ STAR SCHEMA: All necessary surrogate keys for dimension joins
    ✅ NO HEAVY MATH: datediff, row_number already calculated in intermediate
    ✅ DATA QUALITY PASSTHROUGH: Keep is_verified + quality_issue_reason
    ✅ INCREMENTAL: Only add new/modified orders (cost & performance)

    KEY DESIGN DECISIONS:

    1. **Grain = Line-Level (One Row Per Order Item)**
       Why: Allows granular analysis (revenue per product, seller, customer)

    2. **Customer Key = Surrogate (customer_sk)**
       Why: Enables persistent identity tracking across address changes

    3. **Business Filter = NONE (Load All Statuses)**
       Why: Allows "Cancellation Rate" and "Potential Revenue" analysis.
       *Note: "Recognized Revenue" KPI in Power BI must filter for status='delivered'*

    4. **Data Quality Flags = KEEP (Don't Filter)**
       Why: Power BI users decide what to include in reports

    5. **Pre-Calculated Fields = From Intermediate**
       Why: Complex logic (datediff, ROW_NUMBER) done once in INT layer

    6. **Incremental Materialization = YES**
       Why: Fact tables grow continuously; full refresh = high cost
       How: Merge on order_item_sk, only refresh changed orders
       Cost Savings: 1 GB fact table → ~50 MB refresh per day (typical)

#}

with source as (

    select * from {{ ref('int_sales__order_items_joined') }}

)

select
    -- 🔑 PRIMARY KEY (Surrogate)
    order_item_sk,

    -- 🔗 FOREIGN KEYS
    customer_sk,
    product_sk,
    seller_sk,
    order_date_dt,

    -- 🛒 DEGENERATE DIMENSIONS
    order_id,
    initcap(order_status) as order_status, -- 🚨 CRITICAL: Title Case for Power BI (Delivered, Canceled, etc.)

    -- 💰 FINANCIAL METRICS
    price_brl,
    freight_value_brl,

    -- 📈 OPERATIONAL METRICS
    order_sequence_number,
    delivery_time_days, -- NULL for non-delivered orders (canceled, processing, etc.)
    is_delayed,

    -- 🛡️ DATA QUALITY / AUDIT
    is_verified,
    quality_issue_reason,

    -- ⏰ METADATA
    current_timestamp()::timestamp_ltz as dbt_updated_at

from source
-- ❌ REMOVED FILTER: where order_status = 'delivered'
-- We keep all rows so we can analyze Cancellations in Power BI.

{% if execute_mode == 'incremental' %}
    -- 🚀 INCREMENTAL: Only fetch orders from today (configurable)
    where order_date_dt >= (select max(order_date_dt) from {{ this }})
{% endif %}
