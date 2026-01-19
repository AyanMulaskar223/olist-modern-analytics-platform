-- Singular Test: Verify Date Dimension Completeness (No Gaps)
--
-- BUSINESS RULE:
-- The dim_date table must have a complete, unbroken calendar from start_date to end_date.
-- - No gaps in the calendar (every day must exist)
-- - No duplicates (each date appears exactly once)
-- - Enables proper time-series analysis and DAX date relationships
--
-- CONTEXT:
-- - Date dimension is conformed across all fact tables
-- - Power BI relationships: fact[order_date_dt] → dim_date[date_day]
-- - Gaps or duplicates cause incomplete trend analysis
--
-- FAILURE SCENARIO:
-- 1. Date '2016-06-15' is missing from dim_date
--    → No data for that day in Power BI (appears blank)
--    → Time-series charts have gaps
-- 2. Date '2016-06-15' appears twice (duplicate rows)
--    → Revenue aggregates double-count
--    → SLA metrics incorrect
-- 3. Date range mismatch: Expected 2016-01-01 to 2018-12-31, but missing 2017
--    → Year-over-year analysis breaks
--
-- ROOT CAUSE DETECTION:
-- Failing test indicates:
-- - Date spine generation error (rowcount parameter mismatch)
-- - CTE logic in dim_date.sql has a bug
-- - Check: Expected 1096 days (3 years), verify rowcount in generator

select
    min(date_day) as start_date,
    max(date_day) as end_date,
    count(*) as total_days,
    count(distinct date_day) as distinct_days,
    datediff('day', min(date_day), max(date_day)) + 1 as expected_days

from {{ ref('dim_date') }}

having
    -- Duplicate detection
    count(*) != count(distinct date_day)
    or
    -- Gap detection: actual days should match expected range
    count(*) != datediff('day', min(date_day), max(date_day)) + 1
