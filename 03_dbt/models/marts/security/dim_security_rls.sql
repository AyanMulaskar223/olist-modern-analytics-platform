{{
    config(
        materialized='table',
        schema='security',
        tags=['security', 'rls', 'admin']
    )
}}

{#
    PURPOSE: Security RLS mapping table for row-level security enforcement
    GRAIN: One row per (user_email, access_key) pair
    SOURCE: dbt seed (security_rls_mapping.csv)

    BUSINESS CONTEXT:
    - Maps users to abstract security "tokens" (e.g., states, regions)
    - Many-to-Many relationship: One user can access multiple regions/states
    - This table is the ENTRY POINT for the RLS Bridge pattern
    - Power BI uses this to filter the rest of the data model

    RLS FLOW:
    1. User logs into Power BI
    2. Power BI reads their email from dim_security_rls
    3. Gets all access_keys for that user (e.g., ['SP', 'RJ'])
    4. dim_rls_bridge translates access_keys to seller_state_codes
    5. dim_sellers filters to only those states
    6. fct_order_items is filtered via seller relationships

    MARTS LAYER RULES:
    ✅ Business-friendly column names (user_email, not upn)
    ✅ Explicit column selection
    ✅ Table materialization for fast lookups
    ✅ No complex transformations (simple pass-through from seed)
    ✅ Seed data is source-of-truth (managed by ops/admin)

#}

with security_rls as (

    select * from {{ ref('security_rls_mapping') }}

)

select
    -- 👤 USER IDENTIFIER
    -- Principal name / email (e.g., alice@olist.com)
    -- This is matched against Power BI user context
    user_email,

    -- 🔑 ACCESS TOKEN
    -- Abstract security key (e.g., 'SP', 'RJ', 'SOUTH_REGION')
    -- Linked to dim_rls_bridge for translation to concrete values
    access_key,

    -- 📍 ACCESS LEVEL CONTEXT
    -- Describes what the access_key represents (e.g., 'State', 'Region')
    -- Used for audit trails and documentation
    access_level,

    -- ⏰ METADATA
    current_timestamp()::timestamp_lptz as dbt_updated_at

from security_rls
