{#
    PURPOSE: Deduplicate Customer Master Data for the Dimension
    GRAIN: One row per Unique Person (user_sk)
    SOURCE: stg_olist__customers

    BUSINESS CONTEXT:
    - Olist data stores customer location per order.
    - A person (user_id) who moves cities will appear twice in staging.
    - Dimension Requirement: We need ONE current profile per person.

    LOGIC:
    - Window Function: Rank by 'source_loaded_at' desc to get the most recent address.
    - Filter: Keep only row_num = 1.
#}

{{
    config(
        materialized='table',
        tags=['sales', 'intermediate']
    )
}}

with customers as (
    select * from {{ ref('stg_olist__customers') }}
),

deduplicated as (
    select
        -- The Person Key (Target PK for Dimension)
        user_sk as customer_sk,
        user_id as customer_unique_id,

        -- Location Attributes
        city as customer_city,
        state as customer_state,
        zip_code,

        -- Logic: If a user has multiple addresses, take the most recent one processed
        row_number() over (
            partition by user_sk
            order by source_loaded_at_utc desc
        ) as row_num

    from customers
)

select
    customer_sk,
    customer_unique_id,
    customer_city,
    customer_state,
from deduplicated
where row_num = 1
