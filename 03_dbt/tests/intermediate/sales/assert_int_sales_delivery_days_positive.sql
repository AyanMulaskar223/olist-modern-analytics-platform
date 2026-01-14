-- Logic: If an order is delivered, it must have a delivery time calculation.

select *
from {{ ref('int_sales__order_items_joined') }}
where
    order_status = 'delivered'
    and delivery_time_days is null
    and is_verified = 1 -- Only enforce this on clean data
