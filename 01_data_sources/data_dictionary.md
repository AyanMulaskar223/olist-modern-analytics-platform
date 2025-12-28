# 📊 Dataset Overview

| Item | Description |
|------|-------------|
| **Source** | Olist Brazilian E-commerce Dataset (Kaggle) |
| **Business Domain** | Marketplace & Logistics |
| **Data Owner** | Olist (Public Dataset) |
| **Data Type** | Transactional |
| **Refresh Frequency** | One-time snapshot |
| **Ingestion Format** | CSV / JSON / Parquet |
| **Storage Layer** | Azure Blob → Snowflake RAW |

---

## 🗂 Source Tables

### 1️⃣ `olist_orders_dataset`

**Description:** Contains one row per customer order placed on the Olist platform.

| Column Name | Data Type | Description | Example | Notes |
|-------------|-----------|-------------|---------|-------|
| `order_id` | string | Unique order identifier | `e481f51cbdc54678b7cc49136f2d6af7` | Natural primary key |
| `customer_id` | string | Customer placing the order | `9ef432eb6251297304e76186b10a928d` | Joins to customers |
| `order_status` | string | Order lifecycle status | `delivered` | Filter for revenue |
| `order_purchase_timestamp` | timestamp | Order creation time | `2017-10-02 10:56` | Business event time |
| `order_delivered_customer_date` | timestamp | Delivery completion date | `2017-10-10` | Nullable |
| `order_estimated_delivery_date` | timestamp | Estimated delivery | `2017-10-12` | Used for delay metrics |

**Known Issues:**

- Some orders have missing delivery dates
- Canceled orders exist and must be excluded from revenue

---

### 2️⃣ `olist_order_items_dataset`

**Description:** Contains one row per product item in an order.

| Column Name | Data Type | Description | Example | Notes |
|-------------|-----------|-------------|---------|-------|
| `order_id` | string | Order reference | same as orders | FK |
| `order_item_id` | integer | Line item number | `1` | Composite key |
| `product_id` | string | Product identifier | `1e9e8ef04dbcff4541ed26657ea517e5` | |
| `seller_id` | string | Seller fulfilling item | `3442f8959a84dea7ee197c632cb2df15` | |
| `price` | numeric | Item price | `58.90` | Excludes freight |
| `freight_value` | numeric | Shipping cost | `13.29` | Important cost metric |

**Known Issues:**

- Price outliers exist
- Same order can have multiple items

---

### 3️⃣ `olist_customers_dataset`

**Description:** Contains customer demographic and geographic information.

| Column Name | Data Type | Description | Example | Notes |
|-------------|-----------|-------------|---------|-------|
| `customer_id` | string | Internal customer ID | random string | Not unique |
| `customer_unique_id` | string | Unique customer across orders | stable ID | Use for repeat logic |
| `customer_city` | string | City | `sao paulo` | Case inconsistencies |
| `customer_state` | string | State code | `SP` | Used for region mapping |

**Known Issues:**

- `customer_id` ≠ `customer_unique_id`
- City naming inconsistencies

---

### 4️⃣ `olist_products_dataset`

| Column Name | Data Type | Description | Notes |
|-------------|-----------|-------------|-------|
| `product_id` | string | Product identifier | PK |
| `product_category_name` | string | Category (PT) | Needs translation |
| `product_weight_g` | numeric | Weight | Outliers present |

---

### 5️⃣ `olist_sellers_dataset`

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| `seller_id` | string | Seller identifier |
| `seller_city` | string | Seller city |
| `seller_state` | string | Seller state |

---

### 6️⃣ `olist_payments_dataset`

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| `order_id` | string | Order reference |
| `payment_type` | string | `credit_card`, `boleto` |
| `payment_value` | numeric | Payment amount |

---

## 🔑 Key Relationships (Raw Level)

| From Table | Column | To Table | Column |
|------------|--------|----------|--------|
| `orders` | `order_id` | `order_items` | `order_id` |
| `orders` | `customer_id` | `customers` | `customer_id` |
| `order_items` | `product_id` | `products` | `product_id` |
| `order_items` | `seller_id` | `sellers` | `seller_id` |
| `orders` | `order_id` | `payments` | `order_id` |

---

## ⚠️ Data Quality Observations (RAW)

- Missing delivery dates
- Multiple payments per order
- Price outliers
- Mixed case text fields
- No enforced constraints

> 👉 **No data removed here — only observed**
