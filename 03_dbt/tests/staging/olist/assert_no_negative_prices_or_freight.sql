{{
    config(
        severity='error',
        tags=['singular_test', 'business_rule', 'order_items', 'finance']
    )
}}

{#
    SINGULAR TEST: No Negative Prices or Freight

    PURPOSE: Validate that all financial amounts are non-negative

    BUSINESS RULE: Product prices and freight costs must be >= 0
    - Negative prices violate revenue recognition rules
    - Negative freight indicates data corruption

    WHY: Negative values would:
    1. Inflate refund metrics incorrectly
    2. Break total revenue calculations
    3. Corrupt financial reports for stakeholders

    EXPECTED: 0 violations (all prices >= 0)
#}

with order_items as (

    select
        order_item_sk,
        order_id,
        product_id,
        item_price_brl,
        item_freight_brl
    from {{ ref('stg_olist__order_items') }}

),

violations as (

    select
        order_item_sk,
        order_id,
        product_id,
        item_price_brl,
        item_freight_brl,
        case
            when item_price_brl < 0 then 'Negative price'
            when item_freight_brl < 0 then 'Negative freight'
        end as violation_type
    from order_items
    where
        item_price_brl < 0
        or item_freight_brl < 0

)

-- Test fails if ANY negative values found
select * from violations
