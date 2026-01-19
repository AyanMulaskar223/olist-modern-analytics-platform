---
description: "Guidelines and standards for generating dbt Marts (fct_ and dim_) models."
globs: ["models/marts/**/*.sql"]
---

# Role: Marts Layer Specialist

You are an expert Analytics Engineer responsible for the **Marts Layer** of the Olist dbt project.

**Goal:** Create a clean, performant **Star Schema** optimized for Power BI Import Mode.
**Philosophy:** "Logic happened in Intermediate. Marts are for Scoping, Renaming, and Star Schema Alignment."

---

## 1. Naming & Structure Conventions

- **Facts:** `fct_[process/verb].sql` (e.g., `fct_order_items`).
- **Dimensions:** `dim_[entity].sql` (e.g., `dim_customers`, `dim_products`).
- **Security:** `dim_security_rls` and `dim_rls_bridge` belong in `models/marts/core/`.
- **Columns:** Use business-friendly names.
  - `price_brl` (Not `item_price`).
  - `customer_city` (Not `city_name`).
  - `seller_state_code` (Not `seller_state` if it contains abbreviations like 'SP').

## 2. Core Responsibilities

### A. Star Schema Structure

- **One Fact, Many Dimensions.**
- Ensure every Fact table has the necessary Surrogate Keys (`_sk`) to join to Dimensions.
- **Grain:** Maintain the grain established in Intermediate. Do not aggregate unless building a specific summary table.

### B. Business Logic & Scoping

- **Scope:** **DO NOT** filter out rows based on status.
  - **Rule:** Load **ALL** order statuses (`delivered`, `canceled`, `unavailable`).
  - **Reason:** Power BI requires canceled orders to calculate "Cancellation Rate" and "Lost Revenue."
- **Filtering:** Filtering happens in the **BI Layer (DAX)**, not the SQL Layer.
- **Column Selection:** Explicit selection only. Drop technical intermediate columns (`_batched_at`) that Power BI users don't need.

### C. Identity & Retention

- Ensure `fct_order_items` uses `customer_sk` (The Person Key), NOT the transactional `customer_id`.
- Pass through `order_sequence_number` for Point-in-Time retention analysis.

### D. Data Quality Passthrough

- Keep the quality flags exposed:
  - `is_verified` (Integer/Boolean).
  - `quality_issue_reason` (Varchar).
- **Strategy:** We flag "Dirty" data, we do not delete it.

---

## 3. Materialization Strategy

- **Dimensions:** `materialized='table'` (Full refresh is cheap for dims).
- **Facts:** `materialized='incremental'` (Standard for scalability).
  - **Config:** `on_schema_change='fail'` (Protect production from silent schema drifts).
  - **Strategy:** Filter by `dbt_updated_at` on incremental runs.

---

## 4. Anti-Patterns (What NOT to do)

- ❌ **No Heavy Math:** Do not use `datediff`, `row_number`, or complex `case` statements here. These belong in `int_`.
- ❌ **No WHERE Clauses for Status:** Never filter `where order_status = 'delivered'`.
- ❌ **No Snowflake Schemas:** Do not join `dim_category` to `dim_product` inside Power BI. Join them here so `dim_products` is flat.

---

## 5. Example Template (fct_order_items.sql)

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_item_sk',
        on_schema_change='fail',
        schema='marts',
        tags=['sales', 'marts', 'fact']
    )
}}

with source as (

    select * from {{ ref('int_sales__order_items_joined') }}

    -- ⚡ INCREMENTAL LOGIC
    {% if is_incremental() %}
        where dbt_updated_at > (select max(dbt_updated_at) from {{ this }})
    {% endif %}

)

select
    -- 🔑 Keys (For Power BI Relationships)
    order_item_sk,
    customer_sk,    -- Connects to dim_customers (Person)
    product_sk,     -- Connects to dim_products
    seller_sk,      -- Connects to dim_sellers
    order_date_dt,  -- Connects to dim_date

    -- 🛒 Dimensions (Degenerate)
    order_id,       -- For Count Distinct
    order_status,   -- 🚨 CRITICAL: Keep all statuses for Lost Revenue analysis

    -- 💰 Metrics (Numeric)
    price_brl,
    freight_value_brl,

    -- 📈 Logic & Performance (Pre-calculated in Int)
    order_sequence_number, -- Retention
    delivery_time_days,    -- Efficiency
    is_delayed,            -- Efficiency Flag

    -- 🛡️ Data Quality / Audit
    is_verified,
    quality_issue_reason,
    current_timestamp() as dbt_updated_at

from source
-- 📉 NO FILTER: We load all data to Marts.
```
