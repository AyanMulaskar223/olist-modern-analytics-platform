{#
    PURPOSE: Prepare core sales event table by joining Orders, Items, and Customers
    GRAIN: One row per line item per order (order_item_sk)
    SOURCES:
      - stg_olist__orders
      - stg_olist__order_items
      - stg_olist__customers

    BUSINESS CONTEXT:
    - Resolves "Transactional ID" to "Person ID" (Identity Resolution)
    - Calculates "Point-in-Time" Retention (Sequence #) at the Order Grain
    - Compresses technical DQ flags into business-friendly 'is_verified' switch

    ADLC COMPLIANCE:
    ✅ Import CTE pattern
    ✅ Explicit Joins (Star Schema prep)
    ✅ Window Functions (for Retention Logic)
    ✅ Surrogate Key preservation
    ✅ Date Type Casting (Timestamp -> Date)

    DATA TRANSFORMATION LOGIC:
    - Identity: Maps stg_orders.customer_id -> stg_customers.user_sk
    - Performance: Calculates delivery_time_days (DATEDIFF)
    - Logic: Consolidates 3+ DQ boolean flags into 1 'quality_issue_reason'
    - Fix: Pre-filters orders to ensure Retention Sequence #1 always exists (ignores empty orders)
#}

{{
    config(
        materialized='table',
        tags=['sales', 'intermediate']
    )
}}

with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

items as (
    select * from {{ ref('stg_olist__order_items') }}
),

customers as (
    select * from {{ ref('stg_olist__customers') }}
),

-- 1. PRE-FILTER: Identify only orders that actually have items
-- We do this to ensure we don't assign a Sequence Number to an empty order
-- This prevents the "Min Sequence = 2" bug.
valid_orders_list as (
    select distinct order_id
    from items
),

/*
   2. IDENTITY & RETENTION LOGIC
   We only calculate rank for orders that exist in the valid_orders_list.
   This ensures Order #2 becomes Order #1 if the original #1 was empty.
*/
orders_with_retention as (
    select
        o.order_id,
        o.customer_id,
        c.user_sk as customer_sk,
        c.user_id as customer_unique_id,
        o.ordered_at,
        o.delivered_at,
        o.estimated_delivery_at,
        o.order_status,

        -- DQ Flags
        o.is_ghost_delivery,
        o.is_arrival_before_shipping,
        o.is_arrival_before_approval,

        -- 🧠 CORRECTED SENIOR LOGIC:
        -- Rank only the VALID orders.
        row_number() over (
            partition by c.user_id
            order by o.ordered_at asc
        ) as order_sequence_number

    from orders o
    -- ⚡ INNER JOIN here filters out empty orders BEFORE ranking
    inner join valid_orders_list v
        on o.order_id = v.order_id
    left join customers c
        on o.customer_id = c.order_customer_id
),

/*
   3. JOIN TO ITEMS & CALCULATE METRICS
*/
joined as (
    select
        i.order_item_sk,
        o.order_id,
        o.customer_sk,
        i.product_sk,
        i.seller_sk,

        cast(o.ordered_at as date) as order_date_dt,

        i.item_price_brl as price_brl,
        i.item_freight_brl as freight_value_brl,

        o.order_sequence_number,

        datediff('day', o.ordered_at, o.delivered_at) as delivery_time_days,

        case
            when o.delivered_at > o.estimated_delivery_at then 1
            else 0
        end as is_delayed,

        -- DQ Compression
        case
            when o.is_ghost_delivery = true then 'Ghost Delivery'
            when o.is_arrival_before_shipping = true then 'Arrival Before Shipping'
            when o.is_arrival_before_approval = true then 'Arrival Before Approval'
            when i.item_price_brl <= 0 then 'Zero Value Item'
            else null
        end as quality_issue_reason,

        o.order_status

    from orders_with_retention o
    inner join items i
        on o.order_id = i.order_id
)

select
    order_item_sk,
    order_id,
    customer_sk,
    product_sk,
    seller_sk,
    order_date_dt,
    price_brl,
    freight_value_brl,
    order_sequence_number,
    delivery_time_days,
    is_delayed,

    case
        when quality_issue_reason is null then 1
        else 0
    end as is_verified,

    quality_issue_reason,
    order_status

from joined
