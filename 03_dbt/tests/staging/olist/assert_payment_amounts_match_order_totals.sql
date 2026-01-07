{{
    config(
        severity='warn',
        tags=['singular_test', 'business_rule', 'payments', 'reconciliation']
    )
}}

{#
    SINGULAR TEST: Payment Amounts Match Order Totals

    PURPOSE: Reconcile payment transactions with order item totals

    BUSINESS RULE: Total payment amount per order should equal sum of item prices + freight

    WHY: Discrepancies indicate:
    1. Partial refunds not captured in payment data
    2. Data quality issues in source systems
    3. Missing payment records

    TOLERANCE: Allow R$0.10 variance for floating-point rounding

    SEVERITY: WARN (not ERROR) because some variance is expected due to:
    - Partial refunds
    - Promotional adjustments
    - Payment system timing differences

    EXPECTED: <5% of orders with discrepancies (investigate if higher)
#}

with order_payments_total as (

    select
        order_id,
        sum(payment_amount) as total_paid
    from {{ ref('stg_olist__payments') }}
    group by order_id

),

order_items_total as (

    select
        order_id,
        sum(item_price_brl + item_freight_brl) as total_order_value
    from {{ ref('stg_olist__order_items') }}
    group by order_id

),

reconciliation as (

    select
        coalesce(p.order_id, i.order_id) as order_id,
        coalesce(p.total_paid, 0) as total_paid,
        coalesce(i.total_order_value, 0) as total_order_value,
        abs(coalesce(p.total_paid, 0) - coalesce(i.total_order_value, 0)) as variance
    from order_payments_total p
    full outer join order_items_total i
        on p.order_id = i.order_id

),

violations as (

    select
        order_id,
        total_paid,
        total_order_value,
        variance,
        case
            when total_paid = 0 and total_order_value > 0 then 'Missing payment records'
            when total_paid > 0 and total_order_value = 0 then 'Missing order items'
            when variance > 0.10 then 'Payment mismatch > R$0.10'
        end as violation_type
    from reconciliation
    where
        -- Flag significant discrepancies (>R$0.10)
        variance > 0.10
        -- Or missing data on either side
        or (total_paid = 0 and total_order_value > 0)
        or (total_paid > 0 and total_order_value = 0)

)

-- Test warns if reconciliation issues found
select * from violations
