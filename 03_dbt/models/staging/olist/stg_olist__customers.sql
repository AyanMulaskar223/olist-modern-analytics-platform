{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'customers', 'core']
    )
}}

{#
    PURPOSE: Clean and standardize raw_customers location and identification data
    GRAIN: One row per customer_id (Note: This is an order-specific ID, not a person ID)
    SOURCE: raw_customers (CSV format)

    ADLC COMPLIANCE:
    ✅ Import CTE pattern
    ✅ Explicit type casting
    ✅ Dual Surrogate Key generation (Session vs User)
    ✅ No JOINs (staging rule)
    ✅ No GROUP BY (preserves grain)
    ✅ No business filtering
    ✅ Standardization of text fields (State/City)

    DATA QUALITY SUMMARY (from Phase 2 validation):
    - Missing customer_id: 0 (100% integrity)
    - State Codes: 27 unique values found. applied UPPER() to standardize mixed casing.
    - Zip Codes: Treated as text to preserve leading zeros (e.g., '01001').
    - Grain Check: customer_id is unique per order, customer_unique_id is unique per human.
#}

with source as (

    select * from {{ source('olist', 'raw_customers') }}

),

renamed as (

    select
        -- 🔑 SURROGATE KEYS (Dual Strategy)
        -- 1. Order-Link Key: Matches the key in stg_orders. Used for connecting orders to locations.
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,

        -- 2. User-Link Key: Grouping key for unique humans. Used for "Retention" & "CLV" analysis.
        {{ dbt_utils.generate_surrogate_key(['customer_unique_id']) }} as user_sk,

        -- 🔗 NATURAL KEYS
        -- Kept for debugging and distinct counting
        trim(customer_id)::varchar(32) as order_customer_id,
        trim(customer_unique_id)::varchar(32) as user_id,

        -- 📍 LOCATION DETAILS (Standardized)
        -- Zip Code: Pad with zeros to 5 digits (Standard Brazil Format) to fix integer stripping
        lpad(cast(customer_zip_code_prefix as varchar), 5, '0')::varchar(5) as zip_code,

        -- City: Standardize Title Case for cleaner reporting
        initcap(trim(customer_city))::varchar(50) as city,

        -- State: Force Uppercase (Fixes 'sp' vs 'SP' inconsistency found in DQ check)
        upper(trim(customer_state))::varchar(2) as state,

        -- 📝 AUDIT
        -- Only tracking source arrival. Transformation time belongs in Marts.
        _source_file as source_filename,
        _loaded_at::timestamp_ntz as source_loaded_at_utc

    from source

)

select * from renamed
