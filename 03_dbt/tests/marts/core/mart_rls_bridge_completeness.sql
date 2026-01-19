-- Singular Test: Verify RLS Bridge Completeness (No Orphaned Security Tokens)
--
-- BUSINESS RULE:
-- Every access_key in dim_security_rls must have at least one mapping in dim_rls_bridge.
-- This ensures no user is assigned an access key that doesn't map to any seller state.
--
-- CONTEXT:
-- - dim_security_rls: Maps users (email) to abstract tokens (access_key)
-- - dim_rls_bridge: Translates tokens to concrete seller_state_codes
-- - Power BI flow: User → access_key → seller_state_code → dim_sellers
--
-- FAILURE SCENARIO:
-- 1. User alice@olist.com has access_key='SOUTH_REGION'
--    but dim_rls_bridge has no row for access_key='SOUTH_REGION'
--    → User logs in but sees NO data (empty fact table)
--    → Silent failure (user doesn't know why)
-- 2. New state code 'XX' added to bridge, not used by any user
--    → Orphaned security mapping (no harm, but inefficient)
--
-- ROOT CAUSE DETECTION:
-- Failing test indicates:
-- - Seed data mismatch (security_rls_mapping.csv incomplete)
-- - Data entry error in access_key assignment
-- - Bridge not re-generated after seed update

select
    'orphaned_access_key' as rls_issue,
    access_key,
    count(*) as user_count

from {{ ref('dim_security_rls') }}

where access_key not in (select distinct access_key from {{ ref('dim_rls_bridge') }})

group by access_key
