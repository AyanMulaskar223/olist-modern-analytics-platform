{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'products', 'translation']
    )
}}

{#
    PURPOSE: Standardize and stage the category translation seed file.
    GRAIN: One row per category (Unique on Portuguese Name).
    SOURCE: seeds/product_category_name_translation.csv

    ADLC COMPLIANCE:
    ✅ Source: references {{ ref() }} instead of {{ source() }}
    ✅ Join Key Integrity: Portuguese name keeps underscores to match stg_products.
    ✅ Reporting Aesthetics: English name has underscores removed ('health_beauty' -> 'Health Beauty').
#}

with source as (

    select * from {{ ref('product_category_name_translation') }}

),

renamed as (

    select
        -- 🇧🇷 Portuguese Category (Join Key)
        -- 🛑 DO NOT REMOVE UNDERSCORES HERE!
        -- This must match the raw format in 'stg_olist__products' (e.g., 'cama_mesa_banho')
        -- or your joins will fail in the next layer.
        lower(trim(product_category_name))::varchar(50) as category_name_pt,

        -- 🇺🇸 English Category (Reporting Label)
        -- ✅ REMOVE UNDERSCORES HERE.
        -- We replace '_' with ' ' so 'bed_bath_table' becomes 'Bed Bath Table'.
        -- This creates a clean, business-ready label for Power BI.
        initcap(
            replace(trim(product_category_name_english), '_', ' ')
        )::varchar(50) as category_name_en

    from source

)

select * from renamed
