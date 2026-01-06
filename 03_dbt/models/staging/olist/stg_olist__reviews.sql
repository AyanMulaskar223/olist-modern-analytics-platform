{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'reviews']
    )
}}

{#
    PURPOSE: Flatten and clean raw_order_reviews (JSON blob)
    GRAIN: One row per unique review_id
    SOURCE: raw_order_reviews (Column: review_data)

    ADLC COMPLIANCE (STRICT):
    ✅ JSON Parsing: Extracts fields safely using try_parse_json
    ✅ NaN Handling: Converts Python 'NaN' string artifacts to SQL NULLs
    ✅ Deduplication: Removes 814 duplicate review_ids (Technical Cleaning)
    ✅ Type Casting: Explicit casts for scores (int) and dates (timestamp)
    ❌ NO Business Logic: Sentiment and Response Time moved to Intermediate Layer.

    DATA QUALITY SUMMARY:
    - Duplicates: 814 (Handled via QUALIFY)
    - NaN Artifacts: Handled via NULLIF
#}

with source as (

    select * from {{ source('olist', 'raw_order_reviews') }}

),

parsed as (

    select
        _loaded_at,
        try_parse_json(review_data) as json_blob
    from source

),

flattened as (

    select
        _loaded_at,

        -- 🔑 IDS
        -- Extract as text first to catch any 'NaN' strings
        json_blob:review_id::varchar as review_id,
        json_blob:order_id::varchar as order_id,

        -- 📊 METRICS
        try_cast(json_blob:review_score::varchar as integer) as review_score,

        -- 📝 CONTENT
        -- Technical Cleaning: Converting "NaN" text to real NULLs
        nullif(json_blob:review_comment_title::varchar, 'NaN') as review_title,
        nullif(json_blob:review_comment_message::varchar, 'NaN') as review_message,

        -- 🕒 TIMESTAMPS
        try_cast(json_blob:review_creation_date::varchar as timestamp) as created_at,
        try_cast(json_blob:review_answer_timestamp::varchar as timestamp) as answered_at

    from parsed

),

final as (

    select
        -- 🔑 KEYS
        -- 1. PK: Identify the Review
        {{ dbt_utils.generate_surrogate_key(['review_id']) }} as review_sk,
        -- 2. FK: Link to the Order (Bridge to fct_orders)
        {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_sk,

        -- 🔗 NATURAL KEYS
        review_id,
        order_id,

        -- 📊 RAW METRICS
        review_score,

        -- 📝 CONTENT
        review_title,
        review_message,

        -- Boolean flag is faster for BI filtering than checking "IS NOT NULL" text
        case
            when review_message is not null then true
            else false
        end as has_comment,

        -- 🕒 TIMESTAMPS
        created_at,
        answered_at,

        -- 📝 AUDIT
        _loaded_at as source_loaded_at_utc

    from flattened

    -- 🛑 DEDUPLICATION (Technical Rule, not Business Rule)
    qualify row_number() over (partition by review_id order by _loaded_at desc) = 1

)

select * from final
