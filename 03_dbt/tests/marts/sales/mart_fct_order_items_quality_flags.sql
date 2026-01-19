-- Singular Test: Verify Data Quality Flags Consistency
--
-- BUSINESS RULE:
-- Data quality flags (is_verified, quality_issue_reason) must be consistent:
-- - If is_verified = 1 (TRUE): quality_issue_reason must be NULL
-- - If is_verified = 0 (FALSE): quality_issue_reason SHOULD be NOT NULL (warning only)
--
-- CONTEXT:
-- - Marts Layer Philosophy: "Flag dirty data, don't filter it out"
-- - These flags allow Power BI users to decide whether to include low-quality records
-- - Inconsistent flags indicate upstream logic errors
--
-- FAILURE SCENARIO:
-- 1. Record marked is_verified=1 but has quality_issue_reason='Missing category'
--    → Confusing to users (is it verified or not?)
--
-- ROOT CAUSE DETECTION:
-- Failing test means:
-- - Intermediate model's quality logic has a bug
-- - Test case: Check int_products__enriched if this is a product issue

select
    'verified_with_reason' as flag_inconsistency,
    count(*) as problematic_records

from {{ ref('fct_order_items') }}

where is_verified = 1 and quality_issue_reason is not null

having count(*) > 0
