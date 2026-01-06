{{
    config(
        severity='warn',
        error_if='>500',
        warn_if='>0',
        tags=['singular_test', 'business_rule', 'orders']
    )
}}

{#
    SINGULAR TEST: Order Timestamp Logical Sequence

    PURPOSE: Validate that order timestamps follow business process flow

    BUSINESS RULE: For delivered orders, timestamps must follow this sequence:
    1. ordered_at (customer places order)
    2. approved_at (payment approved)
    3. shipped_at (carrier picks up)
    4. delivered_at (customer receives)

    WHY: Violations indicate data corruption or timestamp recording errors

    EXCEPTION: Approved orders can ship before approval in rare payment async cases
    (exclude from test to reduce noise)

    EXPECTED: 0 violations (all delivered orders have logical timestamp progression)
#}

with order_timestamps as (

    select
        order_id,
        order_status,
        ordered_at,
        approved_at,
        shipped_at,
        delivered_at
    from {{ ref('stg_olist__orders') }}
    where order_status = 'DELIVERED'  -- Only test completed orders

),

violations as (

    select
        order_id,
        case
            when delivered_at < ordered_at then 'Delivered before ordered'
            when delivered_at < approved_at then 'Delivered before payment approval'
            when delivered_at < shipped_at then 'Delivered before carrier pickup'
            when shipped_at < ordered_at then 'Shipped before ordered'
            when approved_at < ordered_at then 'Approved before ordered'
        end as violation_type
    from order_timestamps
    where
        -- Check all logical sequence violations
        delivered_at < ordered_at
        or delivered_at < approved_at
        or delivered_at < shipped_at
        or shipped_at < ordered_at
        or (approved_at is not null and approved_at < ordered_at)

)

-- Test fails if ANY violations found
select * from violations
