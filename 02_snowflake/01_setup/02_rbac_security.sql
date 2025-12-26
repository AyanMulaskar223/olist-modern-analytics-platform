-- ============================================================
-- RBAC & Security Setup
-- Project: Olist Modern Analytics Platform
-- Purpose: Least-privilege access for ingestion, analytics, CI, and BI
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
COMMENT = 'Service role for raw data ingestion';

CREATE ROLE IF NOT EXISTS CI_SERVICE_ROLE
COMMENT = 'Service role for CI/CD pipelines (dbt + tests)';


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
GRANT SELECT ON ALL TABLES IN DATABASE OLIST_RAW_DB TO ROLE ANALYTICS_ROLE;

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