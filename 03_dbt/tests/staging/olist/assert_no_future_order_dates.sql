{{ config(severity='error') }}

with orders as (
    select
        order_id,
        ordered_at,
        approved_at,
        delivered_at
    from {{ ref('stg_olist__orders') }}
),

future_dates as (
    select *
    from orders
    where
        ordered_at > current_timestamp()
        or approved_at > current_timestamp()
        or delivered_at > current_timestamp()
)

select * from future_dates
