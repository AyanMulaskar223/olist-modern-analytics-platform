-- Singular Test: Verify ALL Order Statuses Present (No Status Filtering)
--
-- BUSINESS RULE:
-- The fact table must include orders with multiple statuses (not just delivered)
-- as required for Power BI Lost Revenue and Cancellation Rate analysis.
--
-- CONTEXT:
-- - Marts Layer Philosophy: "No WHERE clauses for status"
-- - Filtering happens in DAX, not SQL
-- - This enables Power BI to calculate:
--   * Realized Revenue = SUM(price) WHERE status='Delivered'
--   * Lost Revenue = SUM(price) WHERE status IN ('Canceled', 'Unavailable')
--   * Cancellation Rate = COUNT(Canceled) / COUNT(*)
--
-- EXPECTED STATUSES (from stg_olist__orders, converted to Title Case):
-- - 'Delivered': Order received by customer
-- - 'Shipped': In transit
-- - 'Canceled': Customer or seller canceled
-- - 'Processing': Order being prepared
-- - 'Approved': Order approved, awaiting shipping
-- - 'Created': Order just created
-- - 'Invoiced': Payment received
-- - 'Unavailable': Seller out of stock
--
-- FAILURE SCENARIO:
-- If fact table only contains 'Delivered' orders → Cannot calculate Lost Revenue
-- Test fails if fewer than 2 distinct statuses exist

with status_counts as (

    select
        count(distinct order_status) as distinct_statuses

    from {{ ref('fct_order_items') }}

)

select
    'insufficient_statuses' as test_issue,
    distinct_statuses

from status_counts

where distinct_statuses < 2  -- Expect at least Delivered + one other status
