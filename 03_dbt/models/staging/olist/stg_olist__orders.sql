{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'orders', 'core']
    )
}}

{#
    PURPOSE: Clean and standardize raw_orders from Phase 2
    GRAIN: One row per order (order_id is unique)
    SOURCE: raw_orders (CSV format, 99,441 rows)

    ADLC COMPLIANCE:
    ✅ Import CTE pattern
    ✅ Explicit type casting
    ✅ Surrogate key generation
    ✅ No JOINs (staging rule)
    ✅ No GROUP BY (preserves grain)
    ✅ No business filtering (no WHERE on business data)
    ✅ FLAG data quality issues (not remove)

    DATA QUALITY SUMMARY:
    - Missing delivery dates: 2,965 (2.98%) [Valid: Status = shipped/processing]
    - Delivered before shipped: 23 orders [Flagged: is_arrival_before_shipping]
    - Delivered status without date: 8 orders [Flagged: is_ghost_delivery]
#}

with source as (

    select * from {{ source('olist', 'raw_orders') }}

),

renamed as (

    select
        -- 🔑 KEYS
        {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_sk,
        trim(order_id)::varchar(32) as order_id,
        trim(customer_id)::varchar(32) as customer_id,

        -- 📝 STATUS (Standardized)
        -- 'Delivered' -> 'DELIVERED'
        upper(trim(order_status))::varchar(20) as order_status,

        -- 🕒 TIMESTAMPS (Strict Type Casting)
        -- Using TIMESTAMP_NTZ to preserve local Brazilian time context
        order_purchase_timestamp::timestamp_ntz as ordered_at,
        order_approved_at::timestamp_ntz as approved_at,
        order_delivered_carrier_date::timestamp_ntz as shipped_at,
        order_delivered_customer_date::timestamp_ntz as delivered_at,
        order_estimated_delivery_date::timestamp_ntz as estimated_delivery_at,

        -- 🚩 LOGIC FLAGS (Technical Integrity)
        -- These indicate broken data, not just missing data.

        -- 1. Impossible Logistics: Customer received it before carrier shipped it
        case
            when order_delivered_customer_date is not null
                 and order_delivered_carrier_date is not null
                 and order_delivered_customer_date < order_delivered_carrier_date
            then true
            else false
        end as is_arrival_before_shipping,

        -- 2. Impossible Process: Delivered before payment approval
        case
            when order_delivered_customer_date is not null
                 and order_approved_at is not null
                 and order_delivered_customer_date < order_approved_at
            then true
            else false
        end as is_arrival_before_approval,

        -- 3. "Ghost Delivery": Status is DELIVERED, but date is NULL (Process Failure)
        case
            when upper(trim(order_status)) = 'DELIVERED' and order_delivered_customer_date is null
            then true
            else false
        end as is_ghost_delivery,

        -- 📝 AUDIT
        _source_file::varchar as source_file,
        _loaded_at::timestamp_ntz as source_loaded_at_utc

    from source

)

select * from renamed
