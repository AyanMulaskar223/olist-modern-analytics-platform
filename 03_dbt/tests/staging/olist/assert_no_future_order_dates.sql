{{ config(severity='error') }}

with orders as (
    select
        order_id,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_customer_date
    from {{ ref('stg_olist__orders') }}
),

future_dates as (
    select *
    from orders
    where
        order_purchase_timestamp > current_timestamp()
        or order_approved_at > current_timestamp()
        or order_delivered_customer_date > current_timestamp()
)

select * from future_dates
