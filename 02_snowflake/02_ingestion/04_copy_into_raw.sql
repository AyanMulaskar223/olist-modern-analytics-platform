-- ==============================================================================
-- PHASE 2: DATA ACQUISITION & INGESTION
-- FILE: 04_copy_into_raw.sql
-- PURPOSE: Create RAW tables + Load data from Azure Blob via COPY INTO
-- ==============================================================================

-- ==============================================================================
-- SECTION 0: CONTEXT SETUP
-- ==============================================================================
use ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH_XS;
USE DATABASE OLIST_RAW_DB;
USE SCHEMA OLIST;

-- DataFinOps: Tag queries for cost tracking
ALTER SESSION SET QUERY_TAG = 'PHASE_2_RAW_INGESTION';


-- ==============================================================================
-- SECTION 1: CREATE RAW TABLES WITH AUDIT COLUMNS
-- ==============================================================================
-- WHY: Raw tables must exactly match source structure + add metadata for traceability
-- PRINCIPLE: No transformations, no derived columns, no filtering
-- DESIGN: TRANSIENT = reduced storage cost (source of truth is in Azure)

-- 1.1 Customers Table
CREATE OR REPLACE TRANSIENT TABLE raw_customers (
    -- Source columns (exact match to CSV)
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2),

    -- Audit columns (DataOps: enables debugging & lineage tracking)
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw customer demographic data from Olist. Source: Azure Blob Storage.';

