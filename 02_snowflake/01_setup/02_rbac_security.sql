-- ============================================================
-- RBAC & Security Setup
-- Project: Olist Modern Analytics Platform
-- Purpose: Least-privilege access for ingestion, analytics, CI, and BI
-- Owner: Ayan
-- ============================================================

-- ============================================================
-- ⚠️ EXECUTION CONTEXT: Run this script as SECURITYADMIN or ACCOUNTADMIN
-- ============================================================

-- ------------------------------------------------------------
-- 1. CREATE ROLES
-- ------------------------------------------------------------

-- Human roles
CREATE ROLE IF NOT EXISTS ANALYTICS_ROLE
COMMENT = 'Data analysts / engineers: develop & manage analytics models';

CREATE ROLE IF NOT EXISTS REPORTER_ROLE
COMMENT = 'BI consumers: read-only access to curated marts';

-- Service roles
CREATE ROLE IF NOT EXISTS LOADER_ROLE
COMMENT = 'Service role for raw data ingestion (Azure → Snowflake)';

CREATE ROLE IF NOT EXISTS CI_SERVICE_ROLE
COMMENT = 'Service role for CI/CD pipelines (dbt + testing + schema validation)';


-- ------------------------------------------------------------
-- 2. ROLE HIERARCHY
-- ------------------------------------------------------------

-- SYSADMIN retains visibility & recovery control
GRANT ROLE ANALYTICS_ROLE TO ROLE SYSADMIN;
GRANT ROLE LOADER_ROLE TO ROLE SYSADMIN;
GRANT ROLE CI_SERVICE_ROLE TO ROLE SYSADMIN;


-- ------------------------------------------------------------
-- 3. DATABASE PRIVILEGES
-- ------------------------------------------------------------

-- RAW database (immutable landing zone)
GRANT USAGE ON DATABASE OLIST_RAW_DB TO ROLE LOADER_ROLE;
GRANT USAGE ON DATABASE OLIST_RAW_DB TO ROLE ANALYTICS_ROLE;

-- Analytics database (dbt-managed)
GRANT USAGE ON DATABASE OLIST_ANALYTICS_DB TO ROLE ANALYTICS_ROLE;
GRANT USAGE ON DATABASE OLIST_ANALYTICS_DB TO ROLE CI_SERVICE_ROLE;
GRANT USAGE ON DATABASE OLIST_ANALYTICS_DB TO ROLE REPORTER_ROLE;


-- ------------------------------------------------------------
-- 4. SCHEMA PRIVILEGES
-- ------------------------------------------------------------

-- Raw schemas
GRANT USAGE ON ALL SCHEMAS IN DATABASE OLIST_RAW_DB TO ROLE LOADER_ROLE;
GRANT CREATE ON SCHEMA OLIST_RAW_DB.OLIST TO ROLE LOADER_ROLE;
GRANT SELECT ON ALL TABLES IN DATABASE OLIST_RAW_DB TO ROLE ANALYTICS_ROLE;
GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA OLIST_RAW_DB.OLIST TO ROLE LOADER_ROLE;
GRANT INSERT, SELECT ON FUTURE TABLES IN SCHEMA OLIST_RAW_DB.OLIST TO ROLE LOADER_ROLE;
GRANT USAGE ON STAGE OLIST_RAW_DB.LANDING.AZURE_STAGE TO ROLE LOADER_ROLE;
GRANT USAGE ON FILE FORMAT OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT TO ROLE LOADER_ROLE;
GRANT USAGE ON FILE FORMAT OLIST_RAW_DB.LANDING.JSON_GENERIC_FMT TO ROLE LOADER_ROLE;
GRANT USAGE ON FILE FORMAT OLIST_RAW_DB.LANDING.PARQUET_GENERIC_FMT TO ROLE LOADER_ROLE;

-- Analytics schemas (dbt-managed)
GRANT USAGE ON ALL SCHEMAS IN DATABASE OLIST_ANALYTICS_DB TO ROLE ANALYTICS_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE OLIST_ANALYTICS_DB TO ROLE CI_SERVICE_ROLE;

GRANT SELECT ON ALL TABLES IN DATABASE OLIST_ANALYTICS_DB TO ROLE REPORTER_ROLE;


-- ------------------------------------------------------------
-- 5. FUTURE GRANTS (CRITICAL)
-- ------------------------------------------------------------

-- Ensure new objects automatically inherit permissions
GRANT SELECT ON FUTURE TABLES IN DATABASE OLIST_ANALYTICS_DB TO ROLE REPORTER_ROLE;
GRANT SELECT ON FUTURE VIEWS IN DATABASE OLIST_ANALYTICS_DB TO ROLE REPORTER_ROLE;

GRANT ALL ON FUTURE TABLES IN DATABASE OLIST_ANALYTICS_DB TO ROLE ANALYTICS_ROLE;


-- ------------------------------------------------------------
-- 6. WAREHOUSE ACCESS
-- ------------------------------------------------------------

-- Ingestion
GRANT USAGE ON WAREHOUSE LOADING_WH_XS TO ROLE LOADER_ROLE;

-- Transformations
GRANT USAGE ON WAREHOUSE TRANSFORM_WH_XS TO ROLE ANALYTICS_ROLE;
GRANT USAGE ON WAREHOUSE TRANSFORM_WH_XS TO ROLE CI_SERVICE_ROLE;

-- BI / Reporting
GRANT USAGE ON WAREHOUSE REPORTING_WH_XS TO ROLE REPORTER_ROLE;


-- ==============================================================
-- 7. ASSIGN USER AYAN TO APPROPRIATE ROLES
-- ==============================================================
-- ⚠️ IMPORTANT: Change 'AYAN' to match your Snowflake username (case-sensitive)
-- Run this section after replacing AYAN with your actual user name

GRANT ROLE ANALYTICS_ROLE TO USER AYAN;
GRANT ROLE LOADER_ROLE TO USER AYAN;
GRANT ROLE SYSADMIN TO USER AYAN;

-- Set SYSADMIN as default role for your user (can switch to others)
ALTER USER AYAN SET DEFAULT_ROLE = SYSADMIN;


-- ==============================================================
-- 8. VALIDATION (Run these to verify setup)
-- ==============================================================

-- Check all roles created
-- SHOW ROLES;

-- Check grants to AYAN
-- SHOW GRANTS TO USER AYAN;

-- Check grants to LOADER_ROLE
-- SHOW GRANTS TO ROLE LOADER_ROLE;

-- Check grants on schemas
-- SHOW GRANTS ON SCHEMA OLIST_RAW_DB.OLIST;

-- ==============================================================
-- SUMMARY
-- ==============================================================
-- ✅ Roles created: ANALYTICS_ROLE, REPORTER_ROLE, LOADER_ROLE, CI_SERVICE_ROLE
-- ✅ Least-privilege model: Each role has minimum required permissions
-- ✅ Future grants enabled: New tables inherit role permissions automatically
-- ✅ Cost tracking: QUERY_TAG used in ingestion/dbt scripts
-- ✅ User AYAN assigned to: ANALYTICS_ROLE, LOADER_ROLE, SYSADMIN
--
-- 🚀 NEXT STEPS:
-- 1. Verify user AYAN exists: SHOW USERS;
-- 2. If AYAN doesn't exist, create it: CREATE USER AYAN;
-- 3. Re-run this script to assign roles
-- 4. Test by switching roles: USE ROLE LOADER_ROLE;
-- ==============================================================
