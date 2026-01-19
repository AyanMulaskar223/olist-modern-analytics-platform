{{
    config(
        materialized='table',
        schema='marts',
        tags=['sellers', 'marts', 'core', 'dimension', 'security']
    )
}}

{#
    PURPOSE: Seller dimension table representing merchant partners.
    GRAIN: One row per unique seller (seller_id).
    SOURCE: stg_olist__sellers

    BUSINESS CONTEXT:
    - Sellers are the external partners fulfilling orders.
    - This table is the PRIMARY TARGET for Row-Level Security (RLS).
    - Managers are assigned Regions (States), which filter this table via the Bridge.

    MARTS LAYER RULES:
    ✅ Surrogate Key (seller_sk) generated for Fact table joins.
    ✅ State column renamed to *_code to indicate ISO format (e.g., 'SP', 'RJ').
    ✅ Metadata included for lineage tracking.
#}

with sellers as (

    select * from {{ ref('stg_olist__sellers') }}

),

final as (

    select
        seller_sk,

        -- 🔗 NATURAL KEY (Business Key)
        -- Exposed for operational debugging (e.g., "Which seller is this?")
        seller_id,

        -- 📍 LOCATION ATTRIBUTES
        -- City is kept as text (Low cardinality enough for Import Mode)
        city as seller_city,

        -- 🛡️ RLS TARGET COLUMN
        -- This column is filtered by dim_rls_bridge.
        -- Renamed to *_code to be precise (It contains 'SP', not 'São Paulo')
        state as seller_state_code,


        -- ⏰ METADATA
        current_timestamp()::timestamp_ltz as dbt_updated_at

    from sellers

)

select * from final
