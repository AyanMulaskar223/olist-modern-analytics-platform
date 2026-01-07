{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'sellers']
    )
}}

{#
    PURPOSE: Clean and standardize raw_sellers location data
    GRAIN: One row per seller_id
    SOURCE: raw_sellers (CSV format, 3,095 rows)

    ADLC COMPLIANCE:
    ✅ Surrogate Key Generation (Standardize join keys)
    ✅ Explicit Type Casting (Varchar safety)
    ✅ Location Standardization (Fixing Mixed Case & Whitespace)
    ✅ Zip Code Formatting (Defensive zero-padding)
    ✅ Audit Trail Preservation

    DATA QUALITY SUMMARY (from Validation):
    - Completeness: 100% (No missing IDs or locations)
    - Uniqueness: 100% (No duplicate sellers)
    - Issues Fixed:
        * Detected mixed casing in Cities -> Applied INITCAP()
        * Detected whitespace -> Applied TRIM()
    - Note: 12 States have <10 sellers (valid long-tail distribution)
#}

with source as (

    select * from {{ source('olist', 'raw_sellers') }}

),

renamed as (

    select
        -- 🔑 KEYS
        -- Hashing the natural key to match the SK pattern in Orders/Order_Items
        {{ dbt_utils.generate_surrogate_key(['seller_id']) }} as seller_sk,
        trim(seller_id)::varchar(32) as seller_id,

        -- 📍 LOCATION DETAILS (Standardized)

        -- Zip Code: Defensive Engineering
        -- Even if DQ passed, we apply LPAD to ensure '01001' doesn't become '1001'
        -- This ensures it joins correctly to the Geolocation table later.
        lpad(cast(seller_zip_code_prefix as varchar), 5, '0')::varchar(5) as zip_code,

        -- City: Aesthetic Fix
        -- DQ found "Mixed Case". We convert 'rio de janeiro' -> 'Rio De Janeiro'.
        -- We use INITCAP (Title Case) instead of UPPER because it is easier to read in charts.
        initcap(trim(seller_city))::varchar(50) as city,

        -- State: Format Fix
        -- DQ found whitespace. We trim and force UPPER because state codes are acronyms (SP, RJ).
        upper(trim(seller_state))::varchar(2) as state,

        -- 📝 AUDIT
        _source_file::varchar as source_file,
        _loaded_at::timestamp_ntz as source_loaded_at_utc

    from source

)

select * from renamed
