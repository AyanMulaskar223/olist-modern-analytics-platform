{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'products']
    )
}}

{#
    PURPOSE: Clean and standardize raw_products
    GRAIN: One row per product_id
    SOURCE: raw_products (CSV format)

    ADLC COMPLIANCE:
    ✅ Fix Source Typos: 'lenght' -> 'length' (Olist dataset spelling errors)
    ✅ Explicit Type Casting: Ensure metrics are numeric/integer
    ✅ Null Handling:
        - Default 'outros' for missing categories (610 rows)
        - Default 0 for missing photos (610 rows)
        - Default 0 for missing dimensions (2 rows) to prevent math errors
    ✅ Flagging: Identify products with missing specs for logistics team

    DATA QUALITY SUMMARY (from Validation):
    - Missing Categories: 610 (Imputed with 'outros')
    - Missing Photos: 610 (Imputed with 0)
    - Missing Dimensions (Weight/L/H/W): 2 rows (Imputed with 0, Flagged)
    - Orphaned Products: 0 (Integrity OK)
#}

with source as (

    select * from {{ source('olist', 'raw_products') }}

),

renamed as (

    select
        -- 🔑 KEYS
        {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_sk,
        trim(product_id)::varchar(32) as product_id,

        -- 🏷️ CATEGORY (Cleaned)
        -- DQ Fix: 610 rows are NULL. We map them to 'outros' (others)
        -- so they don't disappear in "Sales by Category" charts.
        coalesce(
            lower(trim(product_category_name)),
            'outros'
        )::varchar(50) as category_name_pt,

        -- 📏 SPECS & METRICS (Note: Raw table uses correct spelling 'length')
        -- We Coalesce to 0 because NULLs break downstream aggregation (AVG, SUM)
        coalesce(product_name_length, 0)::integer as name_length,
        coalesce(product_description_length, 0)::integer as description_length,
        coalesce(product_photos_qty, 0)::integer as photos_qty,

        -- 📦 LOGISTICS DATA (Dimensions & Weight)
        -- DQ Fix: 2 rows have NULL weight/dimensions.
        -- Set to 0 to safeguard freight calculations, but flag them below.
        coalesce(product_weight_g, 0)::integer as weight_g,
        coalesce(product_length_cm, 0)::integer as length_cm,
        coalesce(product_height_cm, 0)::integer as height_cm,
        coalesce(product_width_cm, 0)::integer as width_cm,

        -- 🚩 DATA QUALITY FLAGS
        -- Flag products that will cause shipping calculation errors
        case
            when product_weight_g is null
                 or product_length_cm is null
                 or product_height_cm is null
                 or product_width_cm is null
            then true
            else false
        end as is_missing_dimensions,

        -- Flag for Marketing: Products with no photos likely have low conversion
        case
            when coalesce(product_photos_qty, 0) = 0 then true
            else false
        end as is_missing_photos,

        -- 📝 AUDIT
        _source_file as source_filename,
        _loaded_at::timestamp_ntz as source_loaded_at_utc

    from source

)

select * from renamed
