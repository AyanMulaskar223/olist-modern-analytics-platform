## Data Quality Issues by Table

### 1. `raw_orders` - Order Transaction Data

#### 1.1 Missing Values

| **Issue Type**             | **Column**                                                                                             | **Issue Count** | **Percentage** | **Severity** | **Proposed Fix**                                                      | **Where to Fix**                    |
| -------------------------- | ------------------------------------------------------------------------------------------------------ | --------------- | -------------- | ------------ | --------------------------------------------------------------------- | ----------------------------------- |
| Missing delivery date      | `order_delivered_customer_date`                                                                        | 2,965           | 2.98%          | **High**     | Flag as incomplete delivery, exclude from delivery SLA metrics        | `stg_orders.sql` + `fct_orders.sql` |
| Missing carrier handoff    | `order_delivered_carrier_date`                                                                         | 1,783           | 1.79%          | Medium       | Flag for logistics analysis, calculate estimated carrier date         | `stg_orders.sql`                    |
| Missing approval timestamp | `order_approved_at`                                                                                    | 160             | 0.16%          | Low          | Impute with `order_purchase_timestamp` + 1 hour (business assumption) | `stg_orders.sql`                    |
| Missing core fields        | `order_id`, `customer_id`, `order_status`, `order_purchase_timestamp`, `order_estimated_delivery_date` | 0               | 0%             | **Critical** | ✅ No issues found                                                    | -                                   |

**Business Impact:**

- 2,965 orders (3%) missing delivery confirmation → Cannot calculate accurate delivery metrics
- Recommendation: Add `is_delivery_confirmed` flag, exclude from CSAT analysis

---

#### 1.2 Temporal Data Quality

**Future Timestamps:**
| **Issue Type** | **Column** | **Issue Count** | **Action** |
|----------------|------------|-----------------|------------|
| Future order dates | `order_purchase_timestamp` | 0 | ✅ No issues |

**Date Range Validation:**
| **Issue Type** | **Issue Count** | **Date Range** | **Action** |
|----------------|-----------------|----------------|------------|
| Orders before 2016-09-04 | 0 | - | ✅ No issues |
| Orders after 2018-10-17 | 0 | - | ✅ No issues |

**Finding:** All order dates fall within expected dataset range (2016-2018).

---

#### 1.3 Logical Date Sequence Issues

| **Issue Type**                     | **Issue Count** | **Severity** | **Proposed Fix**                                         | **Where to Fix**          |
| ---------------------------------- | --------------- | ------------ | -------------------------------------------------------- | ------------------------- |
| Delivered before shipped           | 23              | **High**     | Flag as data quality issue, exclude from logistics KPIs  | `int_orders_enriched.sql` |
| Delivered before approved          | 61              | **High**     | Flag as data quality issue, investigate in source system | `int_orders_enriched.sql` |
| Approved before purchased          | 0               | Critical     | ✅ No issues                                             | -                         |
| Estimated delivery before purchase | 0               | Critical     | ✅ No issues                                             | -                         |
