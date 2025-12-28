# Azure Storage Configuration (Data Lake Landing Zone)

**Phase:** 2 (Data Acquisition)
**Objective:** Configure a secure, organized "Landing Zone" in Azure Blob Storage to host raw Olist e-commerce data before ingestion into Snowflake.

---

## 1. Infrastructure Configuration

### 1.1 Resource Group

- **Name:** `rg-olist-analytics-dev-central-india`
- **Region:** **Central India**
  - _Rationale:_ Co-located with Snowflake region to eliminate data egress fees.

### 1.2 Storage Account

- **Name:** `stolistanalyticsdev`
- **Type:** StorageV2 (General Purpose v2)
- **Performance:** Standard
  - _Rationale:_ Cost-effective for batch loading; Premium IOPS not required.
- **Redundancy:** LRS (Locally-redundant storage)
  - _Rationale:_ Source data is reproducible; LRS provides sufficient durability at lowest cost.
- **Hierarchical Namespace:** Disabled
  - _Rationale:_ Flat namespace is sufficient for `COPY INTO` patterns; reduces cost.

### 1.3 Container

- **Name:** `raw-landing`
- **Access Level:** Private
  - _Security:_ Access restricted to Storage Integrations (Snowflake) and SAS tokens.

### 1.4 Lifecycle Management (DataFinOps)

Automated tiering rules configured to optimize storage costs:

- **Hot Tier:** < 30 days (Ingestion & active processing)
- **Cool Tier:** 30-180 days (Infrequent access)
- **Archive Tier:** > 180 days (Historical retention)

---

## 2. Directory Architecture

Data is organized by **Source System** → **Entity** to support schema evolution and automated ingestion patterns.

**Structure:**

```text
raw-landing/
└── olist/                          # Source System
    ├── orders/                     # Entity
    │   └── olist_orders_dataset.csv
    ├── items/
    │   └── olist_order_items.parquet
    ├── customers/
    │   └── olist_customers_dataset.csv
    ├── payments/
    │   └── olist_order_payments_dataset.csv
    ├── products/
    │   └── olist_products_dataset.csv
    ├── sellers/
    │   └── olist_sellers_dataset.csv
    ├── reviews/
    │   └── olist_order_reviews.json
    ├── geolocation/
    │   └── olist_geolocation_dataset.csv
    └── category_translation/
        └── product_category_name_translation.csv
```
