-- Singular Test: Verify Retention Tracking (order_sequence_number)
--
-- BUSINESS RULE:
-- The order_sequence_number must correctly track customer purchase order:
-- - First order: order_sequence_number = 1
-- - Second order: order_sequence_number = 2
-- - No gaps: sequence should be 1, 2, 3, ... per customer (not 1, 3, 5)
-- - Valid range: > 0
--
-- CONTEXT:
-- - Used to calculate Repeat Customer Rate in Power BI
-- - Enables cohort retention analysis (do first-time buyers repeat?)
-- - Pre-calculated in intermediate layer (int_customers__prep logic)
-- - Passed through to facts for retention metrics
--
-- FAILURE SCENARIO:
-- 1. Customer has orders with sequence = [1, 1, 3] (gaps, duplicates)
--    → Retention metrics incorrect
--    → "Repeat customer" flag calculation broken
-- 2. order_sequence_number = 0 or negative
--    → Breaks cohort segmentation
--    → Filters fail in Power BI DAX
--
-- ROOT CAUSE DETECTION:
-- Failing test indicates:
-- - int_sales__order_items_joined didn't properly preserve order_sequence_number
-- - Intermediate layer ROW_NUMBER() logic failed
-- - Customer dimension prep didn't properly count orders

select
    customer_sk,
    count(*) as total_orders,
    min(order_sequence_number) as min_sequence,
    max(order_sequence_number) as max_sequence,
    count(distinct order_sequence_number) as distinct_sequences

from {{ ref('fct_order_items') }}

group by customer_sk

having
    -- Gap detection: max(sequence) should equal count of distinct sequences
    max(order_sequence_number) != count(distinct order_sequence_number)
    or
    -- Invalid range detection: sequence should start at 1
    min(order_sequence_number) != 1
    or
    -- Null detection: no order_sequence_number should be NULL
    count(order_sequence_number) != count(*)
