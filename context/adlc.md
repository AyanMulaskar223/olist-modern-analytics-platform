# Folder Structure

[What to keep in mind](https://www.notion.so/What-to-keep-in-mind-2d01bb84f4a480398c47c90d95063012?pvs=21)

- [ ] Published docs to github pages mkdocs and also dbt docs

## Name: Olist – Modern E-commerce Analytics Platform

**Subtitle (Highly Recommended)**

End-to-End Analytics Platform using Azure Blob, Snowflake, dbt, Power BI, Git & CI

**Folder/Repo: olist-modern-analytics-platform**

| Power BI workspace | Olist Analytics - PROD |
| ------------------ | ---------------------- |

# **🎯 Phase 1: Business Understanding & Requirements**

### 1) Business Problem

| **Field**                | **Details**                                                                                                                                                                                                                                                                                                                                             |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Business Domain          | E-Commerce Marketplace & Logistics                                                                                                                                                                                                                                                                                                                      |
| Business Problem         | Olist Lack a centralized, trusted analytics layer to track sales performance, customer behavior, seller contribution, regional demand, and delivery efficiency                                                                                                                                                                                          |
| Desired Business Outcome | Establish a **single source of truth analytics platform** that enables stakeholders to reliably track revenue and growth trends, identify top-performing categories, sellers, and regions, monitor delivery SLAs across states, analyze repeat customer behavior, and support fast, self-service, data-driven decisions through interactive dashboards. |

Business Context:

**Olist operates a multi-seller e-commerce marketplace in Brazil.**

**As the platform scaled, analytics evolved in a fragmented manner—data was accessed directly from raw transactional tables, metrics were redefined across teams, and reporting relied heavily on manual SQL queries and spreadsheets.**

This legacy analytics approach created **inconsistent KPIs, low data trust, and slow insight delivery**, limiting leadership’s ability to understand sales trends, customer retention, seller performance, and logistics efficiency.

To support growth and move toward a data-driven operating model, Olist requires a **modern analytics platform** that centralizes data, enforces trusted metrics, and enables fast, self-service analytics for business and operations teams.

| **Architecture Domain** | **Current State (Legacy Pain)**                                                      | **Target State (Your Solution)**                                                                |
| ----------------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| **Data Storage**        | Siloed **OLTP Transactional Tables** (Postgres); heavy read-load slows down the app. | Centralized **OLAP Data Warehouse** (Snowflake) optimized for analytical queries.               |
| **Ingestion Pipeline**  | Manual CSV extracts and ad-hoc scripts; frequent failures & stale data.              | Automated **ELT Pipeline** via Azure Blob Storage & Python; distinct "Raw" vs. "Curated" zones. |
| **Data Modeling**       | No defined schema; massive **"Spaghetti SQL"**queries joined at runtime.             | **Kimball Star Schema** modeled in **dbt** with version control, testing, and documentation.    |
| **Governance & Trust**  | **"Metric Drift"**: Every department calculates "Revenue" differently.               | **Single Source of Truth**: Metrics defined once in dbt/Power BI and reused everywhere.         |
| **Consumption Layer**   | Static, emailed Excel spreadsheets; 100% dependency on IT for changes.               | **Self-Service Power BI Dashboard**; Interactive, drill-down capable, and user-friendly.        |
| **Scalability**         | **Low**: System crashes with high data volume; manual fixes required.                | **High**: Cloud-native architecture scales compute instantly to handle millions of rows.        |

### 2) Key Business Questions

| **ID** | **Business Question**                                                                            | **Analytics Type** |
| ------ | ------------------------------------------------------------------------------------------------ | ------------------ |
| Q1     | How are total revenue and order volume trending over time?                                       | Descriptive        |
| Q2     | Which product categories generate the most revenue and orders?                                   | Descriptive        |
| Q3     | Which regions and states contribute most to revenue and orders?                                  | Descriptive        |
| Q4     | How efficient is order delivery performance across regions in terms of delivery time and delays? | Diagnostic         |
| Q5     | Which sellers contribute the most to revenue and order volume?                                   | Descriptive        |
| Q6     | What payment methods are most commonly used, and how do they impact order value?                 | Diagnostic         |
| Q7     | How many customers are repeat buyers versus new customers?                                       | Descriptive        |

### 3) KPI/Metrics

| ID     | Business Question                                                      | KPI Type   | KPI Name                        | KPI Definition                                    | Fact / Dim Tables Used    |
| ------ | ---------------------------------------------------------------------- | ---------- | ------------------------------- | ------------------------------------------------- | ------------------------- |
| **Q1** | How are total revenue and order volume trending over time?             | Primary    | Total Revenue                   | Sum of order item prices for delivered orders     | fct_orders, dim_date      |
| **Q1** |                                                                        | Primary    | Total Orders                    | Count of distinct orders delivered                | fct_orders                |
| **Q1** |                                                                        | Supporting | Avg Order Value (AOV)           | Total Revenue ÷ Total Orders                      | fct_orders                |
| **Q1** |                                                                        | Supporting | MoM Revenue Growth %            | (Current Month − Previous Month) ÷ Previous Month | fct_orders, dim_date      |
| **Q2** | Which product categories generate the most revenue and orders?         | Primary    | Revenue by Category             | Total Revenue grouped by product category         | fct_orders, dim_products  |
| **Q2** |                                                                        | Primary    | Orders by Category              | Count of orders per product category              | fct_orders, dim_products  |
| **Q2** |                                                                        | Supporting | Avg Price per Category          | Avg item price per category                       | fct_orders, dim_products  |
| **Q3** | Which regions and states contribute most to revenue and orders?        | Primary    | Revenue by State                | Total Revenue grouped by customer state           | fct_orders, dim_customers |
| **Q3** |                                                                        | Primary    | Orders by State                 | Count of orders per state                         | fct_orders, dim_customers |
| **Q3** |                                                                        | Supporting | Revenue % Contribution          | % share of total revenue by state                 | fct_orders                |
| **Q4** | How efficient is order delivery performance across regions?            | Primary    | Avg Delivery Time (Days)        | Avg days between order purchase and delivery      | fct_orders                |
| **Q4** |                                                                        | Primary    | Delivery Delay Rate %           | % of orders delivered after estimated date        | fct_orders                |
| **Q4** |                                                                        | Supporting | On-Time Delivery %              | % of orders delivered on or before estimate       | fct_orders                |
| **Q5** | Which sellers contribute the most to revenue and orders?               | Primary    | Revenue by Seller               | Total Revenue per seller                          | fct_orders, dim_sellers   |
| **Q5** |                                                                        | Primary    | Orders by Seller                | Count of orders per seller                        | fct_orders                |
| **Q5** |                                                                        | Supporting | Avg Revenue per Seller          | Revenue ÷ Orders per seller                       | fct_orders                |
| **Q6** | What payment methods are most used and how do they impact order value? | Primary    | Orders by Payment Type          | Count of orders per payment method                | fct_payments              |
| **Q6** |                                                                        | Primary    | Avg Order Value by Payment Type | Avg payment value per payment method              | fct_payments              |
| **Q6** |                                                                        | Supporting | Payment Share %                 | % distribution of payment methods                 | fct_payments              |
| **Q7** | How many customers are repeat buyers vs new customers?                 | Primary    | Repeat Customers                | Customers with ≥ 2 orders                         | fct_orders, dim_customers |
| **Q7** |                                                                        | Primary    | New Customers                   | Customers with only 1 order                       | fct_orders, dim_customers |
| **Q7** |                                                                        | Supporting | Repeat Purchase Rate            | Repeat Customers ÷ Total Customers                | fct_orders                |

### 4) Data Scope and Sources

## **1. Project Scope**

| Data Element          | Details                                     |
| --------------------- | ------------------------------------------- |
| Date Range            | 2016–2018 (full historical dataset)         |
| Geographic Scope      | All Brazilian states                        |
| Data Refresh Schedule | Daily at 06:00 UTC (simulated batch design) |
| Data Latency Target   | ≤ 24 hours                                  |
| Historical Retention  | Full history retained                       |
| Source Type           | Batch files (CSV → Snowflake)               |

### **✅ In-Scope**

- **Sales & Order Performance:** Tracking revenue, order volume, and growth trends.
- **Customer Behavior:** Analysis of New vs. Repeat purchase patterns.
- **Seller Contribution:** Ranking and performance analysis of sellers.
- **Regional Demand:** Geospatial analysis at the State and City levels.
- **Delivery Logistics:** Measuring efficiency, shipping times, and delay rates.
- **Payment Analysis:** Usage breakdown and impact on Average Order Value (AOV).

### **❌ Out-of-Scope**

- **Customer Reviews & Sentiment:** Text mining of review comments.
- **Fraud Detection:** Anomaly detection for credit card transactions.
- **Real-Time Streaming:** Sub-second latency data ingestion.
- **Marketing Attribution:** Tracking ad spend or campaign ROI.

---

## **2. Source Data Inventory (Raw Layer)**

| **Source File / Table**                     | **Description**                               | **Purpose in Analysis**                                         |
| ------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------- |
| **`olist_orders_dataset.csv`**              | Order lifecycle details (status, timestamps). | Core fact table for sales and delivery timelines.               |
| **`olist_order_items_dataset.csv`**         | Products within each order (price, freight).  | Calculation of Revenue, Quantity, and Freight costs.            |
| **`olist_customers_dataset.csv`**           | Customer identifiers and location keys.       | Customer demographics and repeat buyer analysis.                |
| **`olist_sellers_dataset.csv`**             | Seller details and locations.                 | Seller performance and geographic contribution.                 |
| **`olist_products_dataset.csv`**            | Product master data (dimensions, weight).     | Product category and shipping cost analysis.                    |
| **`olist_order_payments_dataset.csv`**      | Payment methods, installments, and value.     | Analysis of payment preferences and AOV.                        |
| **`olist_geolocation_dataset.csv`**         | Zip Code prefix to City/State mapping.        | Enabling geographic visualization and Row Level Security (RLS). |
| **`product_category_name_translation.csv`** | Portuguese to English category translations.  | Ensuring reporting is business-friendly and readable.           |

---

## **3. Dashboard Focus Areas**

- **💰 Revenue & Orders:** Track overall sales performance, Month-over-Month (MoM) growth, and total volume.
- **👥 Customers:** Distinguish between one-time buyers and loyal (repeat) customers to calculate retention rates.
- **📦 Sellers:** Identify top-performing sellers and their contribution to total platform revenue.
- **🌍 Geography:** Analyze high-demand regions using State and City level heatmaps.
- **🚚 Delivery:** Monitor logistics KPIs, including Average Delivery Days and "% of Orders Delayed".
- **💳 Payments:** Understand consumer financing behavior (Installments) and preferred payment types (Credit Card vs. Boleto).

---

## **4. Data Strategy & Architecture**

| **Aspect**              | **Decision / Strategy**                                                                             |
| ----------------------- | --------------------------------------------------------------------------------------------------- |
| **Ingestion Method**    | Python Script → **Azure Blob Storage** → Snowflake External Stage                                   |
| **Load Frequency**      | **Full Load** (Initial History) + Incremental Simulation capability                                 |
| **Transformation Tool** | **dbt (Data Build Tool)** covering `Staging` → `Intermediate` → `Marts` layers                      |
| **Schema Evolution**    | Controlled via **dbt models**; changes are version-controlled in Git                                |
| **Data Quality**        | Automated testing for **Row Counts**, **Null Values**, and **Referential Integrity** (Foreign Keys) |

### 5) Business Rules

### Purpose

Business rules define how Olist’s data should be interpreted, filtered, and calculated so that all dashboards, KPIs, and analyses remain consistent, trusted, and business-aligned.

These rules act as a contract between business stakeholders and the data team.

---

## A) Core Business Rules (Notion Table)

| Rule Name                  | Description                                             | Example (Olist Context)                           |
| -------------------------- | ------------------------------------------------------- | ------------------------------------------------- |
| Delivered Orders Only      | Only completed deliveries count toward revenue and KPIs | Include orders where order_status = 'delivered'   |
| Revenue Recognition        | Revenue is recognized only after delivery               | Order placed ≠ revenue; delivered order = revenue |
| Repeat Customer Definition | Defines what qualifies as a repeat buyer                | Customer with ≥ 2 delivered orders                |
| Delivery Delay Logic       | Defines what counts as a late delivery                  | actual_delivery_date > estimated_delivery_date    |
| Geographic Mapping         | How customers are mapped to regions/states              | Use customer_zip_code_prefix → state mapping      |
| Payment Attribution        | How payments are linked to orders                       | Multiple payments summed per order                |
| Time Zone Standard         | Consistent date interpretation                          | All dates interpreted in Brazil local time        |
| Outlier Handling           | How extreme values are treated                          | Orders with very high value flagged, not removed  |

---

## B) KPI-Focused Business Rules

| Rule Type            | Rule                                           | Purpose                                   |
| -------------------- | ---------------------------------------------- | ----------------------------------------- |
| Sales Calculation    | Include only delivered orders in Total Revenue | Avoid inflated sales from canceled orders |
| Order Count          | Count distinct delivered orders                | Standardize order metrics                 |
| Average Order Value  | AOV = Revenue ÷ Delivered Orders               | Prevent skew from canceled orders         |
| Repeat Customer      | ≥ 2 delivered orders per customer              | Consistent customer segmentation          |
| Delivery Performance | Delay = Actual − Estimated delivery date       | Measure logistics efficiency              |
| Payment Analysis     | Sum all payment values per order               | Accurate revenue attribution              |

---

## C) Implementation Mapping (Very Important for ADLC)

| #   | Rule Name             | Description                           | Implemented In              |
| --- | --------------------- | ------------------------------------- | --------------------------- |
| 1   | Delivered Orders Only | Filter orders with status = delivered | dbt: stg_orders.sql         |
| 2   | Revenue Recognition   | Revenue counted post-delivery         | dbt: fct_orders.sql         |
| 3   | Repeat Customer Logic | ≥ 2 delivered orders                  | dbt: dim_customers.sql      |
| 4   | Delivery Delay Flag   | Late vs on-time delivery              | dbt: fct_orders.sql         |
| 5   | Payment Aggregation   | Sum multiple payments per order       | dbt: int_order_payments.sql |
| 6   | Profit Calculation    | Profit = Revenue − Cost               | Power BI Measure            |
| 7   | Outlier Flagging      | Flag extreme order values             | dbt: intermediate model     |

### 6) Time Windows & Reporting Frequency

## 6.1 Defined Time Windows (Olist Project)

| **Type**                 | **Definition**                           | **Purpose**                             | **Implementation**            |
| ------------------------ | ---------------------------------------- | --------------------------------------- | ----------------------------- |
| Static Historical Window | Sep 2016 – Oct 2018 (full Olist dataset) | Analyze complete historical performance | dbt model filtering           |
| Rolling Window           | Last 12 Months (dynamic)                 | Monitor recent business trends          | Power BI relative date filter |
| Reporting Frequency      | Monthly                                  | Standard business reporting cadence     | Power BI Service refresh      |

---

## 6.2 Analysis Usage by Time Window

| **Analysis Type**       | **Time Window**        | **Purpose**                           | **Notes**               |
| ----------------------- | ---------------------- | ------------------------------------- | ----------------------- |
| Revenue & Orders Trend  | Monthly (Full History) | Identify growth and decline patterns  | Primary executive view  |
| Delivery Performance    | Monthly (Full History) | Compare delivery efficiency over time | Diagnostic analysis     |
| Customer Retention      | Rolling 12 Months      | Identify repeat vs new customers      | Dynamic business metric |
| Payment Method Analysis | Monthly                | Compare AOV by payment type           | Stable reporting        |

### 5) Expected Deliverables

## Data Platform Deliverables (Snowflake + dbt)

| Deliverable                   | Description                                                | Why It Matters                               |
| ----------------------------- | ---------------------------------------------------------- | -------------------------------------------- |
| RAW Tables                    | Original Olist CSV/Parquet/JSON data loaded into Snowflake | Preserves source-of-truth and auditability   |
| Staging Models (stg\_\*)      | Cleaned, standardized, type-casted tables                  | Ensures consistent column names & data types |
| Intermediate Models (int\_\*) | Business logic joins and transformations                   | Centralizes reusable logic                   |
| Marts Layer (fct*\*, dim*\*)  | Star schema analytics tables                               | Enables fast BI and analytics                |
| Surrogate Keys                | Generated using dbt for dimensions                         | Improves joins and performance               |
| Data Quality Tests            | dbt tests for freshness, uniqueness, relationships         | Prevents silent data issues                  |
| Data Contracts                | Enforced schema expectations                               | Prevents breaking downstream reports         |

---

## Analytics & BI Deliverables (Power BI)

| Deliverable              | Description                                    | Why It Matters                 |
| ------------------------ | ---------------------------------------------- | ------------------------------ |
| Power BI Semantic Model  | Star schema model with relationships           | Enables self-service analytics |
| Measures Table           | Centralized DAX measures (\_Measures)          | Consistent KPI logic           |
| Power BI Dashboards      | 2–3 report pages aligned to business questions | Communicates insights visually |
| KPI Cards                | Primary KPIs (Revenue, Orders, Customers)      | Executive summary view         |
| Diagnostic Visuals       | Delivery delay, payment analysis, churn views  | Supports “why” questions       |
| Time Intelligence        | YoY, MoM, YTD calculations                     | Trend analysis                 |
| RLS (Row Level Security) | Region/Seller based access control             | Enterprise-ready security      |
| Data Dictionary Page     | Auto-generated metadata (INFO.VIEW)            | Improves model understanding   |

## Data Quality & Governance Deliverables

| Deliverable             | Description                                      |
| ----------------------- | ------------------------------------------------ |
| Data Quality Checklist  | Validation rules for raw, staging, marts         |
| Outlier Strategy        | Flag-based outlier handling (not blind deletion) |
| Business Rules Document | Revenue logic, customer definitions, filters     |
| Schema Drift Protection | Contracts + Power Query column selection         |

---

## Automation, CI & DevOps Deliverables

| Deliverable       | Description                        |
| ----------------- | ---------------------------------- |
| Git Repository    | Full project under version control |
| GitHub Actions CI | Automated dbt tests on PR          |
| Branch Strategy   | Feature branches + main branch     |
| SQLFluff Linting  | SQL quality enforcement            |
| Deployment Docs   | Manual promotion steps documented  |

---

## Documentation & Framework Deliverables

| Deliverable               | Description                             |
| ------------------------- | --------------------------------------- |
| ADLC Framework (Notion)   | End-to-end documented lifecycle         |
| Architecture Diagram      | Azure Blob → Snowflake → dbt → Power BI |
| Business Requirement Docs | Problems, questions, KPIs               |
| KPI Definitions           | SQL + DAX formulas                      |
| Reusability Notes         | What can be reused in future projects   |

---

## Business Impact Deliverables

| Deliverable           | Description                            |
| --------------------- | -------------------------------------- |
| Before vs After Table | Manual reporting → automated analytics |
| Time Saved Metrics    | Faster reporting & ad-hoc analysis     |
| Trust Improvement     | Single Source of Truth                 |
| Decision Enablement   | Faster insights for stakeholders       |

---

## Final Project Output Summary (One-Line)

> “Built an end-to-end modern analytics platform using Azure Blob, Snowflake, dbt, and Power BI that delivers trusted KPIs, diagnostic insights, and reusable data models with enterprise-grade documentation and CI.”

---

##

### 6) Stakeholders and Roles

| **Stakeholder Role**                      | **Responsibilities**                        | **Data Needs**                                | **Primary Outputs** |
| ----------------------------------------- | ------------------------------------------- | --------------------------------------------- | ------------------- |
| Business Stakeholder (E-commerce Manager) | Owns revenue, orders, and growth            | Revenue trends, category & region performance | Power BI Dashboard  |
| Operations Manager                        | Oversees delivery and logistics performance | Delivery time, delays, regional efficiency    | Power BI Dashboard  |
| Sales / Seller Manager                    | Manages seller performance                  | Seller contribution, order volume             | Power BI Dashboard  |
| Finance / Payments Analyst                | Tracks revenue and payment behavior         | AOV, payment methods, order value             | Power BI Dashboard  |
| Data Analyst (You)                        | Builds insights and dashboards              | Clean data, business rules                    | All deliverables    |
| Analytics Engineer (You – Project Scope)  | Models data and enforces logic              | dbt models, tests                             | Snowflake tables    |

### 7) Success Criteria

### Business & Analytics Success

| Area                   | Success Criteria                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------- |
| Business Adoption      | Dashboard answers all defined business questions                                       |
| Decision Making        | Stakeholders can identify trends, top contributors, and issues without analyst support |
| KPI Accuracy           | All KPIs match documented business definitions                                         |
| Single Source of Truth | Metrics are consistent across Power BI, SQL, and documentation                         |

---

### Data Engineering & Modeling Success

![🧱](https://fonts.gstatic.com/s/e/notoemoji/16.0/1f9f1/72.png)

| Area             | Success Criteria                                        |
| ---------------- | ------------------------------------------------------- |
| Data Pipeline    | Data flows from Azure Blob → Snowflake without failures |
| Transformations  | Raw → Staging → Marts models built using dbt            |
| Data Quality     | dbt tests pass (uniqueness, not null, relationships)    |
| Schema Stability | Schema changes do not break downstream reports          |
| Freshness        | Data is updated within defined latency SLA              |

---

### Automation & CI Success

![⚙️](https://fonts.gstatic.com/s/e/notoemoji/16.0/2699_fe0f/72.png)

| Area             | Success Criteria                                  |
| ---------------- | ------------------------------------------------- |
| CI Pipeline      | dbt tests run automatically via GitHub Actions    |
| Failure Handling | Pipeline fails clearly on test or schema errors   |
| Version Control  | All SQL, dbt, and Power BI (.pbip) tracked in Git |
| Reproducibility  | Project can be rebuilt end-to-end from repository |

---

### Power BI & Performance Success

![🎨](https://fonts.gstatic.com/s/e/notoemoji/16.0/1f3a8/72.png)

| Area             | Success Criteria                                       |
| ---------------- | ------------------------------------------------------ |
| Load Performance | Report pages load in under 5 seconds                   |
| Model Design     | Star Schema enforced (Facts central, Dims surrounding) |
| Semantic Layer   | Measures centralized and reusable                      |
| Security         | RLS works correctly for different users                |
| UX               | Users can self-serve without confusion                 |

---

### Documentation & Maintainability

![🧠](https://fonts.gstatic.com/s/e/notoemoji/16.0/1f9e0/72.png)

| Area              | Success Criteria                                         |
| ----------------- | -------------------------------------------------------- |
| Documentation     | ADLC, KPIs, data models, and rules fully documented      |
| Onboarding        | New analyst can understand pipeline within 1 day         |
| Change Tracking   | All changes traceable via Git commits                    |
| Knowledge Sharing | Business logic is clearly explained (not hidden in code) |

---

### Business Impact Metrics (Portfolio-Friendly)

![📈](https://fonts.gstatic.com/s/e/notoemoji/16.0/1f4c8/72.png)

| Before                 | After                  | Impact                            |
| ---------------------- | ---------------------- | --------------------------------- |
| Manual Excel reporting | Automated ELT pipeline | 90% reduction in reporting effort |
| Metric inconsistencies | Single Source of Truth | 100% KPI alignment                |
| Slow ad-hoc analysis   | Star Schema + Power BI | Questions answered in minutes     |
| No validation          | dbt tests + CI         | Trustworthy analytics             |

---

### Final Project Sign-Off Criteria

![✅](https://fonts.gstatic.com/s/e/notoemoji/16.0/2705/72.png)

The project is considered successful when:

- All business questions are answered via dashboards
- All dbt models and tests pass in CI
- Power BI reports are performant and secure
- Documentation is complete and reusable
- Business value is clearly demonstrated

---

### Interview-Ready Line

![💬](https://fonts.gstatic.com/s/e/notoemoji/16.0/1f4ac/72.png)

> “I defined clear success criteria across business impact, data quality, automation, and performance to ensure the project was production-ready, not just a demo.”

---

### **Category A: Business Impact (The "Value" Metrics)**

_Did we solve the business problem?_

| Metric               | Target                                 | Why it matters                                                                                                 | Validation Method                                     |
| -------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| **User Adoption**    | **Daily Active Use** by Logistics Team | The dashboard isn't just "pretty"; it is part of their morning routine.                                        | Power BI Usage Metrics Report.                        |
| **Trust / Accuracy** | **100% Match** with Bank Data          | If the "Revenue" number in Power BI differs from the Bank Statement by even $1, the CFO will stop using it.    | Reconciliation test: `SUM(Sales)` vs `Finance_Excel`. |
| **Time-to-Insight**  | **< 10 Minutes**                       | Before, it took 2 days to get a report. Now, they can find the answer in minutes.                              | Interview with the Logistics Manager.                 |
| **Self-Service %**   | **50% Reduction** in Ad-Hoc Requests   | Stakeholders should be able to filter the dashboard themselves instead of asking you for a new CSV every time. | Count of "Can you pull this data?" emails.            |

### **Category B: Technical Performance (The "Health" Metrics)**

_Is the system stable, fast, and scalable?_

| Metric                 | Target                       | Why it matters                                                                                     | Validation Method                             |
| ---------------------- | ---------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| **Data Freshness**     | **Daily (T-1)** by 8:00 AM   | Stakeholders need yesterday's numbers before their 9 AM standup meeting.                           | Check `last_refreshed` timestamp in Power BI. |
| **Dashboard Speed**    | **< 4 Seconds**Load Time     | If a visual takes >10 seconds to load, users assume it's broken and close the tab.                 | Power BI Performance Analyzer.                |
| **Pipeline Stability** | **99% Success Rate**         | The dbt/Snowflake pipeline should not fail more than once per quarter.                             | Azure Data Factory / Snowflake History Logs.  |
| **Data Quality**       | **0 Critical Test Failures** | If a `Primary Key` is duplicated or a `Price` is negative, the pipeline should stop automatically. | `dbt test` results (Severity: Error).         |

### 8) Tools and Technologies

| **Stage**       | **Tool**           | **Purpose**                                         |
| --------------- | ------------------ | --------------------------------------------------- |
| Data Ingestion  | Azure Blob Storage | Raw data landing zone for Olist datasets            |
| Storage         | Snowflake          | Central cloud data warehouse                        |
| Transformation  | dbt Fusion         | Data modeling, business logic, tests, documentation |
| Analytics Layer | dbt Marts          | Fact & dimension tables for BI consumption          |
| Visualization   | Power BI           | Semantic model, dashboards, KPI tracking            |
| Version Control | Git + GitHub       | Code versioning and collaboration                   |
| CI / Validation | GitHub Actions     | Automated dbt runs and tests                        |
| Documentation   | Notion             | ADLC tracking, business rules, decisions            |

[Examples](https://www.notion.so/Examples-2cd1bb84f4a481f99a44d724b13a3a28?pvs=21)

# **📊 Phase 2: Data Acquisition & Source Integration**

[Phase 1: Summary](https://www.notion.so/Phase-1-Summary-2cd1bb84f4a48170bc1fd2eafab92962?pvs=21)

[DataOps Strategy](https://www.notion.so/DataOps-Strategy-2cd1bb84f4a481748206fd191dbbd9e3?pvs=21)

### 🎯 **Objective**

To load, validate, and organize raw data into the **Snowflake RAW schema**, ensuring it’s clean, traceable, and version-controlled before transformation begins in dbt.

### DataFinOps Strategy

### **💸 DataFinOps Strategy (Cost Design)**

- [ ] [ ] **Define Warehouse Sizing Policy:**
  - **Dev/Loading:** Assign `X-SMALL` (1 credit/hr).
  - **Prod Transformation:** Assign `SMALL` (2 credits/hr) or `MEDIUM` only if data volume > 10GB.
  - **Justification:** Document why these sizes were chosen based on estimated scan volume.
- [ ] [ ] **Define Storage Lifecycle Policy (Azure):**
  - **Hot Tier:** Current data (< 30 days).
  - **Cool Tier:** Data accessed monthly (30-180 days).
  - **Archive Tier:** Compliance data (> 180 days).
  - **Action:** Enable "Lifecycle Management" rules in Azure Storage Account settings.
- [ ] [ ] **Select Data Formats:**
  - **Raw Layer:** Mandate **Parquet** or **Avro** (Compressed) instead of CSV/JSON to reduce storage & scan costs.
- [ ] [ ] **Plan Incremental Strategy:**
  - **Fact Tables:** Identify all Fact tables > 1M rows. Mark them for `materialized='incremental'` in dbt.
  - **Snapshots:** Define validity strategy (e.g., `check` vs `timestamp`) to minimize row churning.
- [ ] [ ] **Configure Time Travel Retention:**
- *Action:* Set **Data Retention = 0 days** for Dev/Staging schemas. Keep 1-7 days only for `PROD_MARTS`.
- *Rationale:* We don't need to recover yesterday's test data.
- [ ] [ ] **Configure "Aggressive" Auto-Suspend:**
  - *Action:* Run SQL command: `ALTER WAREHOUSE DEV_WH SET AUTO_SUSPEND = 60;`
  - *Impact:* Stops billing 1 minute after query finishes (vs. default 10 mins).

### **2. Snowflake Transient Tables**

- **The Logic:** Snowflake keeps "Fail-safe" backups (7 days) for all tables, which costs storage. Staging data doesn't need backups because it can be re-loaded from Azure.
- **The FinOps Move:** Set transient: true in dbt_project.yml for all staging and intermediate models.
  - *Result:* No Fail-safe costs for temporary data.
- _Code:_
- [ ] [ ] **Apply "Shift-Left" Filtering:**
  - *Action:* Add `WHERE` clauses in Staging models (e.g., `order_date >= '2024-01-01'`) to limit data volume early.
- [ ] [ ] **Set Resource Monitors:**
  - *Action:* Create a Snowflake Resource Monitor to **Suspend & Notify** at 80% of monthly budget (e.g., 20 Credits).
  - [ ] **Zero-Copy Cloning for Dev Environments:**
  - *Action:* Instead of loading raw data twice (paying compute), use `CLONE` to create Dev environments from Prod.
  - *Rationale:* Instant environment setup with $0 storage cost.
  ### **3. "Slim CI" (The GitHub Action Saver)**
  - **The Logic:** When you open a Pull Request to change *one* model, standard CI runs *all* models. This wastes credits.
  - **The FinOps Move:** Configure dbt to run only modified models.
    - *Command:* dbt build --select state:modified+
    - *Result:* Drastically reduces the compute cost of your CI pipeline.
  ### **2. Query Timeouts**
  - **The Logic:** Sometimes BI tools hang or queries get stuck.
  - **The FinOps Move:** Set STATEMENT_TIMEOUT_IN_SECONDS = 3600 (1 hour) on the Warehouse level. Kill the query automatically before it drains the wallet.

### \*) AI Assistant & Workflow

### Custom Chat Modes

# **1) `Snowflake_Infra_Architect`**

## ✔ What This Mode Will Do

This mode is responsible for **everything related to Snowflake infrastructure setup**, including:

### **RBAC / SECURITY**

- Create human roles (`ANALYTICS_ROLE`, `REPORTER_ROLE`)
- Create service roles (`LOADER_ROLE`, `CI_SERVICE_ROLE`)
- Build role hierarchy & apply least privilege
- Assign users to correct roles safely

### **COMPUTE (WAREHOUSES)**

- Create Loading, Transform, Reporting warehouses
- Configure autosuspend, autresume, scaling policy
- Add comments, cost-optimised configs

### **DATABASE ARCHITECTURE**

- RAW_DB (landing zone)
- ANALYTICS_PROD (gold layer)
- ANALYTICS_DEV (zero-copy clone)
- COMMON_DB (utility tables)

### **SCHEMAS**

- RAW schemas (LANDING, SYSTEM schemas)
- Analytics schemas (STAGING, INTERMEDIATE, MARTS)

### **GOVERNANCE / COST**

- Resource monitors
- Time Travel configuration
- Fail-safe best practices
- Warehouse cost isolation

### **What NOT to do**

- No Azure blob storage
- No ingestion
- No dbt modeling
- No loading scripts

# **2)`Snowflake_Data_Loader`**

## ✔ What This Mode Will Do

This mode handles **all ingestion, staging-area setup, metadata creation, and load audit logic**, including:

### **FILE FORMATS**

- Create CSV / JSON file formats
- Handle delimiters, quotes, skip headers, etc.

### **STAGES (EXTERNAL OR INTERNAL)**

- Create stages (internal only — Azure not included)

### **TABLE CREATION**

- Create raw tables using:
  - `USING TEMPLATE`
  - Manual DDL if needed

### **COPY INTO Ingestion**

- Build patterns for folder/file matching
- Add match-by-column-name logic
- Add error handling (`RETURN_ERRORS`, `SKIP_FILE`, etc.)

### **LOAD METADATA**

Automatically manage:

- `_source_file`
- `_loaded_at`
- `_file_row_number`
- `_load_batch_id`

### **DATA VALIDATION**

- Row count checks
- Load history checks
- Data anomaly detection SQL

## Data Quality Checks on Tables

- Outlier detection (numeric / date anomalies)
- Null Checks
- Duplicate checks
- Triming Checks and Cleaning Check
- Categorial Checks

# **3)`Snowflake_Debug_Optimizer`**

### **Role:** Debugging, error resolution, ingestion performance, metadata QC\*\*

Used when ingestion fails, loads incorrectly, or performance drops.

---

## **What This Mode Does in Phase 2**

### ✔ Fixes ingestion errors:

- Column mismatch
- Encoding errors
- File corruption
- Incorrect formats

### ✔ Improves COPY performance:

- Pattern tuning
- Warehouse tuning

### ✔ Improves metadata quality:

- Detects duplicate loads
- Detects missing rows
- Detects corrupted data

### ✔ Sets best practices for ingestion scaling:

- Incremental loading
- Multi-file loading
- Caching optimizations

### 1) Data Source Register

> Purpose:

> Create a single source of truth for where data comes from, how often it changes, and who owns it, before ingestion into Snowflake.

| Source Name                        | Description                                                                               | Format | Frequency                      | Owner          |
| ---------------------------------- | ----------------------------------------------------------------------------------------- | ------ | ------------------------------ | -------------- |
| olist_orders                       | Order lifecycle data including order status, purchase timestamp, approval, delivery dates | CSV    | One-time (Historical Snapshot) | Olist / Kaggle |
| olist_order_items                  | Line-item level data for each order (products, sellers, price, freight)                   | CSV    | One-time (Historical Snapshot) | Olist / Kaggle |
| olist_customers                    | Customer identifiers and geographic information (ZIP, city, state)                        | CSV    | One-time (Historical Snapshot) | Olist / Kaggle |
| olist_products                     | Product catalog with category and physical attributes                                     | CSV    | One-time (Historical Snapshot) | Olist / Kaggle |
| olist_sellers                      | Seller master data including seller location                                              | CSV    | One-time (Historical Snapshot) | Olist / Kaggle |
| olist_payments                     | Payment method, installments, and payment value per order                                 | CSV    | One-time (Historical Snapshot) | Olist / Kaggle |
| olist_geolocation                  | ZIP code to latitude/longitude mapping                                                    | CSV    | One-time (Reference Data)      | Olist / Kaggle |
| olist_product_category_translation | Portuguese → English product category mapping                                             | CSV    | One-time (Reference Data)      | Olist / Kaggle |

### 2) Naming Conventions

# 📏 Governance & Naming Standards

> Goal: Maintain strict consistency across the full stack.
>
> - **SQL/Snowflake:** `UPPER_SNAKE_CASE` (To avoid quoting identifiers).
> - **Python/dbt:** `lower_snake_case` (Industry standard).
> - **Azure/Git:** `kebab-case` (Lowercase with hyphens).
> - **Power BI:** `Title Case` (User-friendly natural language).

### **1. ☁️ Azure Infrastructure (The Lake)**

_Azure enforces lowercase for many resources. Do not fight this._

| **Object**          | **Pattern**                     | **Example**                        |
| ------------------- | ------------------------------- | ---------------------------------- |
| **Resource Group**  | `rg-[project]-[env]-[region]`   | `rg-retail-dev-eus2`               |
| **Storage Account** | `st[project][env]` (No chars)   | `stretailanalyticsprod`            |
| **Containers**      | `[content]-[layer]`             | `raw-landing`, `archive-processed` |
| **File Path**       | `[source]/[table]/v=[version]/` | `stripe/orders/v=1/`               |
| **Files**           | `[table]_[timestamp].csv`       | `orders_20251025.csv`              |

### **2. ❄️ Snowflake (The Warehouse)**

_Strictly UPPERCASE to ensure SQL queries don't need double quotes `""`._

| **Object**         | **Pattern**            | **Example**                           |
| ------------------ | ---------------------- | ------------------------------------- |
| **Warehouse**      | `[FUNCTION]_WH_[SIZE]` | `LOADING_WH_XS`, `TRANSFORM_WH_S`     |
| **Database**       | `[LAYER]_DB`           | `RAW_DB`, `ANALYTICS_PROD`            |
| **Schema (Raw)**   | `[SOURCE_SYSTEM]`      | `STRIPE`, `SALESFORCE`                |
| **Schema (Marts)** | `[DOMAIN]` or `MARTS`  | `FINANCE`, `MARKETING`, `MARTS`       |
| **Role (Service)** | `[TOOL]_USER_ROLE`     | `DBT_CLOUD_ROLE`, `POWERBI_READ_ROLE` |
| **Role (Human)**   | `[JOB]_ROLE`           | `ANALYTICS_ROLE`                      |

### **3. 🟧 dbt (The Transformation)**

_Follows dbt Labs style guide. Strictly lowercase._

| **Layer**        | **File Prefix** | **Structure**                    | **Example**                                          |
| ---------------- | --------------- | -------------------------------- | ---------------------------------------------------- |
| **Sources**      | `src_`          | `src_[source].yml`               | `src_stripe.yml`                                     |
| **Staging**      | `stg_`          | `stg_[source]__[table].sql`      | `stg_stripe__payments.sql` (Note: double underscore) |
| **Intermediate** | `int_`          | `int_[entity]_[verb].sql`        | `int_orders_joined.sql`                              |
| **Facts**        | `fct_`          | `fct_[process/event].sql`        | `fct_orders.sql`, `fct_monthly_revenue.sql`          |
| **Dimensions**   | `dim_`          | `dim_[entity].sql`               | `dim_customers.sql`, `dim_products.sql`              |
| **Bridge**       | `bridge_`       | `bridge_[table_a]_[table_b].sql` | `bridge_orders_tags.sql`                             |

### **4. 📊 Power BI (The Presentation)**

_Optimized for Q&A, AI, and Business Users. No underscores._

| **Object**         | **Pattern**                  | **Example**                                        |
| ------------------ | ---------------------------- | -------------------------------------------------- |
| **Workspace**      | `[Project] - [Env]`          | `Sales Analytics - PROD`                           |
| **Semantic Model** | `[Domain] Data Model`        | `Retail Sales Data Model`                          |
| **Tables**         | `[Entity]` (Singular/Plural) | `Customer`, `Sales`, `Date` (Remove `dim_`/`fct_`) |
| **Key Columns**    | `[Entity] ID`                | `Customer ID`, `Order ID`                          |
| **Date Columns**   | `[Entity] Date`              | `Order Date`, `Ship Date`                          |
| **Measures**       | `[Name]` (Clean)             | `Total Revenue`, `YoY Growth %`                    |
| **Tech Folders**   | `_Technical`                 | Folder for `_Last Refresh`, `_Sort Columns`        |

### **5. 🐙 Git & Version Control**

_Optimized for CLI and Windows/Linux compatibility._

| **Object**         | **Pattern**               | **Example**                  |
| ------------------ | ------------------------- | ---------------------------- |
| **Repo Name**      | `[project]-data-pipeline` | `retail-analytics-pipeline`  |
| **Main Branch**    | `main`                    | `main`                       |
| **Feature Branch** | `feature/[ticket]-[desc]` | `feature/dt-101-add-stripe`  |
| **Fix Branch**     | `fix/[ticket]-[desc]`     | `fix/dt-105-cast-error`      |
| **Commit Msg**     | `[type]: [description]`   | `feat: add fct_orders model` |

---

### **6. 🧠 dbt Semantic Layer (MetricFlow)**

_Optimized for readability by Business Users and AI Agents._

| **Object**         | **Pattern**                    | **Example**                           | **Why?**                                                                                 |
| ------------------ | ------------------------------ | ------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Semantic Model** | `[entity_name]` (Plural)       | `orders.yml`, `customers.yml`         | Maps 1:1 to a logical concept, usually a Mart table.                                     |
| **Entity (Keys)**  | `[entity_name]`(Singular)      | `order`, `customer`, `product`        | These act as the "Join Keys". Must be unique across the project.                         |
| **Dimensions**     | `[attribute_name]`             | `status`, `country`, `is_churned`     | Descriptive attributes. Avoid `dim_` prefix here.                                        |
| **Time Dimension** | `[event]_at` or `[event]_date` | `ordered_at`, `created_date`          | Explicitly states the timeline. `metric_time` is the system default.                     |
| **Measures**       | `[aggregation]_[column]`       | `sum_amount`, `count_id`, `min_price` | **Technical building blocks.** Not for end users. Prefix helps distinguish from metrics. |
| **Metrics**        | `[business_concept]`           | `total_revenue`, `aov`, `churn_rate`  | **The Final Product.** Clean, business-friendly names. No prefixes                       |

### 📝 To-Do: How to Enforce This

_Add this task to your Phase 3 or 4 checklist._

- [ ] [ ] **Create `docs/NAMING_CONVENTIONS.md`**
  - *Action:* Copy the tables above into this file in your GitHub repo.
  - *Reason:* When you use GitHub Copilot, you can reference this file (`@docs/NAMING_CONVENTIONS.md`) so the AI automatically names your files correctly.

### 3) Azure Blob Storage Setup (done)

> Goal: Create a secure, organized cloud storage location to act as the "Landing Zone" for raw data before it hits Snowflake.

### **✔ 2.1 Storage Infrastructure**

- [ ] [ ] **Create Resource Group**
  - *Action:* Create a new group named `rg-portfolio-data` to keep project resources isolated.
  - *Region:* Select the **exact same region** as your Snowflake account (e.g., East US 2) to avoid data transfer fees.
- [ ] [ ] **Create Storage Account**
  - *Performance:* `Standard` (Premium is unnecessary for this).
  - *Redundancy:* `LRS` (Locally-redundant storage) to minimize costs.
  - *Access Tier:* `Hot` (Best for active projects).
  - *Hierarchical Namespace:* **Disabled** (standard Blob) is fine for personal projects, or **Enabled** (Data Lake Gen2) if you want to demonstrate enterprise skills.
- [ ] [ ] **Apply Metadata Tags**
  - `Project`: `[Your Project Name]`
  - `Environment`: `Dev`

### **✔ 2.2 Container & Folder Architecture**

- [ ] [ ] **Create Main Container**
  - *Name:* `raw-landing`
  - *Public Access Level:* **Private (no anonymous access)**.
- [ ] [ ] **Create Archive Container** (Optional best practice)
  - *Name:* `archive-processed`
- [ ] [ ] **Implement Directory Hierarchy**
  - *Standard:* `container / source_system / entity / YYYY / MM / file.csv`
  - *Task:* Create folder shells for your specific data:Plaintext
    ```jsx
    raw-landing/
    ├── stripe/
    │   ├── payments/
    │   └── customers/
    └── google_analytics/
        └── page_views/
    ```

### **✔ 2.3 Naming Conventions & Governance**

- [ ] [ ] **Define File Naming Rules** (Write these in your project README)
  - Use `snake_case` only (no spaces).
  - Include data extraction date in filename.
  - *Format:* `entity_extract_YYYY_MM_DD.csv`
  - *Example:* `payments_extract_2025_11_29.csv`
- [ ] [ ] **Validate Source Files**
  - Ensure headers are present in the first row.
  - Ensure delimiter is consistent (comma `,` or pipe `|`).

### **✔ 2.4 Security & Access (SAS Token)**

- [ ] [ ] **Generate Shared Access Signature (SAS)**
  - *Scope:* **Container Level** (strictly for `raw-landing`), not Account Key.
  - *Permissions:* `Read` and `List` only.
  - *Start/Expiry:* Set expiry for 6-12 months from today.
  - *Allowed Protocols:* HTTPS only.
- [ ] [ ] **Secure Credentials**
  - *Action:* Copy the **Blob SAS URL** and **SAS Token**.
  - *Action:* Paste them into a local `.env` file or password manager.
  - *Warning:* **NEVER** commit these keys to Git or paste them into clear text in Notion.

### **✔ 2.5 Data Seeding**

- [ ] [ ] **Perform Initial Upload**
  - Upload your sample/historical `.csv` or `.json` files into the correct folder paths created in step 2.2.
  - Verify files appear correctly in the Azure Portal "Storage Browser."

---

### ✔ **2.5 Connect Azure Blob → Snowflake**

This is done in Snowflake SQL (next step), but prepare inputs here:

- [ ] Container URL
- [ ] Storage Account Name
- [ ] SAS Token
- [ ] File path

### 4) Create a Warehouse and Database and Schema in Snowflake(done)

Goal: configure a secure, cost-efficient, and scalable architecture. This setup separates "Compute" (Warehouses) from "Storage" (Databases) and prepares the environment for automation.

### **✔ 3.1 Role-Based Access Control (RBAC) Foundation**

- [ ] [ ] **Create Functional Roles (Human Roles)**
  - `ANALYTICS_ROLE`: For you (and future developers). Has full read/write access to Dev and Prod models.
  - `REPORTER_ROLE`: For Power BI/Dashboard viewers. Read-only access to the final Marts only.
- [ ] [ ] **Create Service Roles (Machine Roles)**
  - `LOADER_ROLE`: Specifically for ingestion tools (e.g., Azure integration or Fivetran).
  - `CI_SERVICE_ROLE`: Specifically for GitHub Actions to run `dbt` in the CI pipeline.
- [ ] [ ] **Establish Role Hierarchy**
  - Grant `ANALYTICS_ROLE` to `SYSADMIN` (Keeps objects visible to admin).
  - Grant `LOADER_ROLE` and `CI_SERVICE_ROLE` to `SYSADMIN`.
- [ ] [ ] **Create Users & Assign Roles**
  - Create your user and assign `ANALYTICS_ROLE`.
  - Create a Service User (`SVC_GITHUB_ACTIONS`) and assign `CI_SERVICE_ROLE`.

### **✔ 3.2 Compute Configuration (Virtual Warehouses)**

- [ ] [ ] **Create Loading Warehouse**
  - *Name:* `LOADING_WH`
  - *Size:* `X-SMALL`
  - *Max Clusters:* `1` (Standard scaling).
  - *Auto-Suspend:* `60 seconds` (Aggressive cost saving).
  - *Comment:* "Dedicated to raw data ingestion."
- [ ] [ ] **Create Transformation Warehouse**
  - *Name:* `TRANSFORM_WH`
  - *Size:* `X-SMALL`
  - *Auto-Suspend:* `60 seconds`.
  - *Auto-Resume:* `True`.
  - *Comment:* "Dedicated to dbt transformations."
- [ ] [ ] **Create Reporting Warehouse**
  - *Name:* `REPORTING_WH`
  - *Size:* `X-SMALL`.
  - *Auto-Suspend:* `300 seconds` (5 mins to keep cache warm).
  - *Comment:* "Dedicated to Power BI DirectQuery/Import."

### **✔ 3.3 Database Architecture (The "Three-Legged Stool")**

- [ ] [ ] **Create Raw Database (`RAW_DB`)**
  - *Purpose:* Immutable landing zone.
  - *Time Travel:* Set `DATA_RETENTION_TIME_IN_DAYS = 0` (Save storage costs; data is backed up in Azure).
  - *Permissions:* Grant `OWNERSHIP` to `LOADER_ROLE`; Grant `USAGE/READ` to `ANALYTICS_ROLE`.
- [ ] [ ] **Create Production Analytics Database (`ANALYTICS_PROD`)**
  - *Purpose:* The "Golden Copy" for BI.
  - *Time Travel:* Set `DATA_RETENTION_TIME_IN_DAYS = 1` (Standard data protection).
  - *Permissions:* Grant `OWNERSHIP` to `CI_SERVICE_ROLE` (or dbt); Grant `READ` to `REPORTER_ROLE`.
- [ ] [ ] **Create Development Database (`ANALYTICS_DEV`)**
  - *Purpose:* Sandbox for development.
  - *Method:* **Zero-Copy Clone** `ANALYTICS_PROD` to create this initially.
  - *Permissions:* Grant `OWNERSHIP` to `ANALYTICS_ROLE`.
- [ ] [ ] **Create Common Database (`COMMON_DB`)**
  - *Purpose:* Utility tables (Date Dimension, Country Codes).

### **✔ 3.4 Schema Definition Strategy**

- [ ] [ ] **Define Raw Schemas (in `RAW_DB`)**
  - `LANDING`: For External Stages and File Formats.
  - `[SOURCE_SYSTEM]`: e.g., `STRIPE`, `SAP` (For the raw tables).
- [ ] [ ] **Define Analytics Schemas (in `ANALYTICS_PROD`)**
  - *Note:* dbt will manage these, but define the convention now.
  - `STAGING`: Views cleaning raw data.
  - `INTERMEDIATE`: Logic and joins.
  - `MARTS`: Final Star Schema tables.

### **✔ 3.5 Advanced Features Configuration**

- [ ] [ ] **Configure Time Travel & Fail-safe**
  - Verify `ANALYTICS_PROD` has **1 Day** retention.
  - Verify `RAW_DB` has **0 Day** retention.
- [ ] [ ] **Initialize Development Environment (Cloning)**
  - Execute `CREATE DATABASE ANALYTICS_DEV CLONE ANALYTICS_PROD;`
  - *Goal:* This ensures your Dev environment starts with the exact same structure as Prod without paying for double storage.

### **✔ 3.6 Resource Monitors (Cost Guardrails)**

- [ ] [ ] **Create Global Resource Monitor**
  - *Name:* `PORTFOLIO_BUDGET_MONITOR`
  - *Credit Quota:* `20` (Approx $40-$60 depending on region/edition).
  - *Cycle:* Monthly.
- [ ] [ ] **Set Triggers**
  - Notify at `75%`.
  - Notify at `90%`.
  - **Suspend Immediately** at `100%` (Hard stop to prevent accidental bills).
- [ ] [ ] **Apply Monitor**
  - Assign to `LOADING_WH`, `TRANSFORM_WH`, and `REPORTING_WH`.

Benefits of Zero Copy Clone

- **Cost-effective:** No additional storage costs until data in the clone is modified
- **Fast:** Instantaneous creation regardless of database size
- **Safe testing:** Test transformations and queries without affecting production data
- **Easy rollback:** Can drop and recreate clones as needed for fresh testing environments

<aside>
💡 **Best Practice:** Use the DEV clone for testing dbt models and transformations before deploying to production. Refresh the clone periodically to sync with production data changes.

</aside>

### Best Practices

- **Never use `ACCOUNTADMIN` for daily work:** Use it only for initial setup and billing. Switch to `SYSADMIN` or `ANALYTICS_ROLE` to prevent accidental deletion.
- **The "60-Second" Rule:** Set `AUTO_SUSPEND` to 60 seconds for Dev and Loading warehouses to avoid unnecessary charges.
- **Isolate Workloads:** Keep heavy data loads separate from `REPORTING_WH` to prevent dashboard performance issues.
- **Tag Everything:** Use `QUERY_TAG` in dbt and Session Tags in load scripts to track costs.
- **Zero-Copy for Safety:** `CLONE` to a temporary database before major Prod updates to avoid breaking changes.

### 5) Data Ingestion & Schema Definition(done)

### **✔ 4.1 Governance & Naming Standards**

- [ ] [ ] **Define Naming Conventions** (Update your `README.md` or Notion Wiki)
  - **Tables:** Plural, snake_case (e.g., `orders`, `customer_payments`).
  - **Columns:** Snake_case (e.g., `order_date` not `OrderDate`).
  - **Audit Columns:** Prefix with underscore (e.g., `_loaded_at`).
- [ ] [ ] **Define Primary Keys & Constraints**
  - *Action:* Identify the unique identifier for each source file (e.g., `order_id`).
  - *Note:* Snowflake constraints are "Not Enforced" but are critical for the Query Optimizer and dbt testing.

### **✔ 4.1 Configure Ingestion Objects (Stage & Formats)**

- [ ] [ ] **Create File Formats**
  - *Location:* `RAW_DB.LANDING` schema.
  - *CSV Format:* Create `CSV_GENERIC_FMT` with `TYPE = CSV`, `FIELD_OPTIONALLY_ENCLOSED_BY = '"'`, `SKIP_HEADER = 1`.
  - *JSON Format:* Create `JSON_GENERIC_FMT` with `TYPE = JSON`, `STRIP_OUTER_ARRAY = TRUE`.
- [ ] [ ] **Create External Stage** (The Bridge)
  - *Action:* Run `CREATE STAGE`.
  - _Parameters:_
    - `URL = 'azure://<account>.blob.core.windows.net/raw-landing'`
    - `STORAGE_INTEGRATION = [Your_Integration_Name]` (from Phase 2).
    - `FILE_FORMAT = CSV_GENERIC_FMT`.
  - *Validation:* Run `LIST @RAW_DB.LANDING.AZURE_STAGE;` to ensure you can see the files.
- [ ] [ ] **Create Tables Automatically**
  - *Action:* Use the `CREATE TABLE ... USING TEMPLATE` command.
  - *Why:* This creates the table structure in `RAW_DB` with the correct column names and data types (String, Number, etc.) derived directly from the file.
  - *Alternative:* If manual control is needed, write the `CREATE TABLE` DDL manually with strict types.

### **✔ 4.3 Execute Data Loading (Ingestion)**

- [ ] [ ] **Run `COPY INTO` Command**
  - *Source:* `@RAW_DB.LANDING.AZURE_STAGE/folder/`
  - *Target:* `RAW_DB.SOURCE_SYSTEM.TABLE_NAME`
  - *Pattern:* Use `PATTERN='.*orders.*.csv'` to load all matching files in one go.
- [ ] [ ] **Implement Error Handling**
  - *Parameter:* Set `ON_ERROR = 'CONTINUE'` (to load good rows and skip bad ones) OR `ON_ERROR = 'SKIP_FILE'`(to reject the whole file if one row is bad).
  - *Logging:* Enable `RETURN_FAILED_ONLY = TRUE` initially to see what broke.

### **✔ 4.4 Data Validation & Auditing**

- [ ] [ ] **Verify Row Counts**
  - Compare the `ROW_COUNT` in the Snowflake "Load History" view vs. the number of records in your source CSV.
- [ ] [ ] **Check Load History**
  - Query `INFORMATION_SCHEMA.LOAD_HISTORY` to see a log of exactly which files were loaded and when.
- [ ] [ ] **Spot Check Data**
  - Run `SELECT * FROM table LIMIT 100` to ensure columns aren't aligned incorrectly (e.g., Dates appearing in the Name column).

---

### 📝 Deliverables for this Phase

- **DDL Script:** A `.sql` file containing the `CREATE FILE FORMAT` and `COPY INTO` commands.
- **Load Report:** A screenshot of the query result from `LOAD_HISTORY` showing "Status: LOADED".

### 💡 Best Practices & Tips

- **Use `MATCH_BY_COLUMN_NAME`:** If your CSV columns might change order in the future, add `MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE` to your `COPY INTO` command. This maps data by name, not by position.
- **Don't transform yet:** Do not try to rename columns or change logic during the `COPY INTO` step. Load it **exactly** as it is. Fix the names later in dbt.
- **Snowflake Constraints:** You can run `ALTER TABLE orders ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);`.**Tip:** Even though Snowflake doesn't stop you from inserting duplicates, defining this tells Power BI and dbt exactly how to join tables later.
- **indempotency:** Your loading process should be repeatable. If you run the load script twice, it shouldn't duplicate data.*Snowflake Native:* `COPY INTO` automatically tracks files it has already loaded and won't load them again unless you modify the file or use `FORCE = TRUE`.

### 🚀 Pro Tips & Tricks (Performance & Workflow)

- **The "Dry Run" (Validation Mode):**
  - Before you actually load data, run the `COPY INTO` command with `VALIDATION_MODE = 'RETURN_ERRORS'`.
  - *Result:* Snowflake simulates the load and tells you exactly which rows *would* fail, without actually inserting any data. This is a lifesaver for debugging.
  - **The "Audit" Columns:**
  - `_source_file`: Essential for debugging. If a specific file was corrupted, you can quickly find and delete only those rows using `DELETE FROM table WHERE _source_file = 'bad_file.csv'`.
  - `_loaded_at`: Helps you track data freshness.

### 6) Data Dictionary(done)

Create comprehensive documentation of every field, including business definitions and calculation logic. Essential for collaboration and future maintenance.

[Example](https://www.notion.so/Example-2cd1bb84f4a481f0ae3adac89024e837?pvs=21)

### 7) Record Metadata and Data Quality Issues(done)

Track load timestamps, source file versions, and any anomalies discovered. This audit trail is critical for troubleshooting and stakeholder communication.

[Example](https://www.notion.so/Example-2cd1bb84f4a48107a7eecd218e694cd8?pvs=21)

### 8) Optimization and Best Practices(done)

- **Use Clustering Keys:** Apply on frequently filtered columns (date, region) to boost query speed and cut costs
- **Leverage Zero-Copy Cloning:** Create instant, free database copies for dev/test without duplicating storage
- **Optimize Warehouse Sizing:** Start small (X-SMALL/SMALL), scale as needed; enable auto-suspend/resume
- **Implement Incremental Loading:** Use COPY INTO with pattern matching to load only new/changed files
- **Enable Query Result Caching:** Leverage automatic 24-hour cache for identical queries
- **Set Resource Monitors:** Create credit quotas to prevent cost overruns with threshold alerts
- **Monitor Query Performance:** Review Query History regularly to identify and optimize slow queries
- **Use Multi-Table Insert:** Load into multiple tables in one operation for better efficiency

### 9) Version Control in Git and Github

```jsx
my-data-project/
├── docs/                     # For Phase 2 Documentation
│   ├── DATA_DICTIONARY_RAW.md
│   └── NAMING_CONVENTIONS.md
├── snowflake/                # For Phase 2 SQL Scripts
│   ├── 01_admin/             # Admin setup scripts
│   │   ├── 01_roles_and_rbac.sql
│   │   └── 02_warehouses_and_monitors.sql
│   ├── 02_infrastructure/    # Storage setup
│   │   ├── 01_databases_and_schemas.sql
│   │   └── 02_stages_and_formats.sql
│   └── 03_raw_tables/        # Data loading
│       ├── stripe_tables.sql
│       └── sap_tables.sql
├── .gitignore                # Critical security file
└── README.md                 # Project summary
```

> Goal: Treat your database infrastructure as "Code." You will write SQL scripts locally in VS Code, version them to track changes, and use GitHub Pull Requests to merge them into your main project, simulating a real-world Data Engineering workflow.

Here is exactly how to document the GitHub Personal Access Token (PAT) configuration in your Notion ADLC framework.
This belongs in your "Build Phase" under a page or toggle named "🔐 Security & Access Control".
The Notion Copy-Paste Block
Copy the section below directly into your Notion. It looks professional and proves you understand Security Best Practices (DataOps).
🔐 GitHub Authentication (PAT Configuration)
Objective: Configure secure, programmatic access for local development and CI/CD pipelines without using raw passwords.

1. Token Creation Strategy

- [ ] Token Type: Used Classic Token (for broad compatibility with dbt Cloud/local CLI) or Fine-Grained Token (for specific repo access).
- [ ] Expiration Policy: Set to 90 Days (Enforcing key rotation security).
- [ ] Permissions/Scopes Selected:
  - repo (Full control of private repositories) - Required for pushing code.
  - workflow (Update GitHub Action workflows) - Required for CI/CD.
  - read:org - Required if accessing organization-level secrets.

1. Secret Storage (The "No-Leak" Policy)

> ⚠️ SECURITY WARNING: Never store the actual PAT string in this Notion doc or commit it to Git.

- [x] Local Environment:
  - Stored in .env file (ensure .env is added to .gitignore).
  - Format: GITHUB_TOKEN=ghp_xxxx...
- [x] CI/CD Environment (GitHub Actions):
  - Navigate to: Repo Settings \rightarrow Secrets and variables \rightarrow Actions.
  - Saved as Repository Secret: GH_PERSONAL_ACCESS_TOKEN.
  - Usage: Used in YAML workflows via ${{ secrets.GH_PERSONAL_ACCESS_TOKEN }}.
    How to explain this in an interview 🗣️
    If they ask about how you handle access:

> "I don't use my GitHub password for git operations. I configured a Personal Access Token (PAT) with an expiration date.
> For the pipeline, I stored this PAT as an Encrypted Secret in GitHub Actions. This ensures that even if someone clones my repo, they cannot see my credentials. I treat my portfolio security like a production environment."

Why document this?
It proves you aren't just hacking things together. You have a "Security First" mindset, which is a massive green flag for Financial (JPMC) and Enterprise clients.

### **✔ 9.1 Initial Repository Setup (One-Time Task)**

- [ ] [ ] **Initialize Local Repository**
  - *Action:* Open your project folder in VS Code terminal.
  - *Command:* `git init`
  - *Check:* Verify a hidden `.git` folder appears
- [ ] [ ] **Configure Security (`.gitignore`)**
  - *Action:* Create a file named `.gitignore` in the root.
  - *Content:* Add the following lines to prevent leaking secrets:Plaintext
    `.env
*.creds
*.pem
.DS_Store
venv/
__pycache__/`
- [ ] [ ] **Connect to Remote**
  - *Action:* Create a new empty repository on GitHub.
  - *Command:* `git remote add origin https://github.com/[your-username]/[repo-name].git`

### **✔ 9.2 The Development Workflow (The Daily Loop)**

- [ ] [ ] **Create a Feature Branch**
  - *Rule:* Never work directly on `main`.
  - *Action:* Create a branch for Phase 2 setup.
  - *Command:* `git checkout -b feat/ph2-snowflake-setup`
- [ ] [ ] **Develop & Test SQL**
  - *Action:* Write your warehouse creation script in `snowflake/01_admin/02_warehouses.sql`.
  - *Test:* Copy/Paste the SQL into Snowflake Worksheet and run it. **Only save the file if it runs successfully.**
- [ ] [ ] **Stage Changes**
  - *Action:* Prepare files for saving.
  - *Command:* `git add .` (Stages all changes) OR `git add snowflake/01_admin/` (Stages specific folder).
- [ ] [ ] **Commit Changes (Save Snapshot)**
  - *Action:* Save the changes with a descriptive message.
  - *Command:* `git commit -m "infra: configured roles and warehouses for phase 2"`
  - *Standard:* Use prefixes like `infra:`, `docs:`, or `feat:` in your message.

### **✔ 9.3 The Review & Merge Workflow (The "Senior" Step)**

- [ ] [ ] **Push to GitHub**
  - *Action:* Send your branch to the cloud.
  - *Command:* `git push origin feat/ph2-snowflake-setup`
- [ ] [ ] **Open Pull Request (PR)**
  - *Action:* Go to your GitHub repo URL. Click the green "Compare & pull request" button.
  - *Title:* "Setup Snowflake Infrastructure (Phase 2)".
  - *Description:* "Created roles, warehouses, and external stages for Azure ingestion."
- [ ] [ ] **Self-Review (The Security Check)**
  - *Action:* Click the "Files changed" tab in the PR.
  - *Check:* **CRITICAL:** Ensure no passwords, SAS tokens, or AWS keys are visible. If found, revoke the key and fix the code locally.
- [ ] [ ] **Merge to Main**
  - *Action:* Click "Merge pull request" -> "Confirm merge".
  - *Result:* Your code is now effectively "In Production."

### **✔ 9.4 Milestone Tagging**

- [ ] [ ] **Create Release Tag**
  - *Trigger:* When Phase 2 is 100% complete (Data is loaded in Snowflake).
  - *Action:* Switch back to main and pull the latest changes.Bash
    `git checkout main
git pull origin main`
  - *Tag:* Create a permanent marker.Bash
    `git tag -a v0.2-raw-ingestion -m "Completed Phase 2: Raw Data Ingestion Pipelines"
git push origin v0.2-raw-ingestion`

---

### **🌟 Git Best Practices for Phase 2**

- **Atomic Commits:** Don't wait until you finish the whole phase to commit. Commit after every logical step (e.g., "created roles," then "created warehouses," then "created stages").
- **No Secrets:** Use placeholders in your code like `azure_sas_token='<INSERT_SECRET_HERE>'`.
- **Cleanup:** After merging, delete the feature branch: `git branch -d feat/ph2-snowflake-setup`.

###

[Phase 2: Summary and Deliverables](https://www.notion.so/Phase-2-Summary-and-Deliverables-2cd1bb84f4a481289ef7e0d5656e2da2?pvs=21)

# **🔧 Phase 3: Data Modeling, Transformation & Quality**

### **Objectives**

1. Set up and configure dbt environment for local and team development.
2. Load raw data (CSV/API/S3) into Snowflake and/or use dbt seeds.
3. Design the logical & physical **data model (Star Schema)** — define fact and dimension tables with clear grains.
4. Build dbt models: **staging → intermediate → marts (facts & dims)**.
5. Implement **data quality tests**, **freshness checks**, and **documentation** in dbt.
6. Create **semantic layer and metrics definitions** in dbt.
7. Prepare clean, tested data for Power BI semantic modeling (Phase 6).

### \*) AI Workflow

### Custom Chat Modes

# 1️⃣ **Mode Name:** `AE_Environment_Architect`

### **Purpose:**

Handles **all environment, configuration, tooling, packages, version control** for dbt + Snowflake.

### **This Mode Will Do:**

- Build `profiles.yml` for dev/prod
- Build `dbt_project.yml` with layer configs
- Set up Python venv + install dbt-snowflake, sqlfluff
- Setup `.gitignore` for dbt
- Setup Git branching strategy
- Setup folder structure: staging / intermediate / marts / macros / tests
- Setup `packages.yml` with dbt_utils + dbt_expectations
- Validate environment (`dbt debug`)

# 2️⃣ **CUSTOM MODE: `AE_Source_Registrar`**

### ✅ **This Mode Covers EVERYTHING About:**

- sources.yml creation
- Mapping RAW_DB tables
- Adding identifiers for weird table names
- Freshness checks (warn + error)
- Source-level tests (unique, not_null)
- seeds folder creation
- seed configuration in dbt_project.yml
- documenting sources
- metadata + ownership (meta tags)
- linking sources → staging lineage

# 3️⃣ **Mode Name:** `AE_Staging_Modeler`

### **Purpose:**

Builds **clean, standardized staging models**.

### **This Mode Will Do:**

- Create `stg_*` models using Import CTE pattern
- Standardize naming & cast data types
- Add surrogate key generation
- Fix categorical values / apply text cleaning
- Add generic tests
- Add singular tests
- Document every staging model

# 4️⃣ **Mode Name:** `AE_Intermediate_Modeler`

### **Purpose:**

Handles **joining, aggregations, fan-out/fan-in, window functions, business logic**, and **grain transformations**.

### **This Mode Will Do:**

- Join staging models
- Enrich data
- Apply business logic
- Define & enforce grain
- Handle duplicates
- Apply window functions
- Pivot / unpivot
- Add tests
- Document transformation logic

# 4️⃣ **Mode Name:** `AE_Intermediate_Modeler`

### **Purpose:**

Handles **joining, aggregations, fan-out/fan-in, window functions, business logic**, and **grain transformations**.

### **This Mode Will Do:**

- Join staging models
- Enrich data
- Apply business logic
- Define & enforce grain
- Handle duplicates
- Apply window functions
- Pivot / unpivot
- Add tests
- Document transformation logic

# 5️⃣ **Mode Name:** `AE_Marts_Architect`

### **Purpose:**

Creates **Star Schema (Fact + Dimension models)** with incremental logic & conformed dimensions.

### **This Mode Will Do:**

- Build fact tables (`fct_`)
- Build dimensions (`dim_`)
- Define grain for fact tables
- Generate surrogate keys
- Add incremental configs
- Add relationship tests
- Add business metrics pre-calculation
- Document marts layer
- Prepare tables for Power BI

# 6️⃣ **Mode Name:** `AE_Semantic_Modeler`

### **Purpose:**

Generates **Semantic Layer (MetricFlow)** + **Business Metrics** and aligns with BI tools.

### **This Mode Will Do:**

🔧 What this mode delivers

- Set up MetricFlow/dbt Semantic Layer tooling
- Create **time spine** + semantic model YAMLs
- Define **entities, dimensions, and measures**
- Define **metrics: simple, ratio, derived, cumulative**
- Validate & query metrics using **dbt sl**
- Push changes with clean Git workflow

# 7️⃣ **CUSTOM MODE: `AE_Debug_Optimizer`**

### 🎯 **Purpose:**

Handles EVERYTHING related to:

- Debugging dbt errors
- Debugging Snowflake errors
- Query optimization
- Model performance tuning
- Warehouse tuning
- Best practices enforcement
- SQL debugging
- Testing failures
- Lineage issues
- Dependency issues
- CI/CD failures

This is your **“Fix Anything”** mode.

### 1) Environment Setup & Configuration(done)

**Task:**

Set up your local development environment and configure dbt to connect to Snowflake. Establish proper project structure and version control.

### 🛠️ Phase 5: Environment Setup & Configuration

> Goal: Establish a robust local development environment, secure the connection between dbt and Snowflake, and initialize version control with best practices.

### **✔ 5.1 Local Tooling & Prerequisites**

- [ ] [ ] **Install Python & Virtual Environment**
  - Install Python (ensure version compatibility with dbt, e.g., 3.10+).
  - Create a virtual environment: `python -m venv venv`.
  - Activate environment: `source venv/bin/activate` (Mac) or `venv\Scripts\activate` (Win).
- [ ] [ ] **Install Development Tools**
  - Install **VS Code**.
  - Install **"dbt Power User"** extension (Vital for autocomplete and lineage in VS Code).
  - Install **"GitGraph"** extension (To visualize branches).

### **✔ 5.2 dbt Core Installation & Initialization**

- [ ] [ ] **Install dbt Adapter**
  - Run `pip install dbt-snowflake`.
  - Run `pip install sqlfluff` (The linter we discussed in Phase 3).
- [ ] [ ] **Initialize Project**
  - Run `dbt init [project_name]`.
  - Select `snowflake` as the database.

### **✔ 5.3 Connection Configuration (`profiles.yml`)**

- [ ] [ ] **Locate Profiles File**
  - Navigate to `~/.dbt/profiles.yml`.
- [ ] [ ] **Configure Development Target (`dev`)**
  - *Type:* `snowflake`
  - *Account:* `[your_account_locator]`
  - *User:* `[your_username]`
  - *Role:* `ANALYTICS_ROLE`
  - *Warehouse:* `TRANSFORM_WH` (X-Small)
  - *Database:* `ANALYTICS_DEV`
  - *Schema:* `dbt_[yourname]`
  - *Threads:* `4`
- [ ] [ ] **Configure Production Target (`prod`)**
  - *Database:* `ANALYTICS_PROD`
  - *Schema:* `MARTS` (or leaving it blank to use schema configurations in dbt_project.yml)
- [ ] [ ] **Secure Credentials**
  - **Action:** Use environment variables for passwords (`{{ env_var('DBT_PASSWORD') }}`) instead of hardcoding text.

### **✔ 5.4 Git & Version Control Strategy**

- [ ] [ ] **Initialize Repository**
  - Run `git init` inside your project folder.
  - Create a `main` branch.
- [ ] [ ] **Configure `.gitignore` (CRITICAL SECURITY STEP)**
  - Add `venv/` (Do not commit python libraries).
  - Add `logs/` (dbt logs).
  - Add `target/` (Compiled SQL artifacts).
  - Add `.env` (If using environment variables).
  - Add `profiles.yml` (If a local copy exists).
- [ ] [ ] **Connect to Remote**
  - Create a new repository on GitHub.
  - Run `git remote add origin [url]`.
  - Perform initial commit and push.

### **✔ 5.5 dbt Project Configuration (`dbt_project.yml`)**

- [ ] ## Define Project Structure
  - Set `model-paths: ["models"]`.
  - Set `seed-paths: ["seeds"]`.
- [ ] [ ] **Configure Model Layers (Materializations)**
  - Set `models:` hierarchy:
    - `staging:` -> `+materialized: view`, `+schema: staging`
    - `intermediate:` -> `+materialized: ephemeral`
    - `marts:` -> `+materialized: table`, `+schema: marts`
- [ ] [ ] **Set Query Tags**
  - Add `+query_tag: "dbt_portfolio"` to track costs in Snowflake.

### **✔ 5.6 Dependency Management (`packages.yml`)**

- [ ] [ ] **Create Packages File**
  - Create `packages.yml` in the root directory.
- [ ] [ ] **Add Standard Libraries**
  - `dbt-labs/dbt_utils` (For surrogate keys, date spines).
  - `calogica/dbt_expectations` (For advanced testing).
- [ ] [ ] **Install Dependencies**
  - Run `dbt deps`.

### **✔ 5.7 Final Validation**

- [ ] [ ] **Test Connectivity**
  - Run `dbt debug`.
  - *Success Criterion:* All checks (profiles.yml, dbt_project.yml, git, connection) pass with "OK".
- [ ] [ ] **Test Execution**
  - Run `dbt run` (on the sample models) to verify write access to Snowflake.

---

### 🌟 Phase 5 Best Practices

- **Virtual Environments are Non-Negotiable:** Never install dbt in your global Python environment. It causes dependency conflicts later. Always use `venv`.
- **Threads Configuration:** In `profiles.yml`, setting `threads: 4` or `8` allows dbt to build multiple models in parallel. This speeds up your run time significantly without costing extra Snowflake credits (since the Warehouse is running anyway).
- **Schema Naming Convention:**
  - By default, dbt concatenates schemas (e.g., `ANALYTICS_DEV_STAGING`).
  - **Tip:** Add a macro `generate_schema_name.sql` later if you want custom control over this (e.g., just `STAGING` in Prod, but `dbt_jdoe_staging` in Dev).
- **Environment Variables:**
  - In your terminal/`.zshrc`/`.bash_profile`, export your password: `export DBT_PASSWORD='my_secret_password'`.
  - In `profiles.yml`: `password: "{{ env_var('DBT_PASSWORD') }}"`.
  - *Why:* This ensures that if you accidentally commit your profiles file, your password isn't leaked.

### 📦 Phase 5 Deliverables (Checklist)

1. **✅ `dbt debug` Screenshot:** Proof that your local machine is talking to Snowflake successfully.
2. **📄 `.gitignore` File:** Verified list of excluded files (security proof).
3. **🔗 GitHub Repo Link:** A link to the initialized repository with the initial commit.

### 🛠️ Reference: Sample `profiles.yml` Structure

YAML

```jsx
# ~/.dbt/profiles.yml

portfolio_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: ANALYTICS_ROLE
      warehouse: TRANSFORM_WH
      database: ANALYTICS_DEV
      schema: dbt_yourname
      threads: 4
      client_session_keep_alive: False
```

| **Component**       | **Configuration Item** | **Example Value**                                |
| ------------------- | ---------------------- | ------------------------------------------------ |
| dbt Profile         | Target Schema          | DEV_ANALYTICS / PROD_ANALYTICS                   |
| Snowflake Warehouse | Size                   | X-SMALL (dev), SMALL (prod)                      |
| Git Branching       | Strategy               | main (prod), develop (staging), feature/\* (dev) |
| dbt Materialization | Default                | Staging: view, Marts: table                      |

<aside>

**Best Practices:**

- Use environment variables for sensitive credentials (never commit to Git)
- Establish naming conventions early (e.g., stg*, int*, fct*, dim* prefixes)
- Set up pre-commit hooks to run dbt tests before pushing code
- Document your connection setup in project README for team onboarding
</aside>

### 2) Data Loading & Raw Layer (Source Registration)(done)

**Task:**

> Goal: Formally register Snowflake raw tables into dbt, configure automated freshness monitoring, and establish the initial "Staging" layer for data cleaning.

- **Goal:** Configure local tooling, dbt connection, and version control.
- [ ] [ ] **Install Tooling:** Python, Virtual Env (`venv`), VS Code, git.
- [ ] [ ] **Install dbt:** `pip install dbt-snowflake sqlfluff`.
- [ ] [ ] **Configure `profiles.yml`:** Set up connection to Snowflake `TRANSFORM_WH`.
- [ ] [ ] **Initialize Git:** `git init`, configure `.gitignore` (hide secrets!).
- [ ] [ ] **Configure `dbt_project.yml`:** Define folders and materialization defaults.
  - *Staging:* View
  - *Intermediate:* Ephemeral
  - *Marts:* Table
- [ ] [ ] **Install Packages:** Add `dbt_utils`, `dbt_expectations` to `packages.yml`.

### **✔ 6.1 Source Registration (`sources.yml`)**

- [ ] [ ] **Create Source Definition File**
  - *Location:* `models/staging/_sources.yml` (Note: Using an underscore ensures it sits at the top).
- [ ] [ ] **Define Source Properties**
  - *Database Mapping:* Map the dbt source `name` to the Snowflake `RAW_DB`.
  - *Schema Mapping:* Map the source `schema` to your specific Snowflake schemas (e.g., `STRIPE`, `GOOGLE_ANALYTICS`).
- [ ] [ ] **Register Raw Tables**
  - *Action:* List every raw table you loaded in Phase 4 (e.g., `orders`, `customers`).
  - *Identifier:* Use the `identifier` property if the Snowflake table name is case-sensitive or messy (though ideally, you fixed this in Phase 4).

### **✔ 6.2 DataOps: Freshness & Quality Controls**

- [ ] [ ] **Configure Freshness Pass/Fail Thresholds**
  - *Warn:* Set `warn_after` (e.g., `count: 12, period: hour`) to get alerts if data is slightly late.
  - *Error:* Set `error_after` (e.g., `count: 24, period: hour`) to break the pipeline if data is stale.
  - *Filter:* Set `loaded_at_field` to your audit column `_loaded_at` (created in Phase 4) for accurate checking.
- [ ] [ ] **Apply Source-Level Tests**
  - *Action:* Add `unique` and `not_null` tests strictly to the Primary Keys in `sources.yml`.
  - *Why:* This catches data issues *before* any transformation logic runs.

### **✔ 6.3 Static Data Management (Seeds)**

- [ ] [ ] **Prepare Reference Files**
  - *Action:* Create CSVs for static lookups (e.g., `country_codes.csv`, `subscription_statuses.csv`,`dim_security_rls`).
  - *Formatting:* Ensure headers are clean (snake_case).
- [ ] [ ] **Configure Seeds (`dbt_project.yml`)**
  - *Action:* Define column types explicitly if needed (e.g., ensure `zip_code` is `string`, not `integer` to preserve leading zeros).
- [ ] [ ] **Execute Seed Load**
  - *Command:* Run `dbt seed`.
  - *Verification:* Check `ANALYTICS_DEV` schema to ensure tables were created.

### **✔ 6.4 Documentation & Metadata**

- [ ] [ ] **Document Sources**
  - *Description:* Add a description to the `source` level (e.g., "Data ingested from Stripe API via Azure Blob").
  - *Table Descriptions:* Briefly explain what each table represents.
- [ ] [ ] **Document External Loader**
  - *Meta Tag:* Use the `meta:` tag to indicate the owner (e.g., `loader: "Fivetran"` or `loader: "Snowpipe"`).
  ### 🌟 Phase 6 Best Practices
  - **The "One Source" Rule:** Never reference a raw Snowflake table (e.g., `RAW_DB.STRIPE.ORDERS`) in more than **one**dbt model. Reference it once in your `stg_` model, and then everyone else queries the `stg_` model. This creates a "Single Point of Failure" which is actually good—if the source changes, you fix it in one place.
  - **Source Freshness is Critical:**
    - Running `dbt source freshness` should be the **first step** in your CI/CD pipeline. If the raw data is old, there is no point in running the expensive transformation models.
  - **Naming Convention (Double Underscore):**
    - Use `stg_[source_system]__[entity].sql` (e.g., `stg_sap__users.sql`).
    - *Why?* It groups files by source system alphabetically in your file explorer, keeping your project organized.
  - **Docs Blocks:**
    - For long descriptions, do not write them inside `sources.yml`. Use a `docs` block in a markdown file and reference it: `description: "{{ doc('stripe_orders_table') }}"`.
  ### 📦 Phase 6 Deliverables (Checklist)
  1. **📄 `sources.yml` File:** A fully defined YAML file with freshness blocks and descriptions.
  2. **✅ Freshness Report:** A screenshot of the terminal output after running `dbt source freshness` (showing Green "PASS" status).
  3. **🕸️ Lineage Graph:** A screenshot from `dbt docs serve` showing the green "Source" node connecting to your blue "Staging" node.
  ### 🛠️ Key dbt Commands for this Phase
  - `dbt source freshness`: Checks if data is up to date.
  - `dbt seed`: Loads your CSVs into Snowflake.
  - `dbt run --select tag:staging`: Runs only your staging models.
  - `dbt test --select source:*`: Runs tests defined specifically on your raw sources.

| **Command**                  | **Purpose**                              | **Example**                                      |
| ---------------------------- | ---------------------------------------- | ------------------------------------------------ |
| `dbt source freshness`       | Check if sources are up-to-date          | `dbt source freshness --select source:raw_sales` |
| `dbt run --select source:*`  | Run models that depend on sources        | `dbt run --select source:raw_sales`              |
| `dbt test --select source:*` | Test source data quality                 | `dbt test --select source:raw_sales`             |
| `dbt seed`                   | Load seed files into database            | `dbt seed --select country_codes`                |
| `dbt docs generate`          | Generate documentation including sources | `dbt docs generate`                              |

### Example Staging Model (stg_sales\_\_orders.sql):

```
status_code,status_name,status_description
1,Pending,Order placed but not processed
2,Processing,Order is being prepared
3,Shipped,Order has been shipped
4,Delivered,Order delivered to customer
5,Cancelled,Order was cancelled

```

<aside>

**Pro Tips:**

- Run `dbt source freshness` daily in production to monitor data pipeline health
- Use source tests to catch data quality issues before they reach downstream models
- Keep staging models simple - just light cleaning and renaming, no business logic
- Document sources thoroughly - this becomes your data catalog for the team
- Use `{{ source() }}` function instead of hard-coding table names for lineage tracking
- Set up alerts in dbt Cloud or orchestration tool when source freshness checks fail
</aside>

<aside>

**Common Issues & Solutions:**

- **Source not found:** Verify database/schema names in sources.yml match Snowflake exactly (case-sensitive)
- **Freshness checks failing:** Ensure loaded_at_field is correctly specified and exists in source table
- **Permission errors:** Confirm dbt role has SELECT access on RAW schema and all source tables
- **Large seed files:** If seeds >1MB, load via Snowflake COPY INTO instead and register as source
</aside>

### 4) Build Staging Layer(done)

### 🏗️ Phase 7: Building the Staging Layer

> Goal: Create a clean, standardized, 1-to-1 mirror of your raw data. This layer prepares data for joining but performs no joins itself.

### **✔ 7.1 Configuration & Architecture**

- [ ] [ ] **Configure Materialization (Global)**
  - *Action:* Open `dbt_project.yml`.
  - *Setting:* under `models: -> staging:`, set `+materialized: view`.
  - *Why:* Staging models should always be views to ensure fresh data and zero storage costs.
- [ ] [ ] **Enforce File Naming Convention**
  - *Pattern:* `stg_[source]__[entity].sql` (Double underscore separates source from table).
  - *Example:* `stg_stripe__payments.sql`, `stg_salesforce__accounts.sql`.

### **✔ 7.2 Model Construction (The SQL Structure)**

- [ ] [ ] **Implement Import CTEs**
  - *Action:* Start every model with a CTE named `source` that selects from `{{ source('src', 'tbl') }}`.
  - *Why:* Separates dependency definition from logic.
- [ ] [ ] **Standardize Column Names**
  - *Action:* Rename all columns to `snake_case`.
  - *Action:* Prefix ambiguous IDs (e.g., rename `id` to `customer_id`).
- [ ] [ ] **Cast Data Types**
  - *Action:* Explicitly cast every column (e.g., `::boolean`, `::timestamp`, `::numeric(10,2)`). Do not rely on implicit types.
- [ ] [ ] **Generate Surrogate Keys (Crucial Step)**
  - *Action:* Use `{{ dbt_utils.generate_surrogate_key(['col_a', 'col_b']) }}` to create a unique hash key if the source lacks a reliable Primary Key.

### **✔ 7.3 Data Cleaning & Standardization**

- [ ] [ ] **Handle Null Values**
  - *Action:* Use `COALESCE(col, 'Unknown')` for text or `COALESCE(col, 0)` for measures where appropriate.
- [ ] [ ] **Standardize Categorical Data**
  - *Action:* Use `CASE WHEN` to fix messy values (e.g., Map 'USA', 'U.S.', 'US' -> 'United States').
- [ ] [ ] **Format Text**
  - *Action:* Apply `TRIM()`, `LOWER()`, or `INITCAP()` to string columns to ensure consistency for downstream joins.
- [ ] [ ] **Convert Units**
  - *Action:* Standardize money to cents (integer) or major currency (decimal), and convert weights/distances to a common metric.

### **✔ 7.4 Quality Assurance (What NOT to do)**

- [ ] [ ] **Verify No Joins**
  - *Check:* Ensure there are `0` `JOIN` statements in this folder.
- [ ] [ ] **Verify No Aggregations**
  - *Check:* Ensure there are `0` `GROUP BY` clauses. Granularity must match the source row-for-row.
- [ ] [ ] **Verify No Filtering**
  - *Check:* Do not use `WHERE` clauses to remove business data (e.g., "Active Users"). Only use `WHERE` to remove technical garbage (e.g., `_fivetran_deleted = true` or completely empty test rows).

### **✔ 7.5 Testing Strategy (Generic & Singular)**

- [ ] [ ] **Apply Generic Tests (Schema.yml)**
  - *Unique:* Apply to Primary Key (or Surrogate Key).
  - *Not Null:* Apply to PK and critical Foreign Keys.
  - *Accepted Values:* Apply to status columns (e.g., `status` must be 'placed', 'shipped', 'returned').
- [ ] [ ] **Write Singular Tests (Custom Logic)**
  - *Location:* Create `.sql` files in `tests/`.
  - *Logic:* Write queries that return "Bad Data".
  - *Example:* `assert_order_date_before_ship_date.sql` -> `SELECT * FROM {{ ref('stg_orders') }} WHERE ship_date < order_date` (If this returns rows, the test fails).

### **✔ 7.6 Documentation**

- [ ] [ ] **Generate YAML Documentation**
  - *Action:* Create `models/staging/[source]/_schema.yml`.
  - *Content:* Add `description:` for the table and every single column.
- [ ] [ ] **Visualize Lineage**
  - *Action:* Run `dbt docs serve` to verify the Staging node sits correctly between Source and Marts.

---

### 🌟 Best Practices & Optimization

- **The "Import CTE" Pattern:**SQL
  - This is the gold standard for readability. It enables "Partition Pruning" in Snowflake if you filter by date in the first CTE.
  ```jsx
  with source as (
      select * from {{ source('stripe', 'charges') }}
  ),
  renamed as (
      select
          id as charge_id,
          amount / 100 as amount_dollars,
          created_at::timestamp as charge_at
      from source
  )
  select * from renamed
  ```
- **Optimization (View Definition):**
  - Since these are Views, Snowflake doesn't store data. However, complex regex or massive `CASE` statements here run *every time* you query downstream. Keep logic simple here. Heavy lifting belongs in Intermediate (Ephemeral/Table).
- **Macro Usage:**
  - Don't write `amount * 100` in 5 different models. Write a macro `cents_to_dollars(column_name)` and use it. This makes your code DRY (Don't Repeat Yourself).

### 🛠️ What You Missed / Corrections

1. **Surrogate Keys:** You missed this, but it is vital. If your source system resets IDs or if you combine two systems, you need a new, reliable ID. Use `dbt_utils`.
2. **Outliers:** You mentioned "Flag Outliers." **Correction:** Do not filter them out here. You can add a flag column (e.g., `is_amount_suspicious`), but keep the row. The raw data should be represented faithfully.
3. **Singular Tests:** These are powerful. Generic tests (`unique`) check *structure*. Singular tests check *business logic* (e.g., "Discount cannot be greater than Total Price").

### 📦 Phase 7 Deliverables

1. **✅ Codebase:** A `staging` folder with consistent SQL files using Import CTEs.
2. **✅ Test Suite:** A populated `schema.yml` and at least 2 Custom Singular Tests in the `tests/` folder.
3. **✅ Documentation:** Descriptions for all columns.

[[prompt.md](http://prompt.md) for Data Model](https://www.notion.so/prompt-md-for-Data-Model-2cd1bb84f4a481a39a90e42330c9b517?pvs=21)

### 3) Data Model Design (Star Schema)

**Task:**

Design and implement a star schema (dimensional model) with fact and dimension tables that align with your business questions and KPIs. This transforms your staging data into business-friendly analytics tables.

Example

**Actions Required:**

1. **Design Logical Data Model:** Create conceptual diagram showing entities, relationships, and business rules without technical implementation details
2. **Design Physical Data Model:** Build technical diagram with specific table names, column data types, indexes, constraints, and partitioning strategy
3. **Identify Star Schema Components:**
   - **Fact Tables:** Business processes/events with measurable metrics (e.g., fct_orders, fct_payments, fct_shipments, fct_returns)
   - **Dimension Tables:** Descriptive context for facts (e.g., dim_customers, dim_products, dim_dates, dim_geographies, dim_store_locations)
   - **Fact Table Grain:** Define the most atomic level of detail (e.g., one record per order line item, one record per daily product inventory snapshot)
   - **Grain Validation:** Document and test that every row in fact table represents exactly one instance of the defined grain
4. **Define Key Structure:** Specify primary keys (natural and surrogate), foreign keys linking facts to dimensions, and composite keys where needed
5. Remove Tables and Columns and That does not Answer the business Questions and Requirements
6. Ensure Perfect Naming convention of each columns
7. **Create Surrogate Key Strategy:** Use `dbt_utils.generate_surrogate_key()` for dimension tables to ensure stable, efficient joins
8. **Map Data Transformations:** Document column-level mappings from raw source tables to final model (renaming, type casting, business rules, calculations)
9. **Define Calculated Measures:** Identify metrics to pre-calculate in fact tables (e.g., profit = revenue - cost, discount_amount, margin_percentage)
10. **Implement Slowly Changing Dimensions:**
    - **SCD Type 1:** Overwrite dimension attributes (for corrections or non-historical attributes)
    - **SCD Type 2:** Track historical changes with effective_from/effective_to dates and is_current flag (for auditing and historical analysis)
    - **Choose SCD Strategy:** Decide per dimension based on business requirements and reporting needs
11. **Define Conformed Dimensions:** Identify dimensions shared across multiple fact tables (e.g., dim_dates used by fct_orders, fct_shipments, fct_returns)
12. **Create Date Dimension:** Build comprehensive date table with calendar attributes (year, quarter, month, week, day_of_week, fiscal_period, holidays, is_weekend)
13. **Document Business Rules:** Capture logic for calculated fields, filtering criteria, aggregation rules, and handling of null/missing values
14. **Design Incremental Load Strategy:** For large fact tables, define incremental materialization approach with appropriate unique_key and filters
15. **Plan Indexing Strategy:** Identify columns for clustering keys in Snowflake to optimize query performance (typically date columns and frequently filtered dimensions)
16. **Create Relationship Tests:** Define dbt relationship tests to validate referential integrity between facts and dimensions
17. **Tag Models by Domain:** Apply tags (e.g., sales, finance, operations) to organize models and enable selective runs

### Star Schema Design Pattern:

```
┌─────────────────┐
│  dim_customers  │
│  - customer_key │◄───┐
│  - customer_id  │    │
│  - name         │    │
│  - segment      │    │
└─────────────────┘    │
                       │
┌─────────────────┐    │    ┌─────────────────┐
│   dim_products  │    │    │    dim_dates    │
│  - product_key  │◄───┼───►│   - date_key    │
│  - product_id   │    │    │   - date        │
│  - category     │    │    │   - year        │
│  - subcategory  │    │    │   - quarter     │
└─────────────────┘    │    │   - month       │
                       │    └─────────────────┘
                       │           ▲
                  ┌────▼───────────┴────┐
                  │    fct_orders       │
                  │  - order_key        │
                  │  - customer_key (FK)│
                  │  - product_key (FK) │
                  │  - date_key (FK)    │
                  │  - quantity         │
                  │  - revenue          │
                  │  - cost             │
                  │  - profit           │
                  └─────────────────────┘

```

### Naming Conventions:

| **Model Type** | **Prefix** | **Example**           | **Materialization**  |
| -------------- | ---------- | --------------------- | -------------------- |
| Staging        | `stg_`     | `stg_sales__orders`   | view                 |
| Intermediate   | `int_`     | `int_orders_enriched` | view or ephemeral    |
| Fact           | `fct_`     | `fct_orders`          | table or incremental |
| Dimension      | `dim_`     | `dim_customers`       | table                |
| Metrics        | `met_`     | `met_monthly_revenue` | view                 |

### Key dbt Commands:

| **Command**                      | **Purpose**                                   | **Example**                          |
| -------------------------------- | --------------------------------------------- | ------------------------------------ |
| `dbt run --select +fct_orders`   | Run fact table and all upstream dependencies  | Builds entire lineage for fact table |
| `dbt run --select dim_*`         | Run all dimension models                      | Build all dimensions first           |
| `dbt test --select fct_orders`   | Test fact table relationships and constraints | Validate data quality                |
| `dbt run --select tag:dimension` | Run all models tagged as dimensions           | Build by model type                  |
| `dbt docs generate`              | Generate documentation with lineage graph     | Visualize star schema                |

<aside>

**Star Schema Design Best Practices:**

- **Define clear grain:** Each fact table should have one clearly defined level of detail (e.g., one row per order line item)
- **Use surrogate keys:** Generate surrogate keys for dimensions using `dbt_utils.generate_surrogate_key()` for better performance
- **Denormalize dimensions:** Include descriptive attributes in dimensions rather than normalizing (star schema, not snowflake)
- **Pre-calculate measures:** Include calculated measures in fact tables (e.g., profit = revenue - cost) for reporting efficiency
- **Build conformed dimensions:** Reuse dimensions across multiple fact tables when possible (e.g., shared date dimension)
- **Document relationships:** Use `relationships` tests to validate foreign keys and document lineage
- **Implement SCD for changing dimensions:** Use Type 2 SCD for tracking historical changes in important dimensions
</aside>

<aside>

**Common Star Schema Patterns:**

- **Transaction Facts:** One row per business event (fct_orders, fct_payments, fct_shipments)
- **Periodic Snapshot Facts:** Regular snapshots of measurements (fct_daily_inventory, fct_monthly_balances)
- **Accumulating Snapshot Facts:** Track lifecycle of processes (fct_order_fulfillment with multiple date keys for order, ship, delivery)
- **Factless Fact Tables:** Track events without measures (fct_student_attendance, fct_promotion_coverage)
- **Role-Playing Dimensions:** Same dimension used multiple times with different meanings (dim_dates as order_date, ship_date, delivery_date)
</aside>

<aside>

**Integration with Power BI:**

- Star schema in dbt translates perfectly to Power BI's semantic model structure
- Fact and dimension tables become tables in Power BI with automatic relationship detection
- Pre-calculated measures in facts become implicit measures; explicit DAX measures built on top
- Date dimension becomes basis for time intelligence functions in Power BI
- Surrogate keys enable efficient relationships and better query performance
- Model documentation from dbt helps Power BI developers understand table purposes and relationships
</aside>

### 5) Build Intermediate Layer(done)

> Goal: Transform cleaned staging data into business-logic-rich models. Join tables, calculate metrics, and handle grain shifts (aggregation/fan-out) without yet creating the final presentation layer.

### **✔ 8.1 Configuration & Materialization Strategy**

- [ ] [ ] **Define Materialization Default**
  - *Action:* In `dbt_project.yml`, set `models: -> intermediate:` to `+materialized: ephemeral`.
  - *Why:* `ephemeral` acts like a CTE (snippet) injected into downstream models. It keeps your Snowflake storage clean.
- [ ] [ ] **Identify Performance Bottlenecks (Override to Table)**
  - *Action:* If a specific model involves massive joins or is referenced by 5+ downstream models, change config *at the file level* to `{{ config(materialized='table') }}`.
  - *Why:* Compute it once and save it, rather than re-computing it every time a Mart runs.
- [ ] [ ] **Enforce Naming Conventions**
  - *Pattern:* `int_[primary_entity]__[action_or_concept].sql`
  - _Examples:_
    - `int_orders__joined_to_payments.sql` (Integration)
    - `int_customers__segmentation_rules.sql` (Logic application)
    - `int_web_events__sessionized.sql` (Window functions)

### **✔ 8.2 Structural Transformations (Joins & Shapes)**

- [ ] [ ] **Join Staging Models**
  - *Action:* Combine related staging tables (e.g., `stg_orders` + `stg_payments`) using standard SQL `JOINs`.
- [ ] [ ] **Handle Granularity (Fan-Out/Fan-In)**
  - *Check:* explicitly document the "Grain" of the model (e.g., "One row per Order" vs "One row per Order Item").
  - *Action:* Use `GROUP BY` to aggregate child rows (e.g., payment attempts) back to the parent grain (order) if necessary.
- [ ] [ ] **Reshape Data**
  - *Pivot:* Convert rows to columns (e.g., `payment_method` rows -> `amount_usd_credit_card`, `amount_usd_paypal` columns).
  - *Unpivot:* Convert wide columns back to rows if normalizing data.
- [ ] [ ] **Deduplicate Records**
  - *Action:* Use `QUALIFY ROW_NUMBER() OVER (...) = 1` to remove duplicates based on strict business rules.

### **✔ 8.3 Business Logic & Calculations**

- [ ] [ ] **Apply Conditional Logic**
  - *Action:* Use `CASE WHEN` statements to create buckets (e.g., `Customer Segment`, `Order Priority`).
- [ ] [ ] **Create Calculated Fields**
  - *Action:* Compute business metrics (e.g., `margin = revenue - cost`, `days_to_ship = shipped_at - ordered_at`).
- [ ] [ ] **Apply Window Functions**
  - *Action:* Calculate "Running Totals," "Rankings," or "Previous Value" (`LAG`/`LEAD`) to analyze trends across rows.
- [ ] [ ] **Filter Business Rows**
  - *Action:* Apply `WHERE` clauses to remove records that are technically valid but business-irrelevant (e.g., filtering out internal test accounts).

### **✔ 8.4 Testing Strategy (Generic & Singular)**

- [ ] [ ] **Apply Structural Tests (`schema.yml`)**
  - *Unique:* Verify the Primary Key (composite or single) is unique.
  - *Not Null:* Ensure keys and critical metrics are populated.
  - *Relationships:* Validate Foreign Keys (e.g., ensure `customer_id` exists in `stg_customers`).
- [ ] [ ] **Apply Business Rule Tests (dbt_utils)**
  - *Accepted Values:* Check categorical fields (e.g., `status` IN ('active', 'churned')).
  - *Expression is True:* Validate logic (e.g., `total_revenue >= 0`, `end_date >= start_date`).
  - *Not Null Proportion:* Ensure critical columns aren't mostly empty.
- [ ] [ ] **Write Singular Tests (Custom SQL)**
  - *Action:* Create `.sql` files in `tests/` for complex logic that generic tests can't catch.
  - *Example:* "A customer cannot be 'Active' if their last login was > 1 year ago."

### **✔ 8.5 Documentation & Lineage**

- [ ] [ ] **Document Logic (`schema.yml`)**
  - *Action:* Add `description:` to the model explaining *what* logic was applied (e.g., "Joins orders to payments and pivots payment methods").
- [ ] [ ] **Verify Lineage Graph**
  - *Action:* Run `dbt docs serve` and check the graph.
  - *Check:* Ensure Staging models flow into Intermediate, and Intermediate flows into Marts (no skipping layers!).

---

### ❓ Should I include Singular Tests in the Intermediate Layer?

**YES. Absolutely.**

The Intermediate Layer is exactly where **Business Logic** is applied. Therefore, it is the *best* place to test that logic.

- **Generic Tests** (Unique, Not Null) check *Data Integrity*.
- **Singular Tests** (Custom SQL) check *Business Logic*.

**Example:** If you write logic in an intermediate model to calculate `days_to_ship`, you should write a **Singular Test** to ensure `ship_date` is never earlier than `order_date`.

- *File:* `tests/assert_ship_date_after_order_date.sql`
- *Query:* `SELECT * FROM {{ ref('int_orders') }} WHERE ship_date < order_date`
- If this returns rows, your intermediate logic is flawed.

---

### 🌟 Best Practices & Pitfalls

**Best Practices:**

- **Use Ephemeral Materialization:** Default to `ephemeral` to keep your Snowflake "Views" list clean. Think of Intermediate models as reusable code blocks, not necessarily physical tables.
- **Define the Grain:** Before writing `SELECT`, write a comment at the top: `- Grain: One row per Customer`. Stick to it.
- **Modularize Complex Joins:** If you need to join 5 tables, don't do it in one massive query. Join A to B (`int_a_b`), Join C to D (`int_c_d`), then join the results.

**What NOT to do:**

- **❌ No Final Presentation:** Don't rename columns to "pretty" names (e.g., "Customer Name"). Keep them snake_case (`customer_name`). "Pretty" names belong in Power BI.
- **❌ No Star Schema Keys:** Don't generate the final `dim_customer_key` here. Do that in the Marts.
- **❌ Don't Drop Columns Prematurely:** Unless a column is massive PII, keep it. You don't know if the Mart layer will need it later.

### 6) Build Marts Layer(done)

> Goal: Transform complex business logic into a governed, performance-optimized Star Schema ready for Power BI. This layer is the "Product" you deliver to stakeholders.

### **✔ 9.1 Pre-Work & Planning**

- [ ] [ ] **Create Engineering Ticket**
  - *Action:* Create a GitHub Issue/Jira Ticket outlining the business requirements and KPIs.
  - *Deliverable:* A 1-page design doc linked in the ticket.
- [ ] [ ] **Define Branching Strategy**
  - *Action:* Create a new branch: `feature/marts-[domain]-[description]` (e.g., `feature/marts-finance-revenue`).
- [ ] [ ] **Folder Architecture**
  - *Standard:* Organize strictly by domain:
    - `models/marts/core/` (Shared dimensions like Date, Customers).
    - `models/marts/finance/` (Revenue, Costs).
    - `models/marts/marketing/` (Campaigns, Leads).

### **✔ 9.2 The "Backbone" Structural Tables**

- [ ] [ ] **Build Date Dimension (`dim_date`)**
  - *Location:* `models/marts/core/dim_date.sql`
  - *Source:* Use `dbt_utils.date_spine` macro.
  - *Logic:* Generate dates from `2015-01-01` to `2035-01-01`.
  - *Attributes:* `date_key` (YYYYMMDD), `year`, `quarter`, `month_name`, `is_weekend`, `fiscal_year`.
  - *Materialization:* `table`.
- [ ] [ ] **Build Bridge Tables (If needed)**
  - *Location:* `models/marts/core/bridge_[entity_a]_[entity_b].sql`
  - *Logic:* Handle Many-to-Many relationships (e.g., Orders <-> Tags).
  - *Columns:* `entity_a_key`, `entity_b_key`, `allocation_weight` (if applicable).
  - *Tests:* Unique constraint on the *composite* key (A + B).

### **✔ 9.3 Building Dimensions (`dim_`)**

- [ ] [ ] **Standardize Dimension Structure**
  - *Primary Key:* `[entity]_key` (Surrogate Key, MD5 hash).
  - *Natural Key:* `[entity]_id` (Source System ID).
  - *Attributes:* Descriptive columns (Name, Status, Category).
- [ ] [ ] **Handle Nulls & Unknowns**
  - *Action:* Use `COALESCE(col, 'N/A')` or `'-1'` for keys. Power BI needs clean relationships.
- [ ] [ ] **Configure Materialization**SQL
  - _Config:_
    `{{ config(
    materialized = 'table',
    schema       = 'marts',
    alias        = 'dim_customers',
    tags         = ['marts', 'core']
) }}`

### **✔ 9.4 Building Fact Tables (`fct_`)**

- [ ] [ ] **Define Grain**
  - *Rule:* One row per [Event] (e.g., Line Item, Click, Transaction).
- [ ] [ ] **Select Measures**
  - *Action:* Bring in numeric columns (`revenue`, `quantity`, `duration_seconds`).
  - *Monetary:* Convert all amounts to cents/base units OR standard decimals. Be consistent.
- [ ] [ ] **Bring in Foreign Keys**
  - *Action:* Ensure every `_key` column matches a `dim_` table.
- [ ] [ ] **Add Degenerate Dimensions**
  - *Action:* Keep `order_id` or `invoice_number` for auditing.

### **✔ 9.5 Optimization: Incremental Materialization**

- [ ] [ ] **Configure Incremental Strategy**SQL
  - *Target:* Apply only to large Fact tables (e.g., `fct_orders`).
  - _Config:_
    `{{ config(
    materialized='incremental',
    unique_key='order_id',
    on_schema_change='fail'
) }}`
- [ ] [ ] **Implement Filter Logic**SQL
  - *Action:* Add `is_incremental()` macro at the end of the query.
    `{% if is_incremental() %}
  where updated_at > (select max(updated_at) from {{ this }})
{% endif %}`
- [ ] [ ] **SCD Type 2 (History)**
  - *Optional:* If tracking history, ensure `valid_from` and `valid_to` columns are preserved.

### **✔ 9.6 Documentation & Metadata**

- [ ] [ ] **Write Descriptions**
  - *Rule:* Every model must have a description (2-4 sentences).
  - *Rule:* Every column in `schema.yml` must have a description.
- [ ] [ ] **Use Doc Blocks**
  - *Action:* Use `{{ doc("business_term") }}` for shared definitions (e.g., "Revenue").
- [ ] [ ] **Power BI Specifics**
  - *Action:* Add `synonyms` in YAML to help Power BI Q&A find columns.

### **✔ 9.7 Testing Strategy (The Safety Net)**

- [ ] [ ] **Configure Singular Tests (Business Logic)**
  - *Dates:* `assert_ship_after_order.sql` (`ship_date >= order_date`).
  - *Monetary:* `assert_positive_revenue.sql` (`revenue >= 0`).
  - *Relationships:* `assert_bridge_integrity.sql` (Bridge keys exist in Dims).
- [ ] [ ] **Configure Generic Tests (`schema.yml`)**
  - *Keys:* `unique`, `not_null`.
  - *Foreign Keys:* `relationships`.
  - *Cardinality:* `dbt_expectations.expect_table_row_count_to_be_between`.
  - *Marts Rules:* `dbt_project_evaluator.no_direct_model_references_from_marts`.
  ### **✔ 9.8 Data Governance (Contracts)**
  - [ ] [ ] **Select Critical Models**
    - *Target:* Identify high-value Mart models (e.g., `dim_customers`, `fct_orders`) that serve Power BI.
    - *Reason:* Enforcing contracts here prevents breaking changes from reaching dashboards.
  - [ ] [ ] **Define Contract Configuration**
    - *Action:* In `models/marts/[domain]/schema.yml`, add the `contract` config block to the model definition.
    - *Code:*YAML
      ```jsx
      config: contract: enforced: true
      ```
  - [ ] [ ] **Define Explicit Column Types**
    - *Action:* For every column in the contracted model, specify the exact data type.
    - *Code:*YAML
      ```jsx
      columns:
        - name: customer_id
          data_type: INT
        - name: email
          data_type: STRING
      ```
  - [ ] [ ] **Define Constraints**
    - *Action:* Add constraints to critical columns to enforce data integrity at the database level (if supported by Snowflake/dbt adapter).
    - *Code:*YAML
      ```jsx
          constraints:
            - type: not_null
            - type: primary_key
      ```
  - [ ] [ ] **Validate Contract Enforcement**
    - *Action:* Run `dbt build --select [model_name]` to verify that the model builds successfully with the contract enabled.
    - *Test:* Try changing a column type in the SQL model (e.g., cast an INT to STRING) and verify that `dbt run` fails, proving the contract is working.
  ***

### **✔ 9.8 Power BI Preparation Tasks**

- [ ] [ ] **Grant Access**
  - *Action:* `GRANT SELECT ON SCHEMA MARTS TO ROLE REPORTER_ROLE;` (Automate via Post-Hook or dbt grants).
- [ ] [ ] **Hide Technical Columns**
  - *Action:* Prefix Surrogate Keys or System columns with `_` or list them in a "Hidden" meta-field for the BI developer.

### **✔ 9.9 Final Review & Deployment**

- [ ] [ ] **Local Validation**
  - *Command:* `dbt build --select tag:marts` (Runs models + tests).
  - *Check:* All tests pass?
- [ ] [ ] **Documentation Check**
  - *Command:* `dbt docs generate`.
  - *Check:* Does the Lineage Graph look like a clean flow (Staging -> Int -> Marts)?
- [ ] [ ] **Pull Request**
  - *Action:* Open PR. Paste test results and lineage screenshot.
  - *Merge:* Merge to `develop` (CI Run) -> Merge to `main` (Prod Run).

---

### 🌟 Phase 9 Best Practices

- **No `SELECT *`:** strictly forbidden in Marts. Explicitly name every column. If a source column changes, your Mart should fail loudly, not silently succeed with broken data.
- **Separation of Duties:**
  - **Staging:** Cleaning & Standardizing.
  - **Intermediate:** Joins & Logic.
  - **Marts:** Selection & Renaming for End Users.
  - *Rule:* Never join `stg_` tables directly in a `mart_`. Always go through `int_` if there is ANY logic involved.
- **Query Acceleration:**
  - For massive tables in Snowflake, consider enabling **Auto-Clustering** or **Search Optimization Service** if performance lags (Advanced).
- **Cost Control:**
  - Use `incremental` strategies aggressively.
  - Use `transient` tables for Intermediate models if they don't need Fail-safe retention.

### 📦 Phase 9 Deliverables

1. **✅ Star Schema Code:** Clean SQL files for Facts, Dims, and Bridge tables.
2. **✅ Date Dimension:** A populated `dim_date` table.
3. **✅ Test Suite:** A robust `schema.yml` with generic and singular tests.
4. **✅ Incremental Logic:** Proven `is_incremental()` blocks in Fact tables.
5. **✅ Documentation Site:** A hosted static site showing the full data dictionary.

### 7) Semantic Layer & Metrics(done)

> Goal: Codify business logic into a centralized semantic layer so that "Revenue" means the exact same thing in dbt, the CLI, and Power BI.

### **✔ 13.1 Environment & Project Configuration**

- [ ] [ ] **Enable Semantic Layer**
  - *Action:* Ensure you have a dbt Cloud account (Team/Enterprise) OR are setting up MetricFlow locally for development.
- [ ] [ ] **Install MetricFlow Package**
  - *Action:* Verify `dbt-metricflow` is installed/compatible with your dbt Core version.
- [ ] [ ] **Create Directory Structure**
  - *Action:* Create `models/semantic_models/` (for mapping tables).
  - *Action:* Create `models/metrics/` (for business calculations).

### **✔ 13.2 Define Semantic Models (The Mapping Layer)**

- [ ] [ ] **Create Semantic Model YAMLs**
  - *Location:* `models/semantic_models/[entity].yml`.
  - *Action:* define the `model:` block referencing a specific Mart table (`ref('fct_orders')`).
- [ ] [ ] **Define Entities (Keys)**
  - *Action:* Map Primary and Foreign keys (e.g., `entity: order_id`, `type: primary`).
  - *Action:* Define relationships to other semantic models (e.g., `orders` links to `customers`).
- [ ] [ ] **Define Dimensions (Attributes)**
  - *Action:* Map time dimensions (e.g., `order_date`) and set time granularity.
  - *Action:* Map categorical dimensions (e.g., `status`, `region`) for slicing.
- [ ] [ ] **Define Measures (Raw Aggregations)**
  - *Concept:* These are the building blocks, NOT the final metrics.
  - *Action:* Define `measures:` block (e.g., `name: orders_total`, `agg: sum`, `expr: amount`).

### **✔ 13.3 Define Business Metrics (The Logic Layer)**

- [ ] [ ] **Create Metrics YAML**
  - *Location:* `models/metrics/[business_area].yml` (e.g., `sales_metrics.yml`).
- [ ] [ ] **Define Simple Metrics**
  - *Type:* `simple`
  - *Action:* Reference the measures defined in 13.2 (e.g., `label: Total Revenue`, `type: simple`, `measure: orders_total`).
- [ ] [ ] **Define Ratio Metrics**
  - *Type:* `ratio`
  - *Action:* Define numerator and denominator metrics (e.g., `Average Order Value` = `Revenue` / `Order Count`).
- [ ] [ ] **Define Derived Metrics**
  - *Type:* `derived`
  - *Action:* Use expressions to combine metrics (e.g., `Profit` = `Revenue - Cost`).
- [ ] [ ] **Define Cumulative Metrics**
  - *Type:* `cumulative`
  - *Action:* Set window settings (e.g., `Rolling 7 Day Revenue`).

### **✔ 13.4 Testing & Validation (CLI)**

- [ ] [ ] **Validate Configuration**
  - *Command:* Run `dbt parse` to ensure YAML syntax is correct.
- [ ] [ ] **Query Metrics via CLI**
  - *Command:* Run `dbt sl query --metrics total_revenue --group-by metric_time`.
  - *Check:* Does the number returned match your SQL query in Snowflake?
- [ ] [ ] **Test Dimension Slicing**
  - *Command:* Run `dbt sl query --metrics total_revenue --group-by status`.
  - *Check:* Do the categories match the raw data?

### **✔ 13.5 Documentation & Governance**

- [ ] [ ] **Add Business Descriptions**
  - *Action:* In the YAML, add `description:` fields for every metric. This is what the CEO reads.
  - *Action:* Add `label:` fields for pretty printing (e.g., `label: "Gross Margin %"`).
- [ ] [ ] **Tag Metrics**
  - *Action:* Use tags (e.g., `tags: ['financial', 'kpi']`) to organize metrics by department.

### **✔ 13.6 Power BI Integration Strategy**

- [ ] [ ] **Establish "Single Source" Policy**
  - *Action:* Decide which metrics live in dbt vs. Power BI.
  - *Best Practice:* "Base" metrics (Sum, Count) live in dbt. "Visual" metrics (Time Intelligence, Dynamic Formatting) often live in Power BI DAX but reference the dbt base.
- [ ] [ ] **Align DAX Measures**
  - *Action:* Create DAX measures in Power BI that strictly reference the columns generated by the Semantic Layer logic.
  - *Action:* Copy the description from dbt into the Power BI measure description property.

---

### 🌟 Phase 13 Best Practices

- **Measures vs. Metrics:**
  - **Measure:** `SUM(amount)` inside a specific table. (Technical).
  - **Metric:** "Revenue". A globally accessible concept that might join Orders and Refunds. (Business).
  - *Rule:* Never expose "Measures" to business users. Only expose "Metrics".
- **Don't Over-Engineer:**
  - If a calculation is extremely specific to one visual (e.g., "Top 3 Products by Region colored by Profit"), do that in Power BI DAX.
  - If a calculation is a company-wide KPI (e.g., "Churn Rate"), do it in dbt Semantic Layer.
- **MetricFlow Joins:**
  - MetricFlow handles joins automatically if you define your **Entities** correctly. Ensure your Primary and Foreign keys are strictly defined in `semantic_models` so dbt knows how to join `Orders` to `Customers` automatically.

### 📦 Phase 13 Deliverables

1. **📄 Semantic YAMLs:** Populated `models/semantic_models/` folder mapping your Marts.
2. **📄 Metrics YAMLs:** Populated `models/metrics/` folder with Ratio and Derived metrics.
3. **✅ CLI Validation:** A screenshot of a successful `dbt sl query` outputting a data table.
4. **🔗 Power BI Matrix:** A simple table in Notion mapping "dbt Metric Name" to "Power BI Measure Name" to prove alignment.

**Common Metrics by Business Area:**

| **Business Area** | **Metric Examples**                                            | **Metric Type**   |
| ----------------- | -------------------------------------------------------------- | ----------------- |
| Sales             | total_revenue, order_count, average_order_value                | Simple, Ratio     |
| Finance           | gross_profit, profit_margin, revenue_growth_rate               | Derived, Ratio    |
| Marketing         | customer_acquisition_cost, conversion_rate, return_on_ad_spend | Ratio, Derived    |
| Customer          | customer_lifetime_value, churn_rate, active_customers          | Cumulative, Ratio |
| Operations        | fulfillment_time, inventory_turnover, order_accuracy_rate      | Simple, Ratio     |

**Git Workflow:**

- Create branch: `git checkout -b feature/semantic-metrics`
- Add metrics: `git add models/metrics/ &amp;&amp; git commit -m "Add sales and finance metrics"`
- Test metrics: `dbt sl query --metrics revenue,profit --group-by date`
- Push changes: `git push origin feature/semantic-metrics`

### 8) Freshness Validation

### 8) **Documentation & Testing**

**The `dbt-project-evaluator` Package:** This is a package built by dbt Labs that automatically checks if you are following best practices (e.g., "Are all models documented?", "Are you joining in staging?").

- **Add to To-Do:** "Run `dbt build --select package:dbt_project_evaluator` to audit project structure."

**Exposures (For Lineage):** You didn't mention **Exposures**. This allows you to tell dbt "This model is used in a Power BI Dashboard." It adds a node to the lineage graph representing the dashboard.

- **Add to To-Do:** "Define `exposures.yml` to link Marts to the downstream Power BI Dashboard."
- Generate comprehensive dbt documentation using `dbt docs generate`
- Review and enhance model descriptions in schema.yml files
- Document column-level descriptions for all models
- Add data lineage diagrams showing source-to-mart flow
- Create data dictionary with business definitions
- Write comprehensive tests for data quality and business logic
- Set up dbt test coverage reports
- Document testing strategy and acceptance criteria
- Create runbook for troubleshooting common issues
- Review all Git commits and ensure clear commit history

### 9) Optimization and Best Practices

Phase 3 is where the magic happens. You are turning raw, messy data into clean, valuable insights. This is the core of "Analytics Engineering."

To impress hiring managers, you shouldn't just write SQL queries; you need to structure your project for **scalability, readability, and performance**.

Here is a guide to Optimization and Best Practices for implementing Phase 3 with dbt and Snowflake.

### 1. Architectural Optimization: The "Layer Cake" Approach

Do not write one massive SQL query that goes from raw data to the final dashboard. Break it down into modular layers. This is the industry standard.

### **Layer A: Staging (`models/staging`)**

- **Goal:** Clean 1-to-1 representation of your source data.
- **Best Practices:**
  - **Materialization:** Configure as `view` (saves storage costs in Snowflake).
  - **Renaming:** Rename obscure column names (e.g., `CUST_ID_01`) to friendly names (`customer_id`).
  - **Casting:** Fix data types here (e.g., cast strings to dates).
  - **No Joins:** strictly avoid joining tables in staging.
- **Snowflake Optimization:** Because these are views, Snowflake computes them only when queried. This keeps your storage footprint low.

### **Layer B: Intermediate (`models/intermediate`)**

- **Goal:** Isolate complex logic and joins.
- **Best Practices:**
  - **Materialization:** `ephemeral` (acts like a CTE, doesn't create an object in Snowflake) or `table` (if the logic is heavy and reused often).
  - **Business Logic:** Perform your currency conversions, heavy joins, and complex aggregations here.
  - **Reusability:** If you need to calculate "User Churn" for three different dashboards, build the logic once here, then reference it everywhere.

### **Layer C: Marts (`models/marts`)**

- **Goal:** The final tables ready for Power BI.
- **Best Practices:**
  - **Materialization:** `table` or `incremental`. This ensures Power BI reads from a pre-built table, making the dashboard fast.
  - **Star Schema:** Structure these as Fact tables (measurements, events) and Dimension tables (attributes, people, products).
  - **Hiding:** Hide helper columns (like surrogate keys) that the end-user doesn't need.

---

### 2. Coding Best Practices: Writing "Clean" dbt SQL

Readable code is maintainable code. Adoption of a style guide is a strong signal of seniority.

- **Use CTEs (Common Table Expressions):** Start every model by importing your data using CTEs at the top, then your logic, then a final select.
  - *Why?* It makes debugging in Snowflake incredibly easy. You can just highlight the logic part and run it.
- **The `ref()` Function is Mandatory:** Never hardcode a table name (e.g., `FROM RAW_DB.PUBLIC.ORDERS`). Always use `FROM {{ ref('stg_orders') }}`.
  - *Why?* This allows dbt to build the dependency graph (DAG) and run models in the correct order.
- **Lowercase Everything:** SQL keywords can be capitalized, but table/column names should be lowercase to avoid Snowflake's case-sensitivity headaches (quoting identifiers).

**Example of a Clean Model Structure:**

SQL

```jsx
/* models/marts/fct_orders.sql */

with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        payments.amount
    from orders
    left join payments using (order_id)
)

select * from final
```

---

### 3. Snowflake Optimization Strategies

Snowflake charges by credit (compute) and storage. Optimizing your dbt project saves money and time.

- **Use Incremental Models for Large Tables:**
  - *Scenario:* You have a transaction table with 10 million rows.
  - *Bad Practice:* Dropping and recreating the table every day (`materialized='table'`).
  - *Optimization:* Use `materialized='incremental'`. This tells dbt to only process *new* rows added since the last run.
  - *How:*SQL
    ```jsx
    {{ config(materialized='incremental', unique_key='transaction_id') }}
    select * from {{ ref('stg_transactions') }}
    {% if is_incremental() %}
      where transaction_date > (select max(transaction_date) from {{ this }})
    {% endif %}
    ```
- **Separate Warehouses (If scaling up):**
  - In a real company, you use a "Loading Warehouse" for Fivetran/ingestion and a separate "Transforming Warehouse" for dbt.
  - *Portfolio Tip:* For your project, stick to an **X-Small** warehouse. It is powerful enough for almost any portfolio dataset and is the cheapest option.
- **Snowflake Zero-Copy Cloning (The "Killer Feature"):**
  - Mention in your documentation that for testing, you utilize Snowflake's "Zero-Copy Cloning" to create instant copies of your production database for development without doubling storage costs.

---

### 4. DataOps Implementation in Phase 3

This is how you ensure reliability.

- **Testing is NOT Optional:**
  - In your `schema.yml` files, every primary key must have:YAML
    - `name: customer_id tests: - unique - not_null`
  - *Optimization:* Add tests *upstream* (in Staging). If data is bad at the source, stop the pipeline before it breaks your dashboard.
- **Documentation as Code:**
  - Use the `description:` field in your `.yml` files.
  - *Best Practice:* Do not describe *what* the column is (e.g., "This is the created_at column"). Describe the *context*(e.g., "The UTC timestamp when the user clicked the checkout button. Nulls indicate abandoned carts.").
- **DRY (Don't Repeat Yourself) with Macros:**
  - If you find yourself writing the same SQL snippet 3 times (e.g., converting cents to dollars, or specific date formatting), turn it into a **Jinja Macro**.
  - *Portfolio Win:* Creating a custom macro demonstrates advanced dbt usage.

---

### 5. Summary Checklist for Phase 3

| **Area**        | **Best Practice**                | **Why it matters**                              |
| --------------- | -------------------------------- | ----------------------------------------------- |
| **Structure**   | Staging -> Intermediate -> Marts | Keeps logic modular and organized.              |
| **Coding**      | Import CTEs at the top           | Makes debugging significantly faster.           |
| **Coding**      | Use `{{ ref() }}` everywhere     | Builds the lineage graph correctly.             |
| **Performance** | Incremental Models               | Drastically reduces run time and compute costs. |
| **Reliability** | `unique` and `not_null` tests    | Prevents bad data from reaching Power BI.       |
| **Context**     | `description` fields in YAML     | Ensures the data is understandable by others.   |

### Next Step for You

Would you like me to provide a **template for a `schema.yml` file** or a **sample code block for a custom dbt Macro** (like a currency converter) that you can copy directly into your project?

##

[Phase 3: Delivarables](https://www.notion.so/Phase-3-Delivarables-2cd1bb84f4a481a4894ef03a5a24e4cb?pvs=21)

[What to ask AI ](https://www.notion.so/What-to-ask-AI-2cd1bb84f4a4814186bbf45f09ea6a06?pvs=21)

# **🚀 Phase 4: Deployment, Orchestration & DataOps**

### **Objectives**

1. Establish a strict **"Gated Promotion Protocol"** to move code from Dev (`ANALYTICS_DEV`) to Prod (`ANALYTICS_PROD`).
2. Ensure Production data is protected from "work in progress" code.
3. Document the Standard Operating Procedure (SOP) for updating the pipeline so the process is repeatable and audit-ready.

### **AI Workflow**

### **Custom Chat Modes**

**8️⃣ Mode Name: `AE_Ops_Manager`**

### **1) The Deployment Protocol (SOP)**

> Goal: A repeatable checklist to ensure you never accidentally break Production. This acts as your "Human CI/CD."

**✔ 14.1 Pre-Deployment Validation (The "Gate")**

- [ ] [ ] **Code Freeze**
  - *Action:* Ensure all Feature Branches are merged into `main`. No open PRs should be pending for this release.
- [ ] [ ] **Clean State**
  - *Action:* Run `dbt clean` locally to remove old artifacts/compiled SQL.
- [ ] [ ] **Local Test Run**
  - *Action:* Run `dbt build --target dev` one last time to ensure 0 errors on your machine.

**✔ 14.2 Execution (The "Push")**

- [ ] [ ] **Freshness Check**
  - *Command:* `dbt source freshness`
  - *Check:* If this fails, **STOP**. Do not deploy stale data to production.
- [ ] [ ] **Switch Target**
  - *Command:* `dbt build --target prod`
  - *Note:* This explicitly targets the `ANALYTICS_PROD` warehouse defined in your `profiles.yml`.
- [ ] [ ] **Verify Artifacts**
  - *Action:* Open Snowflake. Query `ANALYTICS_PROD.MARTS.FCT_ORDERS`.
  - *Check:* Is the `_loaded_at` timestamp current? Are row counts consistent with Dev?

**✔ 14.3 Post-Deployment Audit**

- [ ] [ ] **Documentation Re-Build**
  - *Command:* `dbt docs generate`
  - *Action:* Commit the new `target/` files to your `gh-pages` branch (if hosting docs) or save them locally.

### **2) Power BI Refresh Strategy**

> Goal: Ensure the Dashboard sees the new Production data immediately.

**✔ 15.1 Dataset Refresh**

- [ ] [ ] **Manual Trigger**
  - *Action:* Go to Power BI Service -> Workspace -> Dataset.
  - *Action:* Click the **"Refresh Now"** icon.
- [ ] [ ] **Validation**
  - *Action:* Open the Dashboard. Check the "Last Refreshed" timestamp on the header card.
  - *Action:* Spot check one key metric (e.g., "Yesterday's Revenue") to ensure it matches Snowflake.

### **3) Incident Recovery (The "Undo" Button)**

> Goal: A pre-planned strategy for what to do if you deploy a bug.

**✔ 16.1 Rollback Plan**

- [ ] [ ] **Immediate Code Revert**
  - *Action:* Revert the Git merge commit on `main`.
- [ ] [ ] **Re-Deploy**
  - *Action:* Run `dbt build --target prod` immediately with the reverted code to restore the previous state.
- [ ] [ ] **Communication**
  - *Action:* (Simulated) "Notify stakeholders that data is stale until 10:00 AM."

[Deliverables](https://www.notion.so/Deliverables-2cd1bb84f4a481728447f9d3e0f35f1c?pvs=21)

# **🎨 Phase 5: Semantic Modeling & Visualization (Power BI)**

### DataFinOps Strategy

### **A. Compute & License Optimization (The "Snowflake Bill" Saver)**

- [ ] [ ] **Prefer Import Mode over DirectQuery:**
  - *The Logic:* **DirectQuery** sends a SQL query to Snowflake *every time* a user clicks a slicer. This keeps your Snowflake warehouse running (and billing) constantly.
  - *The FinOps Move:* Use **Import Mode**. It hits Snowflake *once* a day (during refresh), caches the data, and then costs **$0** in Snowflake compute for the rest of the day, no matter how many users view it.
- [ ] [ ] **Incremental Refresh:**
  - *The Logic:* Reloading 10 years of history every morning burns Snowflake credits.
  - *The FinOps Move:* Configure Power BI **Incremental Refresh** to only fetch the last 3 days of data.

### **B. Memory Optimization (The "Capacity" Saver)**

- [ ] [ ] **Disable "Auto Date/Time":**
  - *The Logic:* By default, Power BI creates hidden date tables for every date column. This bloats file size by 30-50%.
  - *The FinOps Move:* Turn it **OFF** globally. Use a single central Date Dimension.
- [ ] [ ] **Vertical Partitioning (Remove Unused Columns):**
  - *The Logic:* Power BI is a columnar database. High-cardinality columns (like a unique `Transaction_GUID` or `Description` text) that aren't used in charts consume massive RAM.
  - *The FinOps Move:* "Select Columns" in Power Query to remove anything not strictly needed for visualization.
- [ ] [ ] **Star Schema Enforcement:**
  - *The Logic:* One big flat table is slow and heavy.
  - *The FinOps Move:* Star Schema (Fact/Dim) reduces the number of rows and unique values stored, lowering memory usage.
- [ ] [ ] **Visual Rendering Cost:**
  - *The Move:* Limit the number of visuals per page (e.g., max 8).
  - *The Save:* Complex pages generate complex DAX queries. If using DirectQuery, this spikes Snowflake CPU usage.

### 1) Connection Strategy & Execution(done)

> Goal: Select the optimal data architecture (Import vs. DirectQuery) and establish a secure, optimized connection between Power BI and the Snowflake Production Marts.

### **✔ 12.1.1 Strategy: Choose Connection Mode**

- [ ] [ ] **Assess Data Volume & Latency**
  - **Decision:** Choose **Import Mode** for your portfolio.
  - *Reason:* Best performance, full DAX capabilities, and easiest to share online. DirectQuery is likely overkill unless you have >10GB of data.
- [ ] [ ] **(Optional) Plan for Hybrid/Composite**
  - *Concept:* If you have one massive Fact table, you might DirectQuery that one table while Importing Dimensions. (Stick to Import for now to keep it simple).

### **✔ 12.1.2 Execution: Connect to Snowflake**

- [ ] [ ] **Gather Credentials (The "Connection String")**
  - **Server:** Copy your Snowflake URL (e.g., `xy12345.us-east-1.snowflakecomputing.com`).
  - **Warehouse:** Use `REPORTING_WH` (The X-Small warehouse we set up earlier).
  - **Role:** Use `REPORTER_ROLE` (Read-only access to Marts).
- [ ] [ ] **Perform "Get Data"**
  - **Action:** Power BI Desktop -> Get Data -> Database -> Snowflake.
  - **Input:** Paste Server and Warehouse.
  - **Advanced Options:** Set "Command Timeout" to 15 minutes (optional, prevents timeouts on initial heavy loads).
  - **SQL Statement:** **Leave Blank.** (Best practice is to navigate the explorer, not write custom SQL, to ensure Query Folding works).
- [ ] [ ] **Authenticate**
  - **Method:** Select **Microsoft Account** (if using SSO/Azure AD) or **Basic** (Username/Password) depending on your setup.
  - **Action:** Sign in and connect.

### **5.1 Environment & Git Setup (Do This First)**

_Set this up properly so you can track changes from the start._

- [ ] [ ] **Enable PBIP Format**
  - _Action:_ File > Options > Preview Features > Check "Power BI Project (.pbip) save option".
- [ ] [ ] **Save as Project**
  - _Action:_ File > Save As > Browse > Select **"Power BI Project files (\*.pbip)"**.
  - _Result:_ Creates `[Project].Report` and `[Project].Dataset` folders.
- [ ] [ ] **Configure `.gitignore`**
  - _Action:_ Add `.pbix`, `.abf`, and `localSettings.json` to your gitignore file.
  - _Why:_ Keeps your repo clean—you only commit the definitions, not the cached data.

### ✔ 12.1.3 Select & Load Data

- [ ] [ ] **Navigate to Schema**
  - **Path:** `ANALYTICS_PROD` -> `MARTS`.
  - **Selection:** Check the boxes for your `fct_` and `dim_` tables.
  - **Selection:** Check the box for `dim_date` and `dim_security` (if applicable).
  - **Crucial:** Do **NOT** select tables from `STAGING` or `RAW`.
- [ ] [ ] **Pre-Load Configuration**
  - **Action:** Click **"Transform Data"** (Power Query) instead of "Load".
  - **Why:** You always want to verify types before the first load.

### ✔ 12.1.4 Incremental Refresh

- [ ] [ ] **Create Range Parameters (Mandatory Names)**
  - *Action:* In Power Query, go to **Manage Parameters** -> **New Parameter**.
  - *Name:* `RangeStart` (Type: Date/Time, Value: `2024-01-01 00:00:00`).
  - *Name:* `RangeEnd` (Type: Date/Time, Value: `2024-12-31 00:00:00`).
  - *Note:* Case sensitivity matters exactly.
- [ ] [ ] **Apply Parameter Filter**
  - *Action:* Select `fct_orders` -> Select `order_date` column.
  - *Action:* Custom Filter -> "is after or equal to" `RangeStart` **AND** "is before" `RangeEnd`.
- [ ] [ ] **Verify Query Folding**
  - *Action:* Right-click the last "Filtered Rows" step -> **View Native Query**.
  - *Check:* If the SQL is visible, folding is active. If greyed out, move this step to the top.
- [ ] [ ] **Define Refresh Policy**
  - *Action:* Close Power Query. Right-click `fct_orders` in the sidebar -> **Incremental Refresh**.
  - *Setting:* Toggle "Incremental refresh" **On**.
  - *Setting:* Archive data starting: **2 Years**.
  - *Setting:* Refresh data starting: **3 Days**.
  - *Action:* Apply. (Note: The first publish will be slow; subsequent ones will be fast).

---

### 🌟 Best Practices for Step 12.1

- **The "Reporting Warehouse" Rule:**
  - Always connect Power BI to a dedicated Snowflake Warehouse (e.g., `REPORTING_WH`).
  - *Why?* If you connect to your `TRANSFORM_WH` (used for dbt), and dbt is running a heavy job, your dashboard will become slow. Isolating them protects the user experience.
- **Native Query vs. Exploring:**
  - Avoid writing `SELECT * FROM table` inside the Power BI connection box.
  - Instead, connect leaving the SQL box empty, and select the table from the list.
  - *Why?* This supports **Query Folding**. Power BI can push filter logic back to Snowflake more effectively if it knows it's looking at a specific table object.
- **Case Sensitivity:**
  - Snowflake is case-sensitive. If you type your warehouse name as `reporting_wh` but in Snowflake it is `REPORTING_WH`, the connection might fail. Use ALL CAPS if your objects were created that way.

---

### 📌 Summary Update for Your To-Do List

_You can replace your previous "12.1 Connection" section with this more detailed version._

### **✔ 12.1 Connection & Source Configuration**

- [ ] [ ] **Select Strategy** Mode: Select **Import** (Recommended for Portfolio) or **DirectQuery** (Enterprise/Real-time).
- [ ] [ ] **Configure Snowflake Source** Server: `[your_account].snowflakecomputing.com` Warehouse: `REPORTING_WH` (Isolated compute). Role: `REPORTER_ROLE` (Read-only access).
- [ ] [ ] **Select Objects** Database: `ANALYTICS_PROD` (Never connect to Dev). Schema: `MARTS`. Tables: Select Facts, Dims, and Security tables only.
- [ ] [ ] **Initial Transformation** Action: Click **Transform Data** to open Power Query Editor (Phase 12.1.5).

| **Connection Mode**    | **Best For**                                          | **Pros**                                                              | **Cons**                                                       | **When to Use**                                              |
| ---------------------- | ----------------------------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------ |
| **Import**             | Small-medium datasets (<1GB), fast performance needed | ·Fastest query performance·Offline access·All DAX functions available | ·Scheduled refresh only·Dataset size limits·Memory consumption | Historical analysis, static dimensions, performance critical |
| **DirectQuery**        | Real-time data, large datasets (>10GB)                | ·Real-time data·No size limits·Lower memory usage                     | ·Slower performance·Limited DAX functions·Network dependent    | Live dashboards, massive datasets, real-time monitoring      |
| **Hybrid (Composite)** | Mix of real-time facts and static dimensions          | ·Balanced performance·Flexible refresh·Optimized queries              | ·Complex setup·Harder to troubleshoot·Mixed limitations        | Large facts with small dims, mixed freshness needs           |

**Key Steps:**

1. Assess data size and refresh requirements
2. Connect Power BI to Snowflake using chosen mode
3. Load dbt mart tables (fct*\*, dim*\*)
4. Test performance with sample queries
5. Configure refresh schedule (Import) or optimize queries (DirectQuery)
6. Document choice and monitor performance

**Quick Decision Guide:**

- Data <1GB + scheduled refresh OK → **Import**
- Data >10GB + real-time needed → **DirectQuery**
- Small dims + large facts → **Hybrid**

### 2) Power BI Table and Model View & Semantic Model Configuration(done)

> Goal: Configure a high-performance Semantic Model that enforces the Star Schema, secures data via RLS, and provides a polished experience for end-users.

_Set this up properly so you can track changes from the start._

- [ ] [ ] **Enable PBIP Format**
  - *Action:* File > Options > Preview Features > Check "Power BI Project (.pbip) save option".
- [ ] [ ] **Save as Project**
  - *Action:* File > Save As > Browse > Select **"Power BI Project files (\*.pbip)"**.
  - *Result:* Creates `[Project].Report` and `[Project].Dataset` folders.
- [ ] [ ] **Configure `.gitignore`**
  - *Action:* Add `.pbix`, `.abf`, and `localSettings.json` to your gitignore file.
  - *Why:* Keeps your repo clean—you only commit the definitions, not the cached data.

### **✔ 12.1 Connection & Environment Setup**

- [ ] [ ] **Connect to Snowflake**
  - Source: Connect to `ANALYTICS_PROD` (or `MARTS` schema).
  - Selection: Import **only** the necessary `fct_` and `dim_` tables.
  - Mode: Choose **Import** (for speed) or **DirectQuery** (for real-time/security compliance).
- [ ] [ ] **Configure Global Settings**
  - Action: Go to **Options -> Current File -> Data Load**.
  - Action: Uncheck **"Auto Date/Time"** (Prevents hidden table bloat).
  - Action: Uncheck **"Autodetect new relationships after data is loaded"** (Manual control is safer).

**✔ 12.1.5 Schema Drift Protection (Power Query – Table.SelectColumns)**

- [ ] Add “Schema Hardening” Step per Table
  - Action: In Power Query, for each fct* and dim* table, add a final step named
    Schema Hardening – Select Columns.
  - Action: Use Table.SelectColumns() to keep only the columns you want in the model.
    Example:

```jsx
- Example:
-

#`"Schema Hardening – Select Columns" =`

`Table.SelectColumns(`

`#"Previous Step",`

`{"order_id", "order_date", "customer_id", "revenue"}`

`)`
```

- Why:
  - If new columns are added upstream (dbt/Snowflake) → they are ignored safely.
  - If a required column is renamed or removed → Power Query errors clearly, instead of silently loading wrong data.
- [ ] Apply to All Fact & Dimension Tables
  - Scope: fct_orders, fct_payments, dim_customers, dim_products, dim_date, etc.
  - Rule: The list in Table.SelectColumns() is your Power BI data contract for that table.
- [ ] Keep Query Folding (Performance)
  - Action: Ensure Schema Hardening – Select Columns stays near the top of the step list (but after the Source step) so that View Native Query is still enabled.
  - Check: Right-click last step → View Native Query is not greyed out.
- [ ] Document Selected Columns
  - Action: For each table, copy the column list into your Notion Data Dictionary or Model Documentation page.
  - Purpose: Makes it clear which columns are part of the contract between dbt Marts → Power BI model
  - [ ] **Configure Incremental Refresh Parameters**
  - *Action:* Create `RangeStart`/`RangeEnd` -> Filter `fct_orders` -> Set Policy (Archive 2 Years, Refresh 3 Days).

### **✔ 12.2 Data Modeling (The Star Schema)**

- [ ] [ ] **Organize Model Layout**
  - Layout: Arrange `fct_` tables in the center and `dim_` tables surrounding them.
- [ ] [ ] **Define Relationships**
  - Cardinality: Ensure all relationships are **One-to-Many (1:\*)**.
  - Direction: Set Cross-filter direction to **Single** (Dimensions filter Facts).
  - Active: Ensure primary relationships are Active; secondary (e.g., Ship Date) are Inactive.
- [ ] [ ] **Configure Date Table**
  - Action: Select `dim_date` (imported from Snowflake).
  - Setting: Right-click table -> **Mark as Date Table** -> Select `date_key`.
- [ ] [ ] **Configure Many-to-Many (If Bridge Table exists)**
  - Action: Set Bidirectional filtering **only** on the relationship between `Fact <-> Bridge <-> Dim`.

### **✔ 12.3 Column Configuration (Metadata Layer)**

- [ ] [ ] **Data Type Validation**
  - Action: specific check: Key columns = Text/Int, Amounts = Decimal/Currency, Dates = Date.
- [ ] [ ] **Hide Technical Columns**
- *Action:* Select and **Hide** all: Surrogate Keys (`_key`), Source IDs, Audit Flags (`_loaded_at`), and Sort Columns (`month_sort`).
- [ ] [ ] **Configure Sort Order**
  - Action: Select `Month Name` -> **Sort by Column** -> `Month Number`.
  - Action: Select `Day Name` -> **Sort by Column** -> `Day of Week`.
- [ ] [ ] **Define Data Categories**
  - Action: Set `City`, `Country`, `Zip` to geospatial categories (enables Map visuals).
  - Action: Set URL columns to **Web URL** or **Image URL**.
- [ ] [ ] **Create Hierarchies**
  - Action: Build `Date Hierarchy` (Year > Quarter > Month > Day).
  - Action: Build `Geo Hierarchy` (Country > State > City).

### **✔ 12.4 DAX Development & Calculations**

- [ ] **Setup Dedicated Measures Table**
  - Action: Create a blank table named `_Measures` (Underscore keeps it at the top).
  - Organization: Create **Display Folders** inside (e.g., `1. Sales`, `2. Ratios`, `3. Time Intel`).
- [ ] [ ] **Create Base Measures**
  - Logic: `Total Revenue = SUM(fct_orders[revenue])`.
  - Formatting: Apply Currency (`$`), Thousands Separator (`,`), and decimal places (`0` or `2`).
- [ ] [ ] **Create Time Intelligence**
  - Logic: Create `Revenue YTD`, `Revenue YoY`, `Revenue MoM` using `CALCULATE` and `SAMEPERIODLASTYEAR`.
- [ ] [ ] **Integrate dbt Semantic Layer (Optional)**
  - Action: If using dbt MetricFlow, connect to the semantic model or replicate logic exactly.
- [ ] [ ] **Implement Calculation Groups**
  - Tool: **Tabular Editor**.
  - Action: Create a "Time Intelligence" group to toggle visuals between Current/YTD/YoY dynamically.

### **✔ 12.5 Security (Row Level Security)**

- [ ] [ ] **Import Security Table**
  - Action: Ensure `dim_security_rls` is in the model.
- [ ] [ ] **Define Roles**
  - Action: Modeling -> **Manage Roles**.
  - Logic: Create role `DynamicAccess`. Filter `dim_security_rls` where `[user_email] = USERPRINCIPALNAME()`.
- [ ] [ ] **Validate Security**
  - Action: **View As** -> Check `DynamicAccess` -> Enter a specific user email to verify data filters correctly.

### **✔ 12.6 Quality Assurance & Optimization**

- [ ] [ ] **Run Best Practice Analyzer (BPA)**
  - Tool: **Tabular Editor 3** (or 2.x).
  - Action: Scan model for rules (e.g., "Avoid Bi-Directional," "Hide Foreign Keys"). Fix all High Severity warnings.
- [ ] [ ] **Audit Performance**
  - Tool: **DAX Studio**.
  - Action: Run **VertiPaq Analyzer**. Identify large columns taking up RAM that aren't used.
- [ ] [ ] **Validate Data Accuracy**
  - Action: Create a generic "QA Page".
  - Check: Compare `Total Revenue` in PBI vs. `SELECT SUM(REVENUE) FROM MARTS.FCT_ORDERS` in Snowflake.
- [ ] [ ] **Generate Documentation**
  - Action: Use DAX Studio to export a list of all Measures, descriptions, and dependencies.

**A) Create Data Dictionary Table (DAX)**

- Modeling → New Table → Paste the full \_Data Dictionary DAX Script

[DAX Script](https://www.notion.so/DAX-Script-2cd1bb84f4a481318a8cf9539a0a5acc?pvs=21)

- Confirm it shows:
  - Columns (from INFO.VIEW.COLUMNS)
  - Measures (from INFO.VIEW.MEASURES)
  - Tables (from INFO.VIEW.TABLES)
  - Relationships (metadata)

📌 This table should be hidden from report pages (only for documentation)

**B) Export Documentation for AI**

- Create a table visual using \_Data Dictionary
- Export as CSV
- Upload CSV in Notion → “Data Dictionary — Export”
- Take model screenshots for evidence (relationships, measure folders)

**C) Generate Measure Descriptions Using AI**

(Tabular Editor preferred)

- Copy-paste full metadata TMDL code into AI
- Use the prompt below

📥 AI Prompt to paste

`The TMDL code below contains details about the DAX measures in my Power BI semantic model.`

`Please add clear, concise, human-readable descriptions for each measure, based on the DAX calculation. Each measure should be preceded by "I/I" and added to a line directly above the measure name. Use the description for Total Cost as an exampleto follow.`

`Do not modify any other code, only add measure descriptions. The TMDL code structure, including tabs, indentation and formatting must remain exactly consistent with the original format below:`

(Immediately paste your DAX TMDL code after this line)

**D) Add Descriptions Back to Model**

- Paste the TMDL in DAX view and hit apply

**E) Create a Documentation Page in Report (Optional)**

- A hidden tab with search + filters to explore Data Dictionary

**F) Governance Audit**

- Add “Documentation Version” column manually:
  - v1.0 = First AI-generated
  - Update when new measures added
- Add Change Log in Notion:
  - Why change?
  - Impacted reports?
  - Date + Owner

**📌 Summary Deliverables (Add to your Phase Deliverables list)**

| **Deliverable**                        | **Evidence to Attach**                    |
| -------------------------------------- | ----------------------------------------- |
| Live Data Dictionary Table in Power BI | Screenshot of \_Data Dictionary           |
| CSV Export                             | File uploaded to Notion                   |
| AI-generated Descriptions              | Before/After screenshot in Tabular Editor |
| Documentation Page (Optional)          | Screenshot                                |
| Governance Log                         | Notion table                              |

#

| **Value to Employers**                       | **Proof in Portfolio**                   |
| -------------------------------------------- | ---------------------------------------- |
| You deliver self-service analytics           | Tooltips + metadata visible to end-users |
| You reduce support tickets                   | Q&A understands semantic model           |
| You build governed BI                        | Change logs + definitions                |
| Shows understanding of Data Governance       | ADLC Documentation                       |
| Shows you know Power BI Enterprise Practices | Not just visuals                         |

This directly increases your portfolio quality score.

# **If you want, I can now generate:**

✔ Notion template of this whole phase

✔ Checklist table formatted for copy-paste

✔ Example Change Log entries (real-world style)

✔ A visual architecture graphic showing flow: dbt ➝ Marts ➝ Power BI ➝ Governance

Which one should I deliver next?

---

### 🌟 Phase 12 Best Practices

- **Version Control (.pbip):** Save your file as a **Power BI Project (.pbip)** instead of `.pbix`. This allows you to track changes in Git (e.g., seeing exactly which measure formula changed).
- **Explicit Measures:** Never drag a raw numeric column onto a visual. Always wrap it in a Measure (e.g., `SUM(Sales)`). This allows you to change logic centrally later without breaking 50 reports.
- **Star Schema Discipline:** If you are tempted to create a "Calculated Column" to join two tables, **stop**. Go back to dbt and fix the model there. Power BI is for aggregation, not cleaning.
- **Descriptions:** Add descriptions to every Measure in the Model View. These appear as tooltips for users in the "Data" pane, reducing "What does this mean?" questions.

### **✔ 13.1 Mark Unique Identifiers (Crucial for AI & Q&A)**

- **Why?** Power BI's Q&A and Copilot need to know which column represents the "ID" of a row (uniqueness) vs. the "Label" of a row (display name).
- **Where?** Go to **Model View** > Select a Dimension Table > **Properties Pane** > **Advanced** section.
- [ ] [ ] **Set "Key Column" (The ID)**
  - *Action:* Select your Primary Key (e.g., `Customer Key`).
  - *Setting:* In Properties > Advanced > **Key Column**, select `Customer Key`.
  - *Effect:* Tells Power BI "This column is unique." Required for "Featured Tables" in Excel.
- [ ] [ ] **Set "Row Label" (The Name)**
  - *Action:* Select your Name Column (e.g., `Customer Name`).
  - *Setting:* In Properties > Advanced > **Row Label**, select `Customer Name`.
  - *Effect:* When users ask Q&A "Count Customers," it counts distinct Keys but displays Names.

### **✔ 13.2 Create Data Dictionary using DAX**

- **Why?** Instead of manually writing documentation in Excel, you create a live table inside Power BI that reads its own metadata.
- **Where?** Go to **Modeling Ribbon** > **New Table**.
- [ ] [ ] **Create the "Model Metadata" Table**
  - *Action:* Paste the following DAX code to generate a live list of all your measures and descriptions.
  ```jsx
  *Code:*Code snippet
  ```
  ```jsx
  Model Dictionary =
  UNION(
      SELECTCOLUMNS(
          INFO.VIEW.MEASURES(),
          "Type", "Measure",
          "Name", [Name],
          "Description", [Description],
          "Formula", [Expression],
          "Table", [Table]
      ),
      SELECTCOLUMNS(
          INFO.VIEW.COLUMNS(),
          "Type", "Column",
          "Name", [Name],
          "Description", [Description],
          "Formula", [Expression],
          "Table", [Table]
      )
  )
  ```
- [ ] [ ] **Build the Dictionary Page**
  - *Action:* Create a hidden report page. Add a **Table Visual** using columns from your new `Model Dictionary` table.
  - *Benefit:* You now have a searchable list of every metric and calculation in your model, directly accessible to users.

### 📦 Phase 12 Deliverables

1. **✅ Optimized Semantic Model:** A clean `.pbip` file with a verified Star Schema.
2. **✅ BPA Report:** A screenshot from Tabular Editor showing 0 High-Severity issues.
3. **✅ Data Dictionary:** An Excel export of all Measures and Definitions.
4. **✅ QA Validation:** A simple matrix showing Power BI totals matching Snowflake totals.

- **✅ Key Columns Set:** All Dimension tables have "Key Column" and "Row Label" defined in properties.\
- **✅ Dictionary Table:** A generic `Model Dictionary` table present in the model using `INFO.VIEW` functions.
- **✅ Clean Interface:** No technical keys visible in Report View; all Sort columns hidden.
- **✅ Descriptions:** Tooltips appear when hovering over Measures in the Data Pane.

### 3) Visualization and Reporting(done)

> Goal: Transform your data model into a compelling, interactive story using "Information Design" principles, ensuring accessibility, performance, and mobile responsiveness.

# **🎯**

# **Slicer & Query Reduction Strategy (Prevent Query Explosion)**

Purpose:

Control unnecessary DAX query execution caused by slicer interactions to protect performance, Snowflake compute, and user experience.

# **🧠 Why This Matters (Context for Reviewers)**

- Every slicer interaction triggers multiple DAX queries
- On large models, this leads to:
  - Slow visuals
  - Excessive CPU usage
  - Poor scalability in Power BI Service
-
- This section enforces controlled, batched filtering — a senior BI best practice

# **✅ 12.X Query Reduction Configuration (Mandatory)**

**✔ Enable “Apply” Button for Slicers**

Action Path

- Power BI Desktop →
  File → Options and settings → Options → Query reduction

Settings

- [ ] Enable Add an Apply button to each slicer
- [ ] (Optional) Disable Auto apply

Result

- Slicer selections do not trigger queries immediately
- Queries execute only when user clicks Apply
- Reduces query count by 50–70% on interactive pages

📌 Rule:

All reports in this project must use Apply buttons for slicers.

# **✅ 12.X Slicer Design Rules (Performance Guardrails)**

**🔹 Rule 1: Prefer**

**Single-Select Slicers**

Action

- Select slicer → Format pane → Selection controls
- Enable Single select

Why

- Prevents combinatorial filter explosions
- Keeps DAX evaluation paths simple
- Improves cache reuse

📌 Exception:

Multi-select allowed only for low-cardinality dimensions (e.g., Region with <10 values).

**🔹 Rule 2: Restrict Slicers to Low-Cardinality Fields**

Allowed Slicer Fields

- Year
- Month
- Region
- Category
- Channel

Disallowed Slicer Fields

- Customer Name
- Product Name / SKU
- Transaction ID
- Free-text attributes

📌 High-cardinality columns belong in the Filter Pane, not slicers.

| **Aspect**      | **Filter Pane** | **Slicer**      |
| --------------- | --------------- | --------------- |
| Query Execution | Batched         | Per interaction |
| UI Clutter      | Hidden          | Visible         |
| Performance     | High            | Lower           |
| User Abuse      | Limited         | High            |

# **✅ 12.X Filter Pane Usage (Preferred for Detailed Filtering)**

**Why Filter Pane is Preferred**

**Filter Pane Rules**

- Use Filter Pane for:
  - Customer
  - Product
  - Store
  - SKU
-
- Keep slicers only for high-level navigation

📌 Filters apply once, not on every click.

# **✅ 12.X Recommended Page Layout Pattern (Standard)**

Header Area

- Year (Single-select slicer)
- Month (Single-select slicer)
- Region (Single-select slicer)
- Apply Button enabled

Right-Side Filter Pane

- Customer
- Product
- Channel
- Store

This layout balances:

- Performance
- Discoverability
- Professional UX

# **❌ Anti-Patterns (Explicitly Forbidden)**

- ❌ More than 5 slicers on a page
- ❌ Multi-select slicers on high-cardinality fields
- ❌ Slicers without Apply button
- ❌ Using slicers instead of Filter Pane for detailed filters

Violations must be fixed before publish.

### **✔ 14.1 Design Strategy & Wireframing (Pre-Development)**

- [ ] [ ] **Define the "Big 4" Business Questions**
  - **Action:** Explicitly list the 4 questions this specific report page must answer.
  - **Constraint:** If a visual does not answer one of these questions, delete it.
- [ ] [ ] **Sketch the Layout (Wireframe)**
  - **Tools:** Excalidraw, Figma, or Pen & Paper.
  - **Pattern:** Adopt the **"Z-Pattern"** layout (KPIs Top-Left → Trends Middle → Detail Data Bottom).
- [ ] [ ] **Map Questions to Visuals**
  - **Action:** Decide the chart type before clicking.
  - **Logic:**
    - Single Number → **Card (New)**
    - Trend over Time → **Line** or **Area Chart**
    - Comparison/Ranking → **Bar Chart**
    - Part-to-Whole → **Donut Chart** (Max 3 slices) or **Tree Map**.

| **Business Question** | **Visual** | **Purpose** | **Why This Visual Works** | **What To Do in the Visual (Action Steps)** | **Best Practices** |
| --------------------- | ---------- | ----------- | ------------------------- | ------------------------------------------- | ------------------ |

### **✔ 14.2 Canvas & Theme Configuration**

- [ ] [ ] **Configure Canvas Settings**
  - **Action:** Visualization Pane > Format Page > Canvas Background.
  - **Settings:** Color: Light Grey (`#F0F2F5`), Transparency: **0%**, Image Fit: **Fit**.
  - **Why:** A grey background makes white visual containers "pop" with a shadow effect.
- [ ] [ ] **Import Corporate JSON Theme**
  - **Action:** View > Browse for Themes > Select `corporate_theme.json`.
  - **Why:** Enforces standard fonts (Segoe UI), palettes, and font sizes globally to save time.
- [ ] [ ] **Set Page Metadata**
  - **Action:** Rename "Page 1" to a descriptive title (e.g., "Executive Summary").
  - **Action:** Hide any "Drill-through" or "Tooltip" pages from the navigation bar (Right-click tab > Hide).

### **✔ 14.3 Visual Construction (The Build)**

- [ ] [ ] **Build KPI Header (New Card Visual)**
  - **Action:** Use the "Card (New)" visual to group multiple KPIs.
  - **Setup:** Add "Reference Labels" to show MoM % change below the main number.
  - **Context:** Ensure every KPI has a "vs Target" or "vs Prior Period" indicator.
- [ ] [ ] **Configure Chart Hygiene**
  - **Titles:** Write descriptive titles (e.g., "Revenue by Region" not "Sum of Revenue by RegionName").
  - **Axes:** Remove Y-Axis titles if the chart title is self-explanatory. Remove X-Axis gridlines.
  - **Sorting:**
    - Time-based charts: **Chronological** (Jan → Dec).
    - Categorical charts: **Magnitude** (Highest value on top/left).
- [ ] [ ] **Apply Conditional Formatting**
  - **Action:** Add **Data Bars** to Matrix visual columns.
  - **Action:** Add **Icons** (Red/Green arrows) to Variance columns.
  - **Logic:** Use colors strictly for performance (Green=Good, Red=Bad). Use neutral Blue/Grey for categories.

### **✔ Step 1: Initialize the Metadata Table**

_Ensure the DAX script for `_Data Dictionary` table is executed as per Step 12.7.1._

- [ ] Name the table: `_Data Dictionary`.
- [ ] Set `IsHidden = True` for the table in Model View (Technical users reference it via the Report Page).

### **✔ Step 2: Configure the Hidden Wiki Page**

- [ ] Create a new Report Page titled: `📘 Data Dictionary`.
- [ ] Right-click the page tab > **Hide Page**.
- [ ] [ ] *Reason:* Keeps the dashboard navigation clean; users access it only via an information "ℹ️" button.

### **✔ Step 3: Build the "Data Glossary" Table Visual**

- [ ] [ ] **Visual Type:** Table.
- [ ] [ ] **Fields to include:**
  - `Table`: Groups information by Fact/Dimension (Context).
  - `Column/Measure/Relationship`: The exact name visible in the "Data" pane.
  - `Type`: Identifies if the row is a base column, calculated measure,or join.
  - `Description`: Business definition (generated by AI TMDL process).
  - `Expression`: The raw DAX logic (Technical source of truth).
- [ ] [ ] **Sorting Logic:** Sort primary by `Table` → secondary by `Type`.

### **✔ Step 4: Add Search & Wiki Navigation**

- [ ] [ ] **Type Slicer:** Filter by Column, Measure, or Table.
- [ ] [ ] **Table Slicer:** Filter by specific model (e.g., `fct_orders`).
- [ ] [ ] **Search Box:** Field: `Column/Measure/Relationship`. Use the "Text Search" slicer or standard slicer with Search enabled.

### **✔ Step 5: Add Metadata Inventory Cards (The "Model at a Glance")**

_Create these DAX measures to summarize the model complexity:_

- [ ] [ ] **Count Tables:** `COUNTROWS(FILTER('_Data Dictionary', [Information View]="Table"))`
- [ ] [ ] **Count Columns:** `COUNTROWS(FILTER('_Data Dictionary', [Information View]="Column"))`
- [ ] [ ] **Count Measures:** `COUNTROWS(FILTER('_Data Dictionary', [Information View]="Measure"))`
- [ ] [ ] **Layout:** Place these cards across the top header of the page.

### **✔ Step 6: Add Governance Context (Text Box)**

- [ ] Add a text box with the following disclaimer:
  > "This page documents the business logic of every field in this semantic model. Use the search bar to explore definitions. If logic appears incorrect or a description is missing, contact the Report Owner at: [Your Professional Email]."

## 🔐 Permissions Strategy (Professional Context)

In a real enterprise environment, the Data Dictionary page often has specific permissions applied, which shows advanced architectural thinking:

- **BI Developers/Data Engineers:** Full visibility to the page for auditing and debugging.
- **Business Users (Published App):** The page is often **excluded** from the final Published App to keep the navigation simple. If included, it's often read-only access.

This strategy demonstrates how you would separate **BI Developers ↔ Business Users** in a secure production environment.

### **✔ 14.4 Advanced Interactivity**

- [ ] [ ] **Configure Navigation (Slicers)**
  - **Setup:** Place slicers in a collapsible "Filter Pane" or a dedicated Header strip.
  - **Sync:** View > **Sync Slicers** > Ensure "Year" and "Region" filter all relevant pages simultaneously.
- [ ] [ ] **Implement Dynamic Titles (DAX)**
  - **Measure:** `Title Sales = "Sales Performance for " & SELECTEDVALUE('Dim_Geo'[Region], "All Regions")`.
  - **Action:** Format Visual > General > Title > **fx** > Field Value > Select Measure.
- [ ] [ ] **Setup Drill-Through**
  - **Action:** Create a "Transaction Details" page.
  - **Setup:** Drag `Order ID` into the "Drill-through" well on the details page.
  - **UX:** Add a "Back" button to the details page.
- [ ] [ ] **Configure Custom Tooltips**
  - **Action:** Create a page sized **"Tooltip"**. Add a mini-trend chart.
  - **Link:** Select main visual > Format > General > Tooltips > Type: **Report Page** > Page: [Tooltip Page].

### **✔ 14.5 Backend Management (The "Pro" Standard)**

- [ ] [ ] **Manage Selection Pane (Mandatory)**
  - **Action:** View > Selection.
  - **Task:** Rename **EVERY** object (e.g., `Card - Total Revenue`, `Chart - Monthly Trend`).
  - **Task:** Group related objects using **Ctrl+G** (e.g., `Group - Header`, `Group - KPI Panel`).
- [ ] [ ] **Manage Layer Order (Z-Index)**
  - **Action:** Move Slicers/Dropdowns to the **Top** of the list.
  - **Action:** Move Background Shapes to the **Bottom**.
  - **Why:** Prevents dropdown menus from getting cut off behind charts.

### **✔ 14.6 Mobile & Accessibility Polish**

- [ ] [ ] **Configure Mobile Layout**
  - **Action:** View > Mobile Layout.
  - **Task:** Re-arrange visuals into a single vertical column. Do not just shrink the desktop view.
- [ ] [ ] **Set Tab Order**
  - **Action:** Selection Pane > **Tab Order**.
  - **Logic:** Number visuals sequentially (Left-to-Right, Top-to-Bottom) for keyboard navigation.
- [ ] [ ] **Add Alt Text**
  - **Action:** Format > General > **Alt Text**.
  - **Content:** Add descriptions for Screen Readers (e.g., "Bar chart showing top 5 products by revenue").

### **✔ 14.7 QA & Final Optimization**

- [ ] [ ] **Run Performance Analyzer**
  - **Action:** View > Performance Analyzer > Start Recording > Refresh Visuals.
  - **Target:** Identify and fix any visual taking > **1000ms** to load.
- [ ] [ ] **Check "Empty States"**
  - **Test:** Filter to a region with 0 sales.
  - **Validation:** Does the chart show a clean "No Data" message, or does it break?
- [ ] [ ] **Add Metadata Footer**
  - **Measure:** `Last Refreshed = "Data updated: " & FORMAT(LASTDATE('fct_orders'[order_date]), "DD-MMM-YYYY")`.
  - **Visual:** Add a small text box/card in the bottom right corner displaying this measure.

---

### 🌟 Phase 14 Best Practices

- **The "Visual Header" Cleanup:**
  - Go to Format > General > **Header Icons**.
  - Turn **OFF** icons for static elements like KPI Cards, Shapes, and Text Boxes. It makes the report look like an App, reduces clutter, and prevents users from "Filtering a Text Box."
- **Visual Density Rule:**
  - Limit the report to **6-8 major visuals** per page. Cognitive load increases drastically after 8 visuals.
- **Avoid "Chart Junk":**
  - If a value is labeled on the bar (Data Label), you do **not** need the Y-Axis. Delete the axis to save whitespace.
- **Consistent Margins:**
  - Ensure exactly **10px or 20px** padding between all visuals. Use the "Align" and "Distribute" tools in the Format ribbon; never eyeball it.

### 📦 Phase 14 Deliverables

1. **✅ Polished PBI Project:** A `.pbip` file with a renamed Selection Pane and grouped elements.
2. **✅ Mobile View:** A verified, scrollable mobile layout.
3. **✅ QA Checklist:** A signed-off list confirming Drill-throughs, Slicers, and Tooltips work.
4. **✅ Performance Report:** Screenshot of Performance Analyzer showing fast load times.

### business question to visuals mapping table

###

### 4) Power BI Service(done)

### ☁️ Phase 15: Power BI Service Deployment

> Goal: Deploy the polished report to a managed cloud environment, secure it with Row Level Security (RLS), and distribute it via an "App" rather than raw workspace access.

### **✔ 15.1 Workspace Architecture**

- [ ] [ ] **Create Production Workspace**
  - **Naming Standard:** Create a new workspace named `[Project Name] - PROD` (e.g., `Sales Analytics - PROD`).
  - **Constraint:** Never use "My Workspace" for portfolio or production work.
- [ ] [ ] **Assign Workspace Roles (RBAC)**
  - **Admins/Members:** Add yourself (and other developers) here.
  - **Viewers:** Do **not** add end-users here yet (they will access via the App).
- [ ] [ ] **Configure Support Contact**
  - **Action:** Workspace Settings > Contact List. Add your email so error messages direct to you.

### **✔ 15.2 Publishing & Connectivity**

- [ ] [ ] **Publish Report**
  - **Action:** In Power BI Desktop > Publish > Select `[Project Name] - PROD`.
- [ ] [ ] **Configure Data Gateway (If DirectQuery/On-Prem)**
  - **Check:** Ensure Standard Gateway is "Online" in "Manage Connections and Gateways".
  - **Mapping:** Map the published dataset to the correct Gateway data source.
- [ ] [ ] **Update Cloud Credentials (Import Mode)**
  - **Action:** Dataset Settings > Data Source Credentials.
  - **Auth:** Set to **OAuth2** (for Snowflake) and sign in.
- [ ] [ ] **Schedule Refresh**
  - **Timing:** Set to run *after* your dbt Cloud job finishes (e.g., if dbt finishes at 6:00 AM, set PBI to 6:30 AM).
  - **Notifications:** Check "Send refresh failure notification to dataset owner".

### **✔ 15.3 Security & Governance**

- [ ] [ ] **Assign RLS Members**
  - **Action:** Dataset > Security > Row-Level Security.
  - **Task:** Add specific emails or Security Groups to the `DynamicAccess` role you created in Phase 12.
- [ ] [ ] **Test RLS (Cloud Verification)**
  - **Action:** Click ellipsis (...) next to role > "Test as role".
  - **Validation:** Confirm you see data filtered as that user.
- [ ] [ ] **Endorsement (Trust Signal)**
  - **Action:** Dataset Settings > Endorsement.
  - **Selection:** Set to **Promoted** (Ready for broad usage) or **Certified** (Official Golden Dataset).

### **✔ 15.4 Distribution (The App Method)**

- [ ] [ ] **Configure the App**
  - **Action:** Click "Create App" (or "Update App") in the Workspace.
  - **Description:** Add a clear description and a support link.
- [ ] [ ] **Configure Navigation**
  - **Action:** Hide any "Validation" or "Draft" reports from the navigation pane.
  - **Structure:** Group reports into Sections if you have multiple reports.
- [ ] [ ] **Manage Audiences (Advanced View)**
  - **Scenario:** If you have an "Executive Summary" page and a "Deep Dive" page.
  - **Action:** Create an `Exec Audience` (sees only summary) and `Analyst Audience` (sees everything).
  - **Access:** Assign users/groups to specific Audiences.
- [ ] [ ] **Publish App**
  - **Action:** Click "Publish App" and copy the link.

### **✔ 15.5 Automation & Monitoring**

- [ ] [ ] **Configure Subscriptions**
  - **Action:** Subscribe yourself to the "Executive Summary" page (Email: Daily at 8 AM).
  - **Purpose:** Acts as a daily "Smoke Test"—if you get the email, the system is working.
- [ ] [ ] **Set Data Alerts (Dashboard Only)**
  - **Action:** Pin a KPI card to a Dashboard.
  - **Trigger:** Set alert rule: "If Revenue drops below $X, email me."
- [ ] [ ] **Review Usage Metrics**
  - **Action:** Open Usage Metrics Report.
  - **Check:** Monitor "Views per day" and "Views per user" to see adoption.

---

### 🌟 Phase 15 Best Practices

- **App > Workspace:**
  - **Rule:** Never share a report by clicking the "Share" button on the report itself.
  - **Why:** Managing 100 individual share links is a nightmare. Managing 1 App with 1 Audience is scalable.
  - **Best Practice:** Give users "Viewer" access via the App. Give Developers "Member" access via the Workspace.
- **Gateway Cluster:**
  - If using an On-Premise Gateway, ensure you have a **Cluster** (2+ gateways). If one machine updates/restarts, the other handles the refresh.
- **Parameterize Connections:**
  - In Power BI Desktop (Power Query), use **Parameters** for Server/Warehouse names.
  - *Benefit:* You can change the connection from `DEV` to `PROD` inside the Power BI Service settings without re-publishing the PBIX file.
- **Deployment Pipelines (Premium Feature):**
  - If you have a Premium/Fabric capacity, use **Deployment Pipelines** to promote content from `Dev Workspace` -> `Test Workspace` -> `Prod Workspace`.

### 📦 Phase 15 Deliverables

1. **✅ Live App Link:** A distinct URL for the published App (not the workspace).
2. **✅ Refresh Log:** Screenshot showing a successful scheduled refresh history.
3. **✅ RLS Validation:** Screenshot of the "Test as Role" screen proving security works.
4. **✅ Subscription Email:** Proof that the automated report delivery system is active.

### 5) Optimization and Best Practices(done)

### ⚡ Quick Optimization Checklist

- **Data Model Optimization:**
  - Remove unused columns and tables from the model
  - Disable auto date/time hierarchy in Power BI settings
  - Replace calculated columns with measures where possible
  - Use appropriate data types (integers instead of text for IDs)
- **DAX Performance:**
  - Avoid using CALCULATE unnecessarily
  - Use variables (VAR) to store repeated calculations
  - Replace ALL() with ALLSELECTED() when appropriate
  - Avoid using iterators (SUMX, FILTER) on large tables
- **Visual Optimization:**
  - Limit visuals per page to 5-7 maximum
  - Use aggregated tables for large datasets
  - Run Performance Analyzer to identify slow visuals
  - Remove excessive formatting and custom themes

This is the final layer of polish. You have a solid process; now let's add the "Senior Engineer" optimizations that make your project scalable, faster, and team-ready.

Here is the **Optimization & Git Strategy Guide** specifically for your Power BI workflow.

---

### 🚀 Power BI Performance Optimization Strategy

### **1. Data Model Optimization (The Engine)**

- **Vertical Partitioning (Remove Columns):** Run **DAX Studio** -> "VertiPaq Analyzer". Look at the "Col Size" column. If a high-cardinality column (like a unique Transaction ID or UUID) takes up 50% of your model size but isn't used for counting, **remove it** in Power Query.
- **Aggregations (The Speed Layer):** If your `fct_orders` has 100 million rows, create a smaller `agg_sales_by_month`table in Snowflake/dbt. Configure Power BI to use this smaller table for high-level visuals and only query the big table when users drill down.
- **Disable Auto Date/Time:** **Mandatory.** This reduces file size by preventing Power BI from creating hidden date tables for every datetime column.

### **2. Power Query Optimization (The ETL)**

- **Query Folding:** In Power Query, right-click your last step -> "View Native Query". If it's greyed out, you broke folding (meaning Power BI is downloading raw data to filter it locally).
  - *Fix:* Move filters and column removals to the *top* of the steps list.
- **Avoid "Merge Queries" in Power Query:** Do joins in **dbt/Snowflake**. Power Query merges are CPU intensive and slow down refresh times.

### **3. DAX Optimization (The Calc)**

- **Variables (`VAR`) are Mandatory:**
  - *Bad:* `IF(SUM(Sales) > 100, SUM(Sales) * 0.1, SUM(Sales) * 0.05)` -> Calculates `SUM(Sales)` 3 times.
  - *Good:*Code snippet
    `VAR _Sales = SUM(Sales)
RETURN IF(_Sales > 100, _Sales * 0.1, _Sales * 0.05)`
- **Strict Boolean Logic:** Avoid `FILTER(Table, Column = Value)`. Use `KEEPFILTERS` or `CALCULATE(..., Column = Value)` to leverage the storage engine (faster) instead of the formula engine (slower).

### **4. Visual Rendering Optimization (The UX)**

- **Limit Visuals:** Max **8 visuals** per page. Each visual sends a separate query to the engine.
- **Reduce Slicer Interaction:** Go to **Format > Edit Interactions**. Turn **OFF** filtering for visuals that don't need it (e.g., a "Year" slicer shouldn't try to filter a static "Company Logo" or a text box).

---

### 🐙 Git & GitHub Strategy for Power BI

Power BI binary files (`.pbix`) are notoriously hard to version control. The game changed with **Power BI Projects (`.pbip`)**. Here is your workflow:

### **Step 1: Save as Project (.pbip)**

- **Action:** File -> Save As -> Browse -> Select type **"Power BI Project files (\*.pbip)"**.
- **Result:** This creates a folder structure:
  - `Project.Report/` (Visuals, layout - JSON format)
  - `Project.Dataset/` (Model, DAX - TOM format)

### **Step 2: Configure `.gitignore`**

Add these specific lines to your repo's `.gitignore` file to avoid committing local cache data:

Plaintext

`# Power BI exclusions
*.pbix
.DS_Store
*.abf
*.pbiq
localSettings.json
cache.abf`

### **Step 3: Branching Strategy**

- **Main Branch:** The "Golden" production version.
- **Feature Branch:** Create a branch for specific tasks (e.g., `feature/add-finance-dashboard`).
  - *Command:* `git checkout -b feature/add-finance-dashboard`

### **Step 4: The Commit Workflow**

1. **Work:** Open the `.pbip` file, make changes (e.g., add a measure), and save.
2. **Stage:** `git add .`
   - *Note:* Git will detect text changes in the `model.bim` file (e.g., `"name": "Total Revenue"`).
3. **Commit:** `git commit -m "feat: added Total Revenue measure"`
4. **Push:** `git push origin feature/add-finance-dashboard`

### **Step 5: Pull Requests (PR)**

- **Action:** Open a PR in GitHub.
- **Review:** You can now see *code diffs*!
  - *Example:* You will see `+ Measure: SUM(Sales)` in green. This allows you to code-review DAX without opening the file.

---

### 🛠️ Final "Project polish" Checklist (The Portfolio Finisher)

Add this to the very bottom of your Notion. It’s the "Definition of Done."

- [ ] **The "Blink Test":** Look at your dashboard for 3 seconds. Can you answer "Is business good or bad?" immediately? If not, your KPIs are unclear.
- [ ] **The Color Blind Test:** Use a simulator (like "Coblis") to ensure your Red/Green indicators are distinguishable by color-blind users (add icons/arrows to be safe).
- [ ] **Tooltip Cleanup:** Hover over *every* chart. Did you leave a "Count of ID" or weird internal column name visible in the tooltip? Hide them.
- [ ] **Empty State Check:** Filter the report to a date/region with zero data. Does it look broken? Add a "No Data Available" text box that appears when the row count is 0.

### 🚀 Next Step

You now have a complete, end-to-end Enterprise Data Roadmap.

Would you like me to generate a Standard Readme.md template for your GitHub repository that summarizes this entire architecture so recruiters can understand your project at a glance?

- **Incremental Refresh:**
  - Set up incremental refresh for large fact tables
  - Keep only necessary historical data (e.g., last 2-3 years)
  - Archive older data to reduce model size
- **Best Practice Analyzer:**
  - Install and run Tabular Editor's Best Practice Analyzer
  - Fix all critical and warning issues
  - Document exceptions if you can't fix certain warnings
- **Compression Tips:**
  - Remove high-cardinality text columns
  - Split date-time columns into separate date and time columns
  - Use numeric keys instead of text keys for relationships
- **Monitoring:**
  - Check .pbix file size (should be under 250 MB ideally)
  - Monitor refresh times (should complete within 30 minutes)
  - Track user report load times via Performance Analyzer

### 🎯 Quick Wins (30-Minute Fixes)

1. Run Performance Analyzer → Identify slowest visual → Simplify or remove it
2. Check Model View → Remove unused columns and tables
3. Power Query → Disable load for staging queries
4. DAX measures → Add VAR to store repeated calculations
5. Visuals → Reduce to maximum 5 per page

### 📊 Performance Targets

- Report load time: Under 3 seconds
- Visual refresh time: Under 1 second per visual
- Data refresh time: Under 10 minutes for typical datasets
- File size: Under 100 MB for optimal performance

###

###

[Deliverables Checklist](https://www.notion.so/Deliverables-Checklist-2cd1bb84f4a48175af1dfe49c77a5067?pvs=21)

# **📊 Phase 6: Analytics, Insights & Business Impact**

### **1) Answer Each Business Question(done)**

### **16.1 The "Q&A" Analysis (Answering Phase 1 Questions)**

- [ ] [ ] **Structure the Answers**
  - **Action:** Create a section in your `REPORT.md` for each of the 5-8 questions defined in Phase 1.
  - **Format:** Use the specific format below for consistency.
- [ ] [ ] **Draft Question 1 (The Headline Number)**
  - **Question:** "What is total sales revenue this year?"
  - **Answer:** "Total sales reached ₹12.3 crore."
  - **Visual Used:** KPI Card (with trend indicator).
  - **What it means:** "Sales grew by 14% compared to last year, indicating strong market recovery."
- [ ] [ ] **Draft Question 2 (The Trend)**
  - **Question:** "Is revenue growing month-over-month?"
  - **Answer:** "Growth is positive but flattening in Q4."
  - **Visual Used:** Line Chart with 3-month rolling average.
  - **What it means:** "While Q1-Q3 were strong, customer demand has plateaued in the last 3 months."
- [ ] [ ] **Draft Remaining Questions**
  - **Action:** Repeat this pattern for all 8 questions. Ensure every answer is backed by a specific visual from your dashboard.

###

### **2) Write Key Insights (Simple, Clean, Beginner Friendly(done)**

### **16.2 Key Insights (The "Why" & "So What?")**

- [ ] [ ] **Draft Insight 1 (The Problem)**
  - **Insight:** "Sales dropped significantly in the South region."
  - **Evidence:** "Bar chart shows a −12% YoY decline specifically in Karnataka and Kerala."
  - **Reason:** "A sharp drop in repeat customer transactions (Retention Rate down 15%)."
  - **Impact:** "The business is projected to lose ₹8–10 lakh per quarter if this trend continues."
  - **Recommendation:** "Improve local delivery times and launch a targeted loyalty discount campaign."
- [ ] [ ] **Draft Insight 2 (The Opportunity)**
  - **Insight:** "The 'Electronics' category is the primary growth driver."
  - **Evidence:** "Tree Map shows Electronics accounts for 60% of total revenue with +22% growth."
  - **Reason:** "High Average Order Value (AOV) combined with low return rates."
  - **Impact:** "Focusing here maximizes profit margin."
  - **Recommendation:** "Increase inventory stock for top-selling electronic SKUs before the holiday season."

###

### **3) Show Before/After of Your Business Impact of my Data Work (done)**

As a beginner data analyst, you MUST show business value from data project work

**✔ 16.4 Business Impact Analysis (Before vs. After)**

- [ ] [ ] **Quantify Your Value (The "Money Slide")**
  - **Action:** Create a table or section highlighting the operational improvements your project delivered.
- [ ] [ ] **Draft the Comparison Table**
  - **Feature:** **Data Refresh**
    - *Before (Problem):* "Reports were manually updated weekly using Excel exports. Stakeholders waited 3-5 days for data."
    - *After (Solution):* "Automated ELT pipeline (Snowflake + dbt) refreshes data daily without human intervention."
    - *Business Impact:* "Reduced time-to-insight by 90%. Stakeholders now make decisions on *yesterday's*data, not last week's."
  - **Feature:** **Ad-hoc Analysis**
    - *Before (Problem):* "Answering a new question (e.g., 'Sales by City') required a new manual data pull (4-6 hours)."
    - *After (Solution):* "Clean, trusted Star Schema in Power BI allows ad-hoc questions to be answered in seconds via drag-and-drop."
    - *Business Impact:* "Saved ~20 hours of analyst time per week, freeing up resources for strategic planning."
  - **Feature:** **Data Quality**
    - *Before (Problem):* "Metrics often mismatched between departments due to siloed spreadsheets."
    - *After (Solution):* "Implemented a 'Single Source of Truth' via dbt Marts and Semantic Layer."
    - *Business Impact:* "Eliminated metric discrepancies, building 100% trust in the executive dashboard."

Example:

| **Feature**         | **Before (The Problem) ❌**                                                                               | **After (Your Solution) ✅**                                                                                | **Business Impact 📈**                                                                                      |
| ------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Data Refresh**    | Reports were manually updated weekly using Excel/CSV exports. Stakeholders waited days for data.          | Automated **ELT pipeline**(Snowflake + dbt) refreshes data daily/hourly without human intervention.         | **Reduced time-to-insight by 90%**. Stakeholders now make decisions on *yesterday's* data, not last week's. |
| **Ad-hoc Analysis** | Answering a new question (e.g., "Sales by City") required a new manual data pull and cleanup (4-6 hours). | Clean, trusted **Star Schema** in Snowflake allows ad-hoc questions to be answered in minutes via Power BI. | **Saved ~20 hours of analyst time per week**, freeing up resources for strategic analysis.                  |

This shows you have **real data analyst skills**.

Simple language but powerful impact.

### **4) Write Business Recommendations (Simple, Clear)(done)**

### **✔ 16.3 Strategic Recommendations (Action Plan)**

- [ ] [ ] **List 5-7 Clear Actions**
  - **Action:** Create a bulleted list of simple, direct recommendations.
  - **Examples:**
    1. "Focus marketing spend on high-value corporate customers in the North."
    2. "Investigate supply chain delays in the South region immediately."
    3. "Increase discounts on 'Accessories' to clear stagnant inventory."
    4. "Implement a post-purchase email sequence to improve retention."
    5. "Discontinue low-margin products with high return rates."

### **5) Write an Executive Summary (Short Paragraph)(done)**

One paragraph telling the story.

### **✔ 16.5 The Executive Summary (The Narrative)**

- [ ] [ ] **Write the Final Paragraph**
  - **Action:** Combine the biggest win and the biggest risk into a short story.
  - **Example:**
    > "Sales grew by 14% this year, driven largely by strong performance in Electronics and high retention among corporate clients. However, the South region is significantly underperforming due to delivery delays, causing an estimated ₹8–10 lakh loss per quarter. By improving delivery SLAs in the South and doubling down on high-margin Electronic inventory, the business could increase overall revenue by an additional 12–15% next year."

This is beginner-friendly but very professional.

### 6) Deliverables and Best Practices(done)

### 🌟 Phase 16 Best Practices

- **Simplicity Wins:** Use simple words. "We lost money" is better than "We experienced a negative fiscal trajectory."
- **Evidence is King:** Never make a claim without pointing to a specific chart or number (Evidence).
- **Focus on "Outcome," not "Output":**
  - *Output:* "I built a dashboard."
  - *Outcome:* "I saved the team 20 hours a week." -> **This gets you hired.**

### 📦 Phase 16 Deliverables

1. **✅ `REPORT.md`:** A polished markdown file in your GitHub repo containing all the above sections.
2. **✅ Impact Table:** The "Before/After" comparison clearly visible in your README.
3. **✅ Recommendations List:** 5-7 clear, actionable steps for the business.
4. **✅ Executive Summary:** A strong opening paragraph that summarizes the entire project.

# **🔄 Phase 7: Monitoring, Optimization & Governance**

> Goal: Quantify performance improvements, document the project's evolution (V1 vs V2), and package all assets into a "Hired-Ready" GitHub repository.

### **Performance Engineering Audit**

- **Goal:** Prove you understand cost and speed.
- [ ] [ ] **Snowflake Cost Optimization**
  - **Action:** Configure `AUTO_SUSPEND = 60` (seconds) on all Warehouses.
  - **Action:** Verify `TRANSFORM_WH` is set to `X-SMALL`.
  - **Action:** Run a query to calculate credits saved: `(Old Runtime - New Runtime) * Cost`.
- [ ] [ ] **dbt Model Optimization**
  - **Action:** Verify `incremental` materialization is active on Fact tables.
  - **Action:** Remove any unused "Intermediate" models that are materialized as Tables (switch to Ephemeral).
  - **Action:** Add Clustering Keys (Snowflake) on large tables if filtering by Date.
- [ ] [ ] **Power BI Performance Tuning**
  - **Action:** Run **Performance Analyzer** in Desktop. Ensure no visual > 1000ms.
  - **Action:** Run **DAX Studio (VertiPaq Analyzer)**. Identify and remove high-cardinality columns (e.g., GUIDs) not used in visuals to reduce file size.
- [ ] [ ] **Create `PERFORMANCE.md`**
  - **Action:** Create a Markdown file in your repo.
  - **Content:** Create the "Before vs After" table (Query Time, Credits, PBIX Size).

### **Pipeline Health & Automation**

- **Goal:** Show you built a robust system, not a fragile script.
- [ ] [ ] **Configure Alerts**
  - **Action:** In dbt Cloud (or GitHub Actions), configure Email/Slack notifications on "Run Failure."
- [ ] [ ] **Implement Freshness Checks**
  - **Action:** Ensure `dbt source freshness` runs *before* `dbt build` in your Production Job.
  - **Why:** If the raw data is stale, don't waste money running the pipeline.
- [ ] [ ] **Create the "Runbook"**
  - **Action:** Create `docs/runbook.md`.
  - **Content:** "If the pipeline fails at step X, check Y." (e.g., "If source freshness fails, check Azure Blob permissions").

### Incident Response

**⚠️ Operational Context:** While this portfolio project utilizes a static dataset (historical snapshot), I have designed the pipeline to handle **Real-World Enterprise Constraints**.

I have manually **simulated** the following failure scenarios to verify that my `dbt tests`, `Schema Hardening`, and `Freshness Checks`function correctly in a live production environment.

> Goal: This section defines the standard operating procedures (SOPs) for when the pipeline breaks.

### **Scenario C: Critical Data Loss (The "Fat Finger" Incident)**

- [ ] **Create SQL Artifact:** Save the script used for this drill in `snowflake/04_maintenance/dr_time_travel_demo.sql`.
- [ ] 📸 4. The Visual Proof (For your ReadMe)

Take **one screenshot** of your Snowflake History showing the `DROP` command followed by the `UNDROP` command.

- **Caption:** *"Demonstrating Snowflake Time Travel to recover a dropped table in under 2 minutes."*

[🛡️ Disaster Recovery Drill: Table Restoration](https://www.notion.so/Disaster-Recovery-Drill-Table-Restoration-2cd1bb84f4a4814c908add48bb642716?pvs=21)

- **What it is:** A developer or admin accidentally executes a destructive command like `DROP TABLE` or `DELETE FROM`on a production table (e.g., `dim_customers`) during a hot-fix or maintenance window.
- **The Risk:** Immediate outage of all downstream dashboards. Users see "Visual has an error." If backups aren't immediate, this causes significant business downtime and potential permanent data loss.
- **Defense Strategy:**
  - **Snowflake Time Travel:** Configure `DATA_RETENTION_TIME_IN_DAYS = 1` (or more) on all Production Databases. This creates a continuous rolling backup of the state of the data.
  - **Fail-Safe:** An additional 7-day backup layer provided by Snowflake (non-configurable) as a last resort.
- **Fix Protocol:**
  1. **Acknowledge the Outage:** Confirm the table is missing via `SHOW TABLES`.
  2. **Identify the Drop:** Check `QUERY_HISTORY` to find the timestamp or Query ID of the `DROP` command.
  3. **Execute Recovery:** Run the `UNDROP TABLE [table_name]` command immediately. This restores the table structure, data, and metadata to the exact state before the drop.
  4. **Validate:** Run a `SELECT COUNT(*)` to confirm row counts match the pre-incident baseline.
     **🧪 How I Simulated This:**
  - *Action:* I explicitly ran a `DROP TABLE` command on my populated `dim_customers` table in the Dev environment.
  - *Result:* I executed `UNDROP TABLE dim_customers` and verified via a screenshot that the table reappeared instantly with zero data loss.
    If you want to look even more senior, show how you fix a **Bad Update** (not just a Drop).
    [**Scenario E: Logical Corruption (The "Bad Update")**](https://www.notion.so/Scenario-E-Logical-Corruption-The-Bad-Update-2cd1bb84f4a481b69a84c1e44d94e92a?pvs=21)

### **Scenario A: Schema Drift (The "Silent Killer")**

- **What it is:** The source system (e.g., the app database or API) changes without warning. A column might be renamed (e.g., `user_id` becomes `cust_id`), a data type might change (String to Integer), or a column might be deleted entirely.
- **The Risk:** If not caught, this can break your SQL transformation logic or, worse, feed empty `NULL` values into the CEO's dashboard.
- **Defense Strategy:**
  - **Upstream (dbt):** Use **Data Contracts** to strictly define what the data *must* look like. If it doesn't match, the pipeline stops immediately.
  - **Downstream (Power BI):** Use `Table.SelectColumns` in Power Query to "harden" the schema. If a column is missing, the refresh fails loudly instead of showing a broken chart.
- **Fix Protocol:**
  1. **Identify the Change:** Look at the error log. (e.g., *"Column 'user_id' not found"*).
  2. **Update Staging:** open your `stg_` model in dbt. Rename the new source column to your standard name (e.g., `cust_id as user_id`).
  3. **Update Contract:** Edit your `schema.yml` to reflect the new reality if the data type changed.
  4. **Full Refresh:** Run `dbt run --full-refresh` to rebuild the table history with the new structure.
     **🧪 How I Simulated This:**
  - *Action:* I intentionally renamed a column in my local CSV and ran `dbt run`.
  - *Result:* Confirmed that dbt threw a specific compilation error, validating the guardrails.

### **Scenario B: Source Freshness Failure (The "Stale Data" Bug)**

- **What it is:** The data pipeline ran successfully, but the data inside it is old. For example, it's Tuesday, but the dashboard still shows Sunday's data.
- **The Risk:** Stakeholders make decisions based on outdated information.
- **The Trigger:** Your `dbt source freshness` check fails because the `_loaded_at` timestamp is older than your threshold (e.g., > 24 hours).
- **Fix Protocol:**
  1. **Check the Source:** Log into your Azure Blob Storage container. Look at the "Last Modified" date of the CSV files.
  2. **Diagnosis:**
     - *If Azure is empty/old:* The issue is with the **Extraction Script** (Python) or the API source itself. You need to re-run the extraction job.
     - *If Azure has new data:* The issue is with **Snowflake Ingestion**. Check if your `COPY INTO` command failed or if permissions (SAS Token) expired.
  3. **Resolution:** Manually trigger the extraction script or refresh the Snowflake pipe, then re-run the dbt pipeline.

### **Scenario C: Data Quality Breach (The "Duplicate" Bug)**

- **What it is:** A business rule was violated. The most common one is **Duplication**—a Primary Key that should be unique (like `order_id`) appears twice.
- **The Risk:** Revenue numbers are double-counted, leading to inflated reporting.
- **The Trigger:** A `dbt test` fails (specifically the `unique` or `not_null` test).
- **Fix Protocol:**

  1.  **Audit the Data:** Run a SQL query to see the bad rows:SQL

           `SELECT order_id, COUNT(*)

      FROM fct_orders
      GROUP BY 1
      HAVING COUNT(\*) > 1;`

  2.  **Determine Cause:**

      - *Is it a Bug?* Did the ingestion job run twice by accident? -> **Fix:** Delete the bad rows in the Raw layer and re-load.
      - *Is it Real Life?* Did the order actually have two status updates? -> **Fix:** Update your **Intermediate** logic to handle this. Use a window function (`QUALIFY ROW_NUMBER()`) to select only the latest version of that order.

      **🧪 How I Simulated This:**

      - *Action:* I manually duplicated 5 rows in the source file `orders.csv`.
      - *Result:* `dbt test` failed as expected. I then implemented `QUALIFY ROW_NUMBER()` in my model to automatically handle future duplicates.

### **Scenario D: Cost or Volume Spike (The "Wallet" Risk)**

- **What it is:** A query runs for way too long, or you accidentally process 100x more data than usual (e.g., re-processing the last 5 years instead of just today).
- **The Risk:** You burn through your Snowflake free credits or get a massive cloud bill.
- **The Trigger:** A Snowflake **Resource Monitor** sends an alert (e.g., "90% of monthly budget used").
- **Fix Protocol:**
  1. **Stop the Bleeding:** Immediately go to Snowflake "Query History" and kill any queries running longer than 10-15 minutes.
  2. **Investigate:** Look for **Cartesian Joins** (a join without a proper key) in recent code changes. This causes row counts to explode (e.g., 1,000 rows x 1,000 rows = 1 million rows).
  3. **Remediate:** Revert the bad code change. If the table is simply too big, ensure your **Incremental Logic** is working correctly so you are only processing *new* rows.
  ### **Scenario E: The "Access Denied" (Credential Expiry)**
  - **What it is:** The pipeline suddenly fails with `403 Forbidden` or `Authentication Error`.
  - **The Root Cause:** Secrets don't last forever. Your **Azure SAS Token** expired (usually set to 6-12 months) or your **Snowflake Service User** password rotated.
  - **The Trigger:** Ingestion step fails immediately.
  - **Fix Protocol:**
    1. **Identify the Key:** Check the error log. If it says `Azure`, it's the SAS Token. If `Snowflake`, it's the user password.
    2. **Rotate Secret:** Generate a new SAS Token in Azure Portal or reset the Snowflake password.
    3. **Update Repo:** Update the `GitHub Secrets` (e.g., `AZURE_SAS_TOKEN`) or your `.env` file.
    4. **Re-Run:** Restart the pipeline.
  ### **Scenario F: The "Infinite Loop" (Pipeline Timeout)**
  - **What it is:** The job doesn't fail, but it hangs forever (or hits the 2-hour timeout limit).
  - **The Root Cause:** A "Table Lock" in Snowflake (another process is updating the table) or a bad join creating billions of rows (Cartesian product) slowly.
  - **The Trigger:** GitHub Actions / dbt Cloud reports `Timeout Exceeded`.
  - **Fix Protocol:**
    1. **Kill the Lock:** Run `SHOW TRANSACTIONS` in Snowflake and abort any hanging transactions preventing the update.
    2. **Scale Up:** If it's just a heavy data day (End of Month), temporarily increase the Warehouse size (`ALTER WAREHOUSE ... SET WAREHOUSE_SIZE = 'SMALL'`).
    3. **Investigate:** Check Query Profile for "Spilling to Disk" (means not enough RAM).
  ### **Scenario G: The "Last Mile" Break (Power BI Refresh Failure)**
  - **What it is:** The data in Snowflake is perfect, but the Dashboard shows an error triangle.
  - **The Root Cause:**
    - **Memory Limit:** You exceeded the 1GB limit (Pro License).
    - **Data Type Mismatch:** Snowflake sent a "Text" column that Power BI expected as "Date".
  - **The Trigger:** You get a "Refresh Failed" email from Power BI Service.
  - **Fix Protocol:**
    1. **Check Service Logs:** Click the warning icon in the Workspace history.
    2. **If Memory Limit:** Run **VertiPaq Analyzer** (DAX Studio) and drop unused columns.
    3. **If Type Mismatch:** Update the Power Query "Schema Hardening" step to explicitly cast the column types again.
  ### **Scenario H: The "Bad Merge" (Logic Regression)**
  - **What it is:** The code runs fine, tests pass, but the numbers are *wrong* (e.g., Profit is negative).
  - **The Root Cause:** A developer changed a `LEFT JOIN` to an `INNER JOIN` and accidentally dropped 10% of records.
  - **The Trigger:** A stakeholder emails you: "Why are sales down 10%?"
  - **Fix Protocol (The Rollback):**
    1. **Verify:** Run a quick SQL check comparing `Row Count Yesterday` vs `Row Count Today`.
    2. **Revert:** Immediately revert the last Git Pull Request (`git revert HEAD`).
    3. **Deploy:** Push the revert to Production to restore the dashboard logic.
    4. **Post-Mortem:** Add a new `dbt test` (e.g., `dbt_expectations.expect_table_row_count_to_be_between`) to catch this drop next time.
  ***
  **✔ Create the Artifact**
  - [ ] [ ] **Write `docs/RUNBOOK.md`**
    - *Action:* Create a markdown file in your repo.
    - *Content:* Copy the scenarios above into tables. Add a "Contact Info" section (your email) acting as the "On-Call Engineer."
      **✔ The "Post-Mortem" Template**
  - [ ] [ ] **Create an Incident Log**
    - *Action:* Add a section in your Notion or Repo to log *actual* bugs you faced while building.
    - *Format:* `[Date] | [Error] | [Root Cause] | [Fix]`.
    - *Why:* This is your "Cheat Sheet" for interview questions about challenges you faced.
  ### 📝 Summary Checklist for Your Notion

| **Scenario**       | **Layer**      | **Primary Fix**                  |
| ------------------ | -------------- | -------------------------------- |
| **Schema Drift**   | Ingestion      | Update Staging Model + Contracts |
| **Stale Data**     | Source         | Check Azure File Dates           |
| **Quality Breach** | Transformation | Fix Logic or Delete Bad Rows     |
| **Cost Spike**     | Warehouse      | Kill Query + Fix Join            |
| **Auth Failure**   | Security       | Rotate SAS Token/Password        |
| **Timeout**        | Compute        | Kill Locks or Scale Warehouse    |
| **PBI Refresh**    | Visualization  | Optimize Model Size (VertiPaq)   |
| **Bad Logic**      | Code           | Git Revert + Add New Test        |

### The Product Evolution (Showing Iteration)

- **Goal:** Show you listen to users and iterate.
- [ ] [ ] **Document the Roadmap**
  - **Action:** In `README.md`, add a section "Project Evolution."
  - **Log:**
    - *v1.0:* MVP Data Pipeline & Basic Sales Report.
    - *v1.1:* Added "Drill-through" features based on stakeholder feedback.
    - *v2.0:* Implemented Incremental Refresh & RLS for security.
- [ ] [ ] **List "Future Improvements"**
  - **Action:** Add a "Next Steps" section.
  - **Ideas:** "Implement Snowflake Streams for real-time data," "Add Python/Snowpark for Churn Prediction."

### **Final Repository Structure & Documentation**

- **Goal:** Make the repo clean, scannable, and professional.
- [ ] [ ] **Finalize Folder Structure**
  - Ensure root is clean. Move helper files to `/docs` or `/scripts`.
  - Structure:Plaintext
    ```jsx
    ├── dbt_project/          # The Transformation Logic
    ├── power_bi/             # The .pbip Project
    ├── docs/                 # Requirements, Runbook, Diagrams
    ├── scripts/              # Python seed generators
    ├── .github/              # CI/CD Workflows
    ├── README.md             # The Landing Page
    ├── REPORT.md             # The Business Analysis
    └── PERFORMANCE.md        # The Optimization Logs
    ```
- [ ] [ ] **Finalize `README.md` (The Most Important File)**
  - **Header:** Project Title, One-line pitch, Tech Stack Badges.
  - **Visual:** Embed the **Architecture Diagram**.
  - **Access:** Link to the hosted dbt Docs site.
  - **Impact:** Include the "Business Value" table (Time Saved, Revenue Opportunity).
- [ ] [ ] **Finalize `REPORT.md`**
  - **Content:** Executive Summary, 3 Key Insights (with screenshots), 3 Recommendations.

### **Portfolio Asset Creation**

- **Goal:** Create "Shareable" content for LinkedIn and Applications.
- [ ] [ ] **Record Demo Video (Loom)**
  - **Length:** 2-3 minutes max.
  - **Script:** Problem -> Architecture -> Demo of Dashboard -> One cool technical challenge you solved (e.g., Incremental logic).
  - **Action:** Add link to the top of README.
- [ ] [ ] **Create "One-Pager" PDF**
  - **Action:** Design a single page summary: "Retail Analytics Pipeline."
  - **Include:** Architecture Image, Dashboard Screenshot, "Results" bullets.
  - **Use:** Attach to job applications.
- [ ] [ ] **GitHub "Release"**
  - **Action:** On GitHub, click "Create a new release". Tag it `v1.0-production`.
  - **Why:** Looks incredibly professional.

### Best Practices and Deliverables

### 🌟 Phase 17 Best Practices

- **Evidence over Claims:** Don't just say "I optimized the query." Show the screenshot of the Query Profile showing the reduction in "Bytes Scanned."
- **The "User" is King:** When describing iterations, always frame it as "User Request" or "Stakeholder Feedback."
  - *Example:* "Users reported the dashboard was slow, so I implemented Aggregation Tables."
- **Clean up your Git History:** If you have 50 commits named "fix", consider doing a "Squash and Merge" when merging your final feature branches to Main to keep the history clean.

### 📦 Phase 17 Deliverables

1. **✅ `PERFORMANCE.md`:** A log of technical optimizations and cost savings.
2. **✅ Clean Repo:** Organized folders, no loose files.
3. **✅ `README.md`:** The perfect landing page with Architecture Diagram embedded.
4. **✅ Demo Video:** A visual walkthrough linked in the README.
5. **✅ `v1.0` Release:** A formal tagged release on GitHub.
6. **Pin the Repo:** Go to your GitHub profile -> "Customize your pins" -> Select this project. It must be #1.
7. **Don't hide the "Ugly":** If you ran into a bug (e.g., "My incremental logic failed on day 3 because of a schema change"), document it in a "Challenges & Lessons Learned" section. This shows resilience.
8. **Visuals First:** In your README, never write a wall of text. Always alternate: Text -> Screenshot -> Text -> Code Snippet.

[Phase 8 Final Summary ](https://www.notion.so/Phase-8-Final-Summary-2cd1bb84f4a48103b35fce51a03eb090?pvs=21)

### 📋 Project Summary and Deliverables

This project delivers a complete, end-to-end modern data analytics solution using **Azure Blob → Snowflake → dbt → Power BI → GitHub**.

**Key Things Produced**

- **Clean, reliable dataset** loaded from Azure Blob into Snowflake
- **Well-structured dbt project** with:
  - Reusable staging, intermediate, and mart models
  - Automated data cleaning
  - Data quality tests (unique, not null, accepted values)
  - Clear lineage showing how raw → final analytics tables are built
- **Reusable data model** (star schema) ready for any analysis
- **Power BI semantic model** with:
  - Standardized KPIs
  - Reusable measures
  - Clean relationships + hierarchies
  - Optimized, easy-to-use model
- **Interactive Power BI Dashboard** including:
  - KPIs
  - Trends
  - Top/bottom analysis
  - Drill-through pages
  - Insights page & recommendations
- **Insights & Business Answers** to real business questions
- **Documented business impact**, such as:
  - Time saved by automating cleaning with dbt
  - Improved data quality
  - Faster reporting with semantic model
- **Fully documented project** in Notion + GitHub
  - Architecture diagram
  - Data model diagram
  - dbt lineage
  - Insights summary
  - README with explanation of each phase
- **Version-controlled code** using Git & GitHub
- **Final monitoring & stability checks** on Snowflake, dbt, Power BI

---

# 🧩 **One-Sentence Portfolio Summary**

> Built a complete analytics pipeline raw files to a production-ready dashboard, including automated dbt transformations, a reusable star schema, and an insight-driven Power BI report.

### Reuseable assets

**1.  Raw data in Azure Blob / Snowflake (ingestion pipelines)**

**2.  Staging models (stg\_\*) in dbt**

**3.  Dimension models (dim_customer, dim_date, dim_product, etc.)**

**4.  Common marts/intermediate models (int_orders, int_sessions, etc.)**

**5.  dbt tests, docs, exposures, sources, macros**

**6.  Semantic layer (dbt metrics or Power BI dataset relationships)**

**7.  Power BI dataset (shared dataset mode)**

**8.  Git repo + branch strategy**

**9.  CI/CD pipelines (dbt Cloud or GitHub Actions)**

**10.  Data contracts & catalog (if using Snowflake tags or Catalog)**
