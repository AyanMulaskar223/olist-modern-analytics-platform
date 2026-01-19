-- Singular Test: Verify RLS State Coverage (All Sellers Have RLS Mapping)
--
-- BUSINESS RULE:
-- Every seller_state_code in dim_sellers must have at least one mapping in dim_rls_bridge.
-- This ensures all sellers can be accessed by at least one manager role.
--
-- CONTEXT:
-- - dim_sellers: Contains seller_state_code for every merchant
-- - dim_rls_bridge: Maps access_keys to seller_state_codes
-- - If a state has sellers but no RLS bridge entry:
--   → No manager can access those sellers (data loss)
--
-- FAILURE SCENARIO:
-- 1. State 'RS' (Rio Grande do Sul) has 50 sellers
--    but dim_rls_bridge has no row with seller_state_code='RS'
--    → All RS sellers are invisible to Power BI users
--    → Revenue missing, anomalies in reporting
-- 2. New state added to sellers, RLS bridge not updated
--    → Same issue as above
--
-- ROOT CAUSE DETECTION:
-- Failing test indicates:
-- - RLS configuration incomplete during onboarding
-- - New state added without security setup
-- - Seed data (security_rls_mapping.csv) doesn't cover all states
-- - Action: Add missing state to seed, rerun dbt
--
-- TEST SEVERITY: WARN (configuration/data issue, not model logic)

{{ config(severity='warn') }}

select
    'uncovered_seller_state' as rls_issue,
    seller_state_code,
    count(distinct seller_sk) as seller_count

from {{ ref('dim_sellers') }}

where seller_state_code not in (
    select distinct seller_state_code from {{ ref('dim_rls_bridge') }}
)

group by seller_state_code
