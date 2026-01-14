-- Logic: Group by the Person ID. If any count > 1, deduplication failed.

select
    customer_unique_id,
    count(*) as count_rows
from {{ ref('int_customers__prep') }}
group by 1
having count(*) > 1
