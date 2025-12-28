-- ==============================================================================
-- PHASE 2: DATA QUALITY CHECKS (RAW LAYER)
-- FILE: 05_raw_data_quality_checks.sql
-- PURPOSE: Detect (not fix) data quality issues in RAW tables
-- ==============================================================================

USE ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH_XS;
USE DATABASE OLIST_RAW_DB;
USE SCHEMA OLIST;

-- Tag queries for cost tracking
ALTER SESSION SET QUERY_TAG = 'PHASE_2_RAW_QUALITY_CHECKS';

-- ==============================================================================
-- SECTION 1: MISSING / NULL DATA
-- ==============================================================================

-- 1.1 Check for NULL Primary Keys (Critical)
SELECT 'NULL_PRIMARY_KEYS' AS check_type, 'raw_customers' AS table_name, COUNT(*) AS issue_count
FROM raw_customers
WHERE customer_id IS NULL

UNION ALL

SELECT 'NULL_PRIMARY_KEYS', 'raw_orders', COUNT(*)
FROM raw_orders
WHERE order_id IS NULL

UNION ALL

SELECT 'NULL_PRIMARY_KEYS', 'raw_products', COUNT(*)
FROM raw_products
WHERE product_id IS NULL

UNION ALL

SELECT 'NULL_PRIMARY_KEYS', 'raw_sellers', COUNT(*)
FROM raw_sellers
WHERE seller_id IS NULL;


-- 1.2 Check for NULL Foreign Keys (Warning)
SELECT 'NULL_FOREIGN_KEYS' AS check_type, 'raw_orders.customer_id' AS column_name, COUNT(*) AS issue_count
FROM raw_orders
WHERE customer_id IS NULL

UNION ALL

SELECT 'NULL_FOREIGN_KEYS', 'raw_order_items.order_id', COUNT(*)
FROM raw_order_items
WHERE order_id IS NULL

UNION ALL

SELECT 'NULL_FOREIGN_KEYS', 'raw_order_items.product_id', COUNT(*)
FROM raw_order_items
WHERE product_id IS NULL;


-- 1.3 Check for NULL in Critical Business Fields
SELECT 'NULL_BUSINESS_FIELDS' AS check_type, 'raw_orders.order_status' AS column_name, COUNT(*) AS issue_count
FROM raw_orders
WHERE order_status IS NULL

UNION ALL

SELECT 'NULL_BUSINESS_FIELDS', 'raw_orders.order_purchase_timestamp', COUNT(*)
FROM raw_orders
WHERE order_purchase_timestamp IS NULL

UNION ALL

SELECT 'NULL_BUSINESS_FIELDS', 'raw_order_payments.payment_value', COUNT(*)
FROM raw_order_payments
WHERE payment_value IS NULL;


-- ==============================================================================
-- SECTION 2: DUPLICATE DETECTION
-- ==============================================================================

