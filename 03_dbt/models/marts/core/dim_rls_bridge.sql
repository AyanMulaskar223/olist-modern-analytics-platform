{{
    config(
        materialized='table',
        schema='marts',
        tags=['security', 'rls', 'bridge']
    )
}}

{#
    PURPOSE: RLS Bridge table for Many-to-Many security mapping
    GRAIN: One row per (access_key, seller_state_code) pair
    SOURCE: security_rls_mapping seed (deduplicated)

    BUSINESS CONTEXT:
    - Translates abstract security tokens (from dim_security_rls) to concrete seller states
    - Example: A manager with access_key='SP' can see all sellers in São Paulo state
    - Many-to-Many support: One access_key can map to multiple seller_state_codes
    - One user can have many access_keys (defined in dim_security_rls)

    RLS FLOW (BRIDGE PATTERN):
    1. User logs into Power BI (e.g., alice@olist.com)
    2. Power BI queries dim_security_rls WHERE user_email = 'alice@olist.com'
    3. Gets access_keys: ['SP', 'RJ']
    4. Power BI queries dim_rls_bridge WHERE access_key IN ['SP', 'RJ']
    5. Gets seller_state_codes: ['SP', 'RJ']
    6. Power BI filters dim_sellers WHERE seller_state_code IN ['SP', 'RJ']
    7. Fact table (fct_order_items) automatically filtered via seller relationships

    MARTS LAYER RULES:
    ✅ Explicit column selection (no SELECT *)
    ✅ DISTINCT to remove duplicates from seed
    ✅ Simple pass-through (no complex joins or logic)
    ✅ Table materialization for fast lookups
    ✅ Filters out NULL access_keys (data quality)

    DESIGN PATTERN: Bridge Table (Translator Pattern)
    - Input: Abstract security tokens (access_key)
    - Output: Concrete data values (seller_state_code)
    - Used for decoupling security rules from data model

#}

with security_seed as (

    select * from {{ ref('security_rls_mapping') }}

)

select distinct
    -- 🔑 BRIDGE KEYS (For Power BI Relationships)

    -- Input: The security token from dim_security_rls
    -- Used in Power BI: dim_rls_bridge[access_key] ← dim_security_rls[access_key]
    access_key,

    -- Output: The concrete seller state code
    -- Used in Power BI: dim_sellers[seller_state_code] ← dim_rls_bridge[seller_state_code]
    -- In this case, access_key values ARE state codes (SP, RJ, RS, etc.)
    -- If you had abstract tokens like 'SOUTH_REGION', you'd map them here
    access_key as seller_state_code,

    -- ⏰ METADATA
    current_timestamp()::timestamp_ltz as dbt_updated_at

from security_seed
where access_key is not null
