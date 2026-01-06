{{
    config(
        severity='error',
        tags=['singular_test', 'business_rule', 'orders', 'data_quality']
    )
}}

{#
    SINGULAR TEST: Delivered Orders Have Delivery Date

    PURPOSE: Validate delivered orders have recorded delivery timestamp

    BUSINESS RULE: If order_status = 'DELIVERED', then delivered_at must not be NULL
    - Delivered status implies delivery occurred
    - delivered_at timestamp required for SLA calculations
    - Missing date = "ghost delivery" (process failure)

    WHY: These violations cause:
    1. Incorrect delivery time calculations
    2. Missing data in on-time delivery KPIs
    3. Customer service escalations

    EXPECTED: Phase 2 identified 8 ghost deliveries (should be investigated and fixed)
#}

with delivered_orders as (

    select
        order_id,
        order_status,
        delivered_at,
        is_ghost_delivery
    from {{ ref('stg_olist__orders') }}
    where order_status = 'DELIVERED'

),

violations as (

    select
        order_id,
        'Ghost delivery: Status=DELIVERED but delivered_at is NULL' as violation_type
    from delivered_orders
    where delivered_at is null

)

-- Test fails if ANY ghost deliveries found
-- NOTE: Phase 2 identified 8 violations. This test documents them.
-- If count increases, investigate data pipeline integrity.
select * from violations