-- 1.2 Orders Table
CREATE OR REPLACE TRANSIENT TABLE raw_orders (
    -- Source columns
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP_NTZ,
    order_approved_at TIMESTAMP_NTZ,
    order_delivered_carrier_date TIMESTAMP_NTZ,
    order_delivered_customer_date TIMESTAMP_NTZ,
    order_estimated_delivery_date TIMESTAMP_NTZ,

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw order header data. One row per order lifecycle.';

-- 1.3 Order Payments Table
CREATE OR REPLACE TRANSIENT TABLE raw_order_payments (
    -- Source columns
    order_id VARCHAR(50),
    payment_sequential NUMBER,
    payment_type VARCHAR(30),
    payment_installments NUMBER,
    payment_value NUMBER(10,2),

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw payment transactions. One order can have multiple payments.';

-- 1.4 Products Table
CREATE OR REPLACE TRANSIENT TABLE raw_products (
    -- Source columns
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length NUMBER,
    product_description_length NUMBER,
    product_photos_qty NUMBER,
    product_weight_g NUMBER,
    product_length_cm NUMBER,
    product_height_cm NUMBER,
    product_width_cm NUMBER,

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw product catalog with dimensions and category (Portuguese).';

-- 1.5 Sellers Table
CREATE OR REPLACE TRANSIENT TABLE raw_sellers (
    -- Source columns
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2),

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw seller location data.';

-- 1.6 Geolocation Table
CREATE OR REPLACE TRANSIENT TABLE raw_geolocation (
    -- Source columns
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat NUMBER(10,8),
    geolocation_lng NUMBER(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2),

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw zip code to lat/lng mapping. Multiple entries per zip code.';

-- 1.7 Product Category Translation Table
-- MOVED TO DBT SEEDS (Phase 3)
-- CREATE OR REPLACE TRANSIENT TABLE raw_product_category_name_translation ... (REMOVED)

-- 1.8 Order Reviews Table (JSON source)
CREATE OR REPLACE TRANSIENT TABLE raw_order_reviews (
    -- Source columns (JSON will be loaded as VARIANT first, then parsed in dbt)
    review_data VARIANT,

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw order review data from JSON files. Will be flattened in dbt.';

-- 1.9 Order Items Table (Parquet source)
CREATE OR REPLACE TRANSIENT TABLE raw_order_items (
    -- Source columns
    order_id VARCHAR(50),
    order_item_id NUMBER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    price NUMBER(10,2),
    freight_value NUMBER(10,2),

    -- Audit columns
    _source_file VARCHAR(500),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_row_number NUMBER
)
COMMENT = 'Raw order items data from Parquet files. One row per product in order.';

-- ==============================================================================
-- SECTION 2: COPY INTO STATEMENTS (IDEMPOTENT LOADS)
-- ==============================================================================
-- WHY: Snowflake's COPY INTO automatically tracks loaded files (prevents duplicates)
-- BEST PRACTICE: Use pattern matching, ON_ERROR handling, and explicit column mapping


-- 2.1 Load Customers
COPY INTO raw_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARCHAR(50),                    -- customer_id
        $2::VARCHAR(50),                    -- customer_unique_id
        $3::VARCHAR(10),                    -- customer_zip_code_prefix
        $4::VARCHAR(100),                   -- customer_city
        $5::VARCHAR(2),                     -- customer_state
        METADATA$FILENAME,                  -- audit: source file name
        METADATA$FILE_ROW_NUMBER           -- audit: row number in source file
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/customers/.*_dataset.*\.csv'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT')
ON_ERROR = 'CONTINUE'                       -- DataOps: Skip bad rows, log errors
FORCE = FALSE;                              -- DataFinOps: Only load new files

-- 2.2 Load Orders
COPY INTO raw_orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARCHAR(50),
        $2::VARCHAR(50),
        $3::VARCHAR(20),
        $4::TIMESTAMP_NTZ,
        $5::TIMESTAMP_NTZ,
        $6::TIMESTAMP_NTZ,
        $7::TIMESTAMP_NTZ,
        $8::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/order/.*_extract.*\.csv'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT')
ON_ERROR = 'CONTINUE'
FORCE = FALSE;

-- 2.3 Load Order Payments
COPY INTO raw_order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARCHAR(50),
        $2::NUMBER,
        $3::VARCHAR(30),
        $4::NUMBER,
        $5::NUMBER(10,2),
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/payments/.*_dataset.*\.csv'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT')
ON_ERROR = 'CONTINUE'
FORCE = FALSE;

-- 2.4 Load Products
COPY INTO raw_products (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARCHAR(50),
        $2::VARCHAR(100),
        $3::NUMBER,
        $4::NUMBER,
        $5::NUMBER,
        $6::NUMBER,
        $7::NUMBER,
        $8::NUMBER,
        $9::NUMBER,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/products/.*_dataset.*\.csv'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT')
ON_ERROR = 'CONTINUE'

FORCE = FALSE;

-- 2.5 Load Sellers
COPY INTO raw_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARCHAR(50),
        $2::VARCHAR(10),
        $3::VARCHAR(100),
        $4::VARCHAR(2),
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/sellers/.*_dataset.*\.csv'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT')
ON_ERROR = 'CONTINUE'
FORCE = FALSE;

-- 2.6 Load Geolocation
COPY INTO raw_geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARCHAR(10),
        $2::NUMBER(10,8),
        $3::NUMBER(11,8),
        $4::VARCHAR(100),
        $5::VARCHAR(2),
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/geolocation/.*_dataset.*\.csv'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.CSV_GENERIC_FMT')
ON_ERROR = 'CONTINUE'
FORCE = FALSE;

-- 2.7 Load Product Category Translation
-- MOVED TO DBT SEEDS (Phase 3)
-- Rationale: Small reference table (< 100 rows), better managed as version-controlled CSV in dbt.
-- COPY INTO raw_product_category_name_translation ... (REMOVED)

-- 2.8 Load Order Reviews (JSON)
COPY INTO raw_order_reviews (
    review_data,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1::VARIANT,                        -- Store entire JSON object
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/reviews/.*_extract.*\.json'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.JSON_GENERIC_FMT')
ON_ERROR = 'CONTINUE'
FORCE = FALSE;
-- 2.9 Load Order Items (Parquet)
COPY INTO raw_order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value,
    _source_file,
    _file_row_number
)
FROM (
    SELECT
        $1:order_id::VARCHAR(50),           -- order_id
        $1:order_item_id::NUMBER,           -- order_item_id
        $1:product_id::VARCHAR(50),         -- product_id
        $1:seller_id::VARCHAR(50),          -- seller_id
        $1:price::NUMBER(10,2),             -- price
        $1:freight_value::NUMBER(10,2),     -- freight_value
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER
    FROM @OLIST_RAW_DB.LANDING.AZURE_STAGE
)
PATTERN = '(?i).*/items/.*_extract.*\\.parquet'
FILE_FORMAT = (FORMAT_NAME = 'OLIST_RAW_DB.LANDING.PARQUET_GENERIC_FMT')
ON_ERROR = 'CONTINUE'
FORCE = FALSE;
-- ==============================================================================
-- SECTION 3: LOAD VALIDATION (DATA QUALITY CHECKS)
-- ==============================================================================
-- WHY: Verify loads succeeded and flag anomalies (but do NOT fix them in RAW)

