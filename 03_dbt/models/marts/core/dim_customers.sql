{{
    config(
        materialized='table',
        schema='marts',
        tags=['customers', 'marts', 'core', 'dimension']
    )
}}

{#
    PURPOSE: Customer dimension table for customer profile and segmentation analysis
    GRAIN: One row per unique customer (person)
    SOURCE: int_customers__prep

    BUSINESS CONTEXT:
    - Provides the customer master data for all analytics
    - Each customer_sk represents a unique person (not per-order)
    - Location reflects the most recent known address
    - Ready for Power BI relationship: customer_sk → fct_order_items

    MARTS LAYER RULES:
    ✅ Star Schema dimension (conformed across all facts)
    ✅ Business-friendly column names (customer_city not city)
    ✅ Explicit column selection (no SELECT *)
    ✅ Table materialization for fast Power BI queries
    ✅ No complex transformations (logic handled in intermediate)


#}

with customers as (

    select * from {{ ref('int_customers__prep') }}

)

select
    -- 🔑 PRIMARY KEY (Surrogate)
    -- Used for Power BI relationships to fact tables
    customer_sk,

    -- 🔗 NATURAL KEY (Business Key)
    -- Preserved for debugging and data lineage
    customer_unique_id,

    -- 📍 LOCATION ATTRIBUTES
    -- Business-friendly column names for Power BI
    customer_city,
    customer_state as customer_state_code,

    -- 🛡️ DATA QUALITY / AUDIT
    current_timestamp()::timestamp_ltz as dbt_updated_at

from customers