-- 2.1 Check for Duplicate Primary Keys
SELECT 'DUPLICATE_PRIMARY_KEYS' AS check_type, 'raw_customers' AS table_name, COUNT(*) AS duplicate_count
FROM (
    SELECT customer_id, COUNT(*) AS cnt
    FROM raw_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT 'DUPLICATE_PRIMARY_KEYS', 'raw_orders', COUNT(*)
FROM (
    SELECT order_id, COUNT(*) AS cnt
    FROM raw_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT 'DUPLICATE_PRIMARY_KEYS', 'raw_products', COUNT(*)
FROM (
    SELECT product_id, COUNT(*) AS cnt
    FROM raw_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
);


-- 2.2 Check for Duplicate Composite Keys (Order Items)
SELECT 'DUPLICATE_COMPOSITE_KEYS' AS check_type, 'raw_order_items' AS table_name, COUNT(*) AS duplicate_count
FROM (
    SELECT order_id, order_item_id, COUNT(*) AS cnt
    FROM raw_order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
);


-- ==============================================================================
-- SECTION 3: DATA TYPE & FORMAT ISSUES
-- ==============================================================================

-- 3.1 Check for Invalid Timestamps (Future Dates)
SELECT 'FUTURE_TIMESTAMPS' AS check_type, 'raw_orders.order_purchase_timestamp' AS column_name, COUNT(*) AS issue_count
FROM raw_orders
WHERE order_purchase_timestamp > CURRENT_TIMESTAMP()

UNION ALL

SELECT 'FUTURE_TIMESTAMPS', 'raw_orders.order_delivered_customer_date', COUNT(*)
FROM raw_orders
WHERE order_delivered_customer_date > CURRENT_TIMESTAMP();


-- 3.2 Check for Invalid Date Sequences (Delivery before Purchase)
SELECT 'INVALID_DATE_SEQUENCE' AS check_type, 'raw_orders' AS table_name, COUNT(*) AS issue_count
FROM raw_orders
WHERE order_delivered_customer_date < order_purchase_timestamp
  AND order_delivered_customer_date IS NOT NULL;


-- ==============================================================================
-- SECTION 4: TEXT STANDARDIZATION ISSUES
-- ==============================================================================

-- 4.1 Check for Leading/Trailing Whitespace
SELECT 'WHITESPACE_ISSUES' AS check_type, 'raw_customers.customer_city' AS column_name, COUNT(*) AS issue_count
FROM raw_customers
WHERE customer_city != TRIM(customer_city)

UNION ALL

SELECT 'WHITESPACE_ISSUES', 'raw_sellers.seller_city', COUNT(*)
FROM raw_sellers
WHERE seller_city != TRIM(seller_city);

select distinct order_status from raw_orders;
-- 4.2 Check for Mixed Case Issues (Should be standardized in STAGING)

SELECT 'MIXED_CASE_ISSUES' AS check_type, 'raw_customers.customer_state' AS column_name, COUNT(DISTINCT customer_state) AS unique_values
FROM raw_customers

UNION ALL

SELECT 'MIXED_CASE_ISSUES', 'raw_orders.order_status', COUNT(DISTINCT order_status)
FROM raw_orders;


-- ==============================================================================
-- SECTION 5: NUMERIC RANGE & OUTLIER DETECTION
-- ==============================================================================

-- 5.1 Check for Negative Values (Should be Positive)
SELECT 'NEGATIVE_VALUES' AS check_type, 'raw_order_payments.payment_value' AS column_name, COUNT(*) AS issue_count
FROM raw_order_payments
WHERE payment_value < 0

UNION ALL

SELECT 'NEGATIVE_VALUES', 'raw_order_items.price', COUNT(*)
FROM raw_order_items
WHERE price < 0

UNION ALL

SELECT 'NEGATIVE_VALUES', 'raw_order_items.freight_value', COUNT(*)
FROM raw_order_items
WHERE freight_value < 0;


-- 5.2 Check for Zero Values (Potentially Invalid)
SELECT 'ZERO_VALUES' AS check_type, 'raw_order_payments.payment_value' AS column_name, COUNT(*) AS issue_count
FROM raw_order_payments
WHERE payment_value = 0

UNION ALL

SELECT 'ZERO_VALUES', 'raw_order_items.price', COUNT(*)
FROM raw_order_items
WHERE price = 0;


-- 5.3 Statistical Outlier Detection (IQR Method - Flag Only)
WITH payment_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY payment_value) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY payment_value) AS q3,
        (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY payment_value) -
         PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY payment_value)) AS iqr
    FROM raw_order_payments
)
SELECT
    'OUTLIERS_IQR' AS check_type,
    'raw_order_payments.payment_value' AS column_name,
    COUNT(*) AS outlier_count
FROM raw_order_payments, payment_stats
WHERE payment_value < (q1 - 1.5 * iqr)
   OR payment_value > (q3 + 1.5 * iqr);


-- ==============================================================================
-- SECTION 6: CATEGORY VALIDATION
-- ==============================================================================

-- 6.1 Check for Invalid Order Statuses
SELECT 'INVALID_CATEGORIES' AS check_type, 'raw_orders.order_status' AS column_name, order_status, COUNT(*) AS issue_count
FROM raw_orders
WHERE order_status NOT IN ('delivered', 'shipped', 'canceled', 'unavailable', 'invoiced', 'processing', 'created', 'approved')
GROUP BY order_status;


-- 6.2 Check for Invalid Payment Types
SELECT 'INVALID_CATEGORIES' AS check_type, 'raw_order_payments.payment_type' AS column_name, payment_type, COUNT(*) AS issue_count
FROM raw_order_payments
WHERE payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')
GROUP BY payment_type;


-- ==============================================================================
-- SECTION 7: REFERENTIAL INTEGRITY (Foreign Key Checks)
-- ==============================================================================

