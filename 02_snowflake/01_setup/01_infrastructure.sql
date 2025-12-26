/*==============================================================================
  01_infrastructure.sql - Olist Modern Analytics Platform
  
  Creates: Resource monitors, warehouses, databases, schemas, raw tables
  Phase: 2 - Data Acquisition & Ingestion
  Run as: SYSADMIN
==============================================================================*/

USE ROLE SYSADMIN;

-- Resource monitor: 100 credit monthly cap, suspend at 90%
CREATE OR REPLACE RESOURCE MONITOR OLIST_MONTHLY_LIMIT
  WITH CREDIT_QUOTA = 100
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS 
    ON 75 PERCENT DO NOTIFY
    ON 90 PERCENT DO SUSPEND
    ON 100 PERCENT DO SUSPEND_IMMEDIATE;

-- Governance database: shared utilities, tags, monitoring
CREATE DATABASE IF NOT EXISTS OLIST_COMMON_DB
  COMMENT = 'Shared utilities: tags, UDFs, monitoring views';

CREATE SCHEMA IF NOT EXISTS OLIST_COMMON_DB.GOVERNANCE;

-- Cost center tag: tracks which workload drives spend (Ingestion/Transform/Reporting)
CREATE OR REPLACE TAG OLIST_COMMON_DB.GOVERNANCE.COST_CENTER 
  COMMENT = 'Workload classification for billing analysis';

-- Environment tag: identifies PROD vs DEV environment
CREATE OR REPLACE TAG OLIST_COMMON_DB.GOVERNANCE.ENVIRONMENT 
  COMMENT = 'DEV | PROD | STAGING environment identifier';

-- Loading warehouse: X-SMALL, 60s suspend, Azure Blob → Snowflake RAW
CREATE OR REPLACE WAREHOUSE LOADING_WH_XS
  WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = 'OLIST_MONTHLY_LIMIT'
  COMMENT = 'Raw data ingestion from Azure Blob Storage';

ALTER WAREHOUSE LOADING_WH_XS SET TAG 
  OLIST_COMMON_DB.GOVERNANCE.COST_CENTER = 'INGESTION',
  OLIST_COMMON_DB.GOVERNANCE.ENVIRONMENT = 'PROD';

-- Transform warehouse: X-SMALL, 60s suspend, dbt model execution
CREATE OR REPLACE WAREHOUSE TRANSFORM_WH_XS
  WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = 'OLIST_MONTHLY_LIMIT'
  COMMENT = 'dbt transformations (STAGING → INTERMEDIATE → MARTS)';

ALTER WAREHOUSE TRANSFORM_WH_XS SET TAG 
  OLIST_COMMON_DB.GOVERNANCE.COST_CENTER = 'TRANSFORMATION',
  OLIST_COMMON_DB.GOVERNANCE.ENVIRONMENT = 'PROD';

-- Reporting warehouse: X-SMALL, 300s suspend (allows Power BI caching)
CREATE OR REPLACE WAREHOUSE REPORTING_WH_XS
  WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = 'OLIST_MONTHLY_LIMIT'
  COMMENT = 'Power BI Import/DirectQuery workloads';

ALTER WAREHOUSE REPORTING_WH_XS SET TAG 
  OLIST_COMMON_DB.GOVERNANCE.COST_CENTER = 'REPORTING',
  OLIST_COMMON_DB.GOVERNANCE.ENVIRONMENT = 'PROD';

-- Raw database: 0-day retention (source in Azure), immutable landing zone
CREATE OR REPLACE DATABASE OLIST_RAW_DB
  DATA_RETENTION_TIME_IN_DAYS = 0
  COMMENT = 'Raw data landing zone. Source of truth stored in Azure Blob.';

-- Landing schema: external stages, file formats
CREATE OR REPLACE SCHEMA OLIST_RAW_DB.LANDING 
  COMMENT = 'External stages and file format definitions';

-- Olist schema: raw tables loaded via COPY INTO
CREATE OR REPLACE SCHEMA OLIST_RAW_DB.OLIST 
  COMMENT = 'Raw Olist tables loaded via COPY INTO';

-- Analytics database: 1-day retention (Time Travel), dbt-managed production layer
CREATE OR REPLACE DATABASE OLIST_ANALYTICS_DB
  DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'Production analytics layer managed by dbt';

-- Staging schema: dbt staging models (cleaned, typed VIEWs)
CREATE OR REPLACE SCHEMA OLIST_ANALYTICS_DB.STAGING
  COMMENT = 'dbt staging: cleaned, typed columns (VIEWs)';

-- Intermediate schema: dbt intermediate models (business logic, EPHEMERAL)
CREATE OR REPLACE SCHEMA OLIST_ANALYTICS_DB.INTERMEDIATE
  COMMENT = 'dbt intermediate: business logic joins (EPHEMERAL)';

-- Marts schema: dbt marts (star schema TABLEs for Power BI)
CREATE OR REPLACE SCHEMA OLIST_ANALYTICS_DB.MARTS
  COMMENT = 'dbt marts: star schema for Power BI (TABLEs)';

--create a dev database for development and testing for dbt models using clone 
CREATE OR REPLACE DATABASE OLIST_DEV_DB CLONE OLIST_ANALYTICS_DB
  COMMENT = 'Development and testing database for dbt models using clone';
