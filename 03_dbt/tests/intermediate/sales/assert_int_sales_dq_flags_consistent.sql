-- Logic: It is invalid to be Verified AND have an Issue Reason
-- It is also invalid to be Unverified AND have NO Issue Reason

select *
from {{ ref('int_sales__order_items_joined') }}
where
    -- Case 1: Says it's clean, but has an error reason
    (is_verified = 1 and quality_issue_reason is not null)
    OR
    -- Case 2: Says it's dirty, but reason is missing
    (is_verified = 0 and quality_issue_reason is null)