-- 7.1 Orphaned Orders (customer_id not in customers table)
SELECT 'ORPHANED_RECORDS' AS check_type, 'raw_orders → raw_customers' AS relationship, COUNT(*) AS orphan_count
FROM raw_orders o
LEFT JOIN raw_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 7.2 Orphaned Order Items (order_id not in orders table)
SELECT 'ORPHANED_RECORDS' AS check_type, 'raw_order_items → raw_orders' AS relationship, COUNT(*) AS orphan_count
FROM raw_order_items i
LEFT JOIN raw_orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 7.3 Orphaned Order Items (product_id not in products table)
SELECT 'ORPHANED_RECORDS' AS check_type, 'raw_order_items → raw_products' AS relationship, COUNT(*) AS orphan_count
FROM raw_order_items i
LEFT JOIN raw_products p ON i.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 7.4 Orphaned Order Items (seller_id not in sellers table)
SELECT 'ORPHANED_RECORDS' AS check_type, 'raw_order_items → raw_sellers' AS relationship, COUNT(*) AS orphan_count
FROM raw_order_items i
LEFT JOIN raw_sellers s ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ==============================================================================
-- SECTION 8: RECORD COUNT & FRESHNESS VALIDATION
-- ==============================================================================

-- 8.1 Row Count Summary (Baseline for Future Loads)
SELECT
    'ROW_COUNTS' AS check_type,
    'raw_customers' AS table_name,
    COUNT(*) AS row_count,
    MAX(_loaded_at) AS last_load_time
FROM raw_customers

UNION ALL

SELECT 'ROW_COUNTS', 'raw_orders', COUNT(*), MAX(_loaded_at)
FROM raw_orders

UNION ALL

SELECT 'ROW_COUNTS', 'raw_order_items', COUNT(*), MAX(_loaded_at)
FROM raw_order_items

UNION ALL

SELECT 'ROW_COUNTS', 'raw_order_payments', COUNT(*), MAX(_loaded_at)
FROM raw_order_payments

UNION ALL

SELECT 'ROW_COUNTS', 'raw_products', COUNT(*), MAX(_loaded_at)
FROM raw_products

UNION ALL

SELECT 'ROW_COUNTS', 'raw_sellers', COUNT(*), MAX(_loaded_at)
FROM raw_sellers

UNION ALL

SELECT 'ROW_COUNTS', 'raw_geolocation', COUNT(*), MAX(_loaded_at)
FROM raw_geolocation;


-- 8.2 Freshness Check (Data Loaded in Last 24 Hours)
SELECT
    'DATA_FRESHNESS' AS check_type,
    table_name,
    DATEDIFF('hour', last_load_time, CURRENT_TIMESTAMP()) AS hours_since_load
FROM (
    SELECT 'raw_customers' AS table_name, MAX(_loaded_at) AS last_load_time FROM raw_customers
    UNION ALL
    SELECT 'raw_orders', MAX(_loaded_at) FROM raw_orders
    UNION ALL
    SELECT 'raw_order_items', MAX(_loaded_at) FROM raw_order_items
)
WHERE DATEDIFF('hour', last_load_time, CURRENT_TIMESTAMP()) > 24;


-- ==============================================================================
-- SECTION 9: SUMMARY REPORT
-- ==============================================================================

-- 9.1 Quality Score Summary (Example)
WITH quality_metrics AS (
    SELECT
        'raw_orders' AS table_name,
        COUNT(*) AS total_rows,
        SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_pks,
        SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_fks,
        SUM(CASE WHEN order_status NOT IN ('delivered', 'shipped', 'canceled', 'unavailable', 'invoiced', 'processing', 'created', 'approved') THEN 1 ELSE 0 END) AS invalid_statuses
    FROM raw_orders
)
SELECT
    table_name,
    total_rows,
    null_pks,
    null_fks,
    invalid_statuses,
    ROUND(((total_rows - null_pks - null_fks - invalid_statuses)::FLOAT / total_rows) * 100, 2) AS quality_score_pct
FROM quality_metrics;


-- Reset query tag
ALTER SESSION UNSET QUERY_TAG;

-- ==============================================================================
-- VALIDATION SUMMARY
-- ==============================================================================
-- ✅ NULL checks on primary keys, foreign keys, and critical fields
-- ✅ Duplicate detection on primary and composite keys
-- ✅ Data type validation (future dates, invalid sequences)
-- ✅ Text standardization issues flagged
-- ✅ Numeric range validation (negatives, zeros, outliers)
-- ✅ Category validation against allowed values
-- ✅ Referential integrity checks (orphaned records)
-- ✅ Row count and freshness validation
-- ✅ Quality score summary generated
--
-- 🚀 NEXT STEPS:
-- 1. Review flagged issues in detail
-- 2. Document findings in docs/03_data_quality_report.md
-- 3. Address issues in dbt STAGING layer (Phase 3)
-- ==============================================================================