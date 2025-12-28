-- ==============================================================================
-- PHASE 2: DATA ACQUISITION & INGESTION
-- FILE: 03_external_stages.sql
-- PURPOSE: Configure Azure Storage Integration, File Formats, and External Stage
-- ==============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE OLIST_RAW_DB;
USE SCHEMA LANDING;

-- ==============================================================================
-- SECTION 1: STORAGE INTEGRATION (Azure Authentication)
-- ==============================================================================
CREATE OR REPLACE STORAGE INTEGRATION AZURE_OLIST_INT
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'AZURE'
ENABLED = TRUE
AZURE_TENANT_ID = 'de9a69e7-f6f0-4046-b46f-8c24ddb7faeb'
STORAGE_ALLOWED_LOCATIONS = ('azure://stolistanalyticsdev.blob.core.windows.net/raw-landing/');

-- Retrieve Azure consent URL and service principal for Azure setup
DESC STORAGE INTEGRATION AZURE_OLIST_INT;

-- ==============================================================================
-- SECTION 2: FILE FORMATS (Reusable Parsers)
-- ==============================================================================

-- CSV Format (Optimized for Olist/Excel exports)
CREATE OR REPLACE FILE FORMAT CSV_GENERIC_FMT
TYPE = 'CSV'
COMPRESSION = 'AUTO'                -- FinOps: Auto-detects GZIP to save storage/bandwidth
FIELD_DELIMITER = ','
RECORD_DELIMITER = '\n'
SKIP_HEADER = 1                     -- Header row is metadata, not data
FIELD_OPTIONALLY_ENCLOSED_BY = '"'  -- DataOps: Handles "City, State" correctly
TRIM_SPACE = TRUE                   -- DataOps: Removes accidental whitespace from cells
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE -- DataOps: Prevents load failure on 1 bad row (Debug later)
ENCODING = 'UTF8'                   -- Critical for Portuguese characters (ã, ç, é)
NULL_IF = ('', 'NULL', 'null')      -- Standardizes missing data to SQL NULL
COMMENT = 'Robust CSV format for Olist ingestion handling special chars and nulls';

-- JSON Format (Standardized)
CREATE OR REPLACE FILE FORMAT JSON_GENERIC_FMT
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE            -- DataOps: Flattens standard API arrays into rows
COMPRESSION = 'AUTO'
COMMENT = 'Standard JSON format for future API ingestions';

-- Parquet Format (Efficient columnar storage)
CREATE OR REPLACE FILE FORMAT PARQUET_GENERIC_FMT
TYPE = 'PARQUET'
COMPRESSION = 'AUTO'
COMMENT = 'Standard Parquet format for efficient columnar storage';

-- ==============================================================================
-- SECTION 3: EXTERNAL STAGE (The Pipeline)
-- ==============================================================================
CREATE OR REPLACE STAGE OLIST_RAW_DB.LANDING.AZURE_STAGE
URL = 'azure://stolistanalyticsdev.blob.core.windows.net/raw-landing'
STORAGE_INTEGRATION = AZURE_OLIST_INT
FILE_FORMAT = CSV_GENERIC_FMT
COMMENT = 'Pointer to Azure Blob Storage raw-landing container';

-- ==============================================================================
-- SECTION 4: VALIDATION
-- ==============================================================================
-- Verify the stage is working and can list files
LIST @OLIST_RAW_DB.LANDING.AZURE_STAGE;
