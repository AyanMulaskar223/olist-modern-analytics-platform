-- Logic: Every customer MUST have a sequence #1.
-- If the minimum sequence number for a customer is > 1, something is broken in the window function.

with sequence_metrics as (
    select
        customer_sk,
        min(order_sequence_number) as min_sequence
    from {{ ref('int_sales__order_items_joined') }}
    group by 1
)

select *
from sequence_metrics
where min_sequence > 1
