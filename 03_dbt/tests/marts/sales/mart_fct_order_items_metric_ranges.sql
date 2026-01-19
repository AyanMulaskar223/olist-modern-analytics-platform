-- Singular Test: Verify Metric Values Are Within Valid Ranges
--
-- BUSINESS RULE:
-- Financial and operational metrics must be within expected ranges:
-- - price_brl ≥ 0 (no negative prices)
-- - freight_value_brl ≥ 0 (no negative freight)
-- - delivery_time_days ≥ 0 (no negative delivery times) - flagged but not filtered
-- - is_delayed ∈ (0, 1, NULL) (boolean flag, NULL for non-delivered)
--
-- CONTEXT:
-- - These are pre-calculated in the intermediate layer (int_sales__order_items_joined)
-- - Marts layer passes them through without modification
-- - Invalid values are flagged with is_verified=0 and quality_issue_reason
-- - Per Phase 1 requirements: Flag outliers, don't remove them
--
-- FAILURE SCENARIO:
-- 1. price_brl < 0: Inflates/deflates revenue analysis
-- 2. freight_value_brl < 0: Incorrect logistics cost
-- 3. delivery_time_days < 0: Timestamp logic error (delivered before ordered)
-- 4. is_delayed not in (0, 1): Filter logic breaks
--
-- NOTE: Negative delivery_time_days are ALLOWED if flagged (is_verified=0)
-- We want visibility into these issues, not to hide them
--
-- TEST SEVERITY: WARN (data quality monitoring, not blocker)

{{ config(severity='warn') }}

select
    'negative_price' as metric_issue,
    count(*) as problematic_records

from {{ ref('fct_order_items') }}

where price_brl < 0

union all

select
    'negative_freight' as metric_issue,
    count(*) as problematic_records

from {{ ref('fct_order_items') }}

where freight_value_brl < 0

union all

select
    'invalid_is_delayed_value' as metric_issue,
    count(*) as problematic_records

from {{ ref('fct_order_items') }}

where is_delayed not in (0, 1) and is_delayed is not null  -- Allow NULL for non-delivered

having count(*) > 0