-- 3.0a List ALL Files (Debug Naming)
SELECT 'ALL FILES IN STAGE:' AS check_point;
LIST @OLIST_RAW_DB.LANDING.AZURE_STAGE RECURSIVE;

-- 3.0b Test Pattern Matching (Run after seeing actual file names)
-- Once you see the files above, update the PATTERN in SECTION 2 if needed
-- Example: If files are named "olist_orders_dataset_sample.csv", pattern should match

-- 3.1 Check Load History (Snowflake Metadata)
SELECT 'COPY_HISTORY for RAW_CUSTOMERS:' AS check_point;
SELECT
    table_name,
    status,
    file_name,
    row_count,
    row_parsed,
    error_count,
    error_limit,
    last_load_time
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OLIST_RAW_DB.OLIST.RAW_CUSTOMERS',
    START_TIME => DATEADD(hours, -12, CURRENT_TIMESTAMP())
))
ORDER BY last_load_time DESC
LIMIT 20;

-- 3.2 Row Count Summary (Quick Sanity Check)
SELECT 'ROW COUNTS - All Raw Tables:' AS check_point;
SELECT 'raw_customers' AS table_name, COUNT(*) AS row_count FROM raw_customers
UNION ALL
SELECT 'raw_orders', COUNT(*) FROM raw_orders
UNION ALL
SELECT 'raw_order_items', COUNT(*) FROM raw_order_items
UNION ALL
SELECT 'raw_order_payments', COUNT(*) FROM raw_order_payments
UNION ALL
SELECT 'raw_products', COUNT(*) FROM raw_products
UNION ALL
SELECT 'raw_sellers', COUNT(*) FROM raw_sellers
UNION ALL
SELECT 'raw_geolocation', COUNT(*) FROM raw_geolocation
-- UNION ALL
-- SELECT 'raw_product_category_name_translation', COUNT(*) FROM raw_product_category_name_translation
UNION ALL
SELECT 'raw_order_reviews', COUNT(*) FROM raw_order_reviews
ORDER BY table_name;



-- 3.6 Check for Load Errors in All Tables (Critical for Debugging)
SELECT
    table_name,
    file_name,
    error_count,
    error_limit,
    status
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OLIST_RAW_DB.OLIST.RAW_CUSTOMERS',
    START_TIME => DATEADD(hours, -2, CURRENT_TIMESTAMP())
))
WHERE error_count > 0
ORDER BY last_load_time DESC;

-- Alternative: Query all recent COPY operations
-- SELECT
--     table_name,
--     file_name,
--     error_count,
--     status
-- FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(START_TIME => DATEADD(hours, -2, CURRENT_TIMESTAMP())))
-- WHERE table_name LIKE 'RAW_%' AND error_count > 0
-- ORDER BY last_load_time DESC;

-- ==============================================================================
-- SECTION 4: COST TRACKING & CLEANUP
-- ==============================================================================

-- 4.1 Query Cost Summary (DataFinOps)
SELECT
    query_tag,
    warehouse_name,
    SUM(credits_used_cloud_services) AS total_credits,
    COUNT(*) AS query_count
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_tag = 'PHASE_2_RAW_INGESTION'
  AND start_time >= DATEADD(hours, -1, CURRENT_TIMESTAMP())
GROUP BY query_tag, warehouse_name;

-- 4.2 Reset Query Tag
ALTER SESSION UNSET QUERY_TAG;

-- ==============================================================================
-- VALIDATION SUMMARY
-- ==============================================================================
-- ✅ Raw tables created with exact source schema + audit columns
-- ✅ COPY INTO executed with idempotent FORCE=FALSE
-- ✅ Load history captured in Snowflake metadata
-- ✅ Cost tracking via QUERY_TAG enabled
--
-- ==============================================================================
