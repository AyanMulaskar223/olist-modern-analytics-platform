# Architecture Overview – Olist Modern Analytics Platform (ADLC)

This document describes the end-to-end architecture for the Olist Modern Analytics Platform, aligned to the **ADLC (Acquire → Ingest & Land → Store → Process → Analyze & Share → Govern & Operate)** lifecycle. The platform is designed for repeatable, auditable ingestion and transformation of the **Olist public datasets** into **analytics-ready marts** consumed by **Power BI**.

---

## ADLC-Aligned Architecture

### 1) Acquire (Source / Collect)

**Primary sources**
- Olist public datasets (CSV)

**Optional sample formats (for ingestion demos / extensibility)**
- JSON
- Parquet

**Source profiling & checks (recommended)**
- **Schema drift detection**
    - Columns added/removed/renamed
    - Type changes (e.g., numeric → string)
- **File validation**
    - Row-count sanity checks (against prior loads, if available)
    - Header presence and delimiter correctness
    - Encoding (UTF-8 recommended)
    - Null-rate / basic distribution checks for key columns (optional)
- **Change tracking**
    - Source versioning via file name conventions and/or checksum

**Source metadata captured (recommended)**
- Source name, dataset name
- Extraction/created timestamp (if available)
- File name and size
- Checksum (MD5/SHA) for immutability verification
- Ingestion batch/run identifier

---

### 2) Ingest & Land (Landing / Raw)

**Ingestion mode**
- Batch file ingestion (local → **Azure Blob Storage**)
- Optional scheduled ingestion via **GitHub Actions** (cron/manual dispatch)

**Landing design principles**
- **Immutable writes**: never update files in place; write new versions
- **Idempotency**: reruns should not create duplicates (use checksums + run IDs)
- **Traceability**: every file is attributable to a source and a run

**Landing conventions**
- Partitioning by time/run for easy discovery:
    - `source=<source_name>/dataset=<dataset_name>/ingestion_date=YYYY-MM-DD/run_id=<id>/...`
- Store a small **manifest** per run (recommended):
    - list of files ingested
    - validation results summary
    - checksums
    - start/end times and status

---

### 3) Store (Landing Zone / System of Record)

**System of Record**
- **Azure Blob Storage** is the immutable system of record for as-received files.

**Folder zones**
- `/landing/`  
    - As-received, immutable source files organized by source/dataset/run  
- `/archive/`  
    - Historical copies retained for audit/backfills (immutable)  
- `/rejected/`  
    - Files failing validation, with reason codes and validation logs  

**Retention & access (recommended)**
- Define retention per zone (e.g., landing 30–90 days, archive long-term)
- Restrict write permissions to ingestion identities only
- Read access scoped by role (engineering vs. consumers)

---

### 4) Process (Load + Transform)

**Warehouse**
- **Snowflake** is the compute + curated storage layer for analytics.

**Database layering (recommended)**
- `RAW`
    - Ingestion tables mirroring sources as closely as possible
    - Minimal transformations (e.g., add load metadata columns)
    - Append-only (avoid destructive updates)
- `STAGING`
    - Cleaned and typed models
    - Standardized naming, null handling, deduplication, casting
    - Derived columns when necessary (timestamps, normalized keys)
- `MARTS`
    - Analytics-ready dimensional/star schema
    - Conformed dimensions and well-defined fact tables

**dbt Core transformations**
- Standardization
    - naming conventions (snake_case)
    - type casting and parsing (dates, numerics)
    - consistent handling of nulls and blanks
- Conformed dimensions (examples)
    - `dim_customer`, `dim_seller`, `dim_product`, `dim_date`
- Facts (examples)
    - `fact_orders`, `fact_order_items`, `fact_payments`, `fact_deliveries`
- Incremental models (where appropriate)
    - Use stable unique keys + updated_at logic when available
    - Prefer partition-aware strategies for larger facts

**Modeling & engineering standards (recommended)**
- Consistent naming:
    - `stg_<source>__<entity>` for staging models
    - `dim_<entity>` and `fact_<process>` for marts
- Reusable macros for:
    - audit columns (e.g., `loaded_at`, `source_file`, `run_id`)
    - safe casting / parsing
    - deduplication patterns
- Documentation:
    - dbt `schema.yml` descriptions for models and columns
    - dbt lineage and exposure definitions for Power BI datasets
- Environments:
    - `dev` → `staging` → `prod` with isolated schemas/roles

---

### 5) Analyze & Share (Consumption)

**BI tool**
- **Power BI** (.pbip)

**Consumption approach**
- Star-schema-first modeling for performance and clarity
- Power BI semantic model aligned to `MARTS`

**Deliverables**
- Curated semantic model with:
    - standardized KPIs/measures
    - consistent dimension usage (conformed dimensions)
    - clear business-friendly naming and descriptions
- Dashboards and reports built on the semantic layer (not on RAW/STAGING)

**Recommended practices**
- Avoid many-to-many relationships where possible
- Prefer surrogate keys for joins in the semantic model
- Centralize business logic:
    - transformations in dbt
    - measures in Power BI (documented and versioned)

---

### 6) Govern & Operate (Quality, CI/CD, Observability)

**Data quality**
- dbt tests:
    - `not_null`, `unique`, `relationships`
    - `accepted_values` / range checks (where applicable)
- Freshness (where applicable)
    - define acceptable staleness per dataset
- SQLFluff linting
    - consistent style, readability, and maintainability

**CI/CD (GitHub Actions)**
- Pull request validation (recommended)
    - `dbt compile` / `dbt build` (scoped to changes when possible)
    - dbt tests execution + artifact upload
    - SQLFluff linting
- Optional:
    - publish dbt docs as a static site/artifact
    - environment promotion gates (approval for prod)

**Orchestration flow (recommended)**
1. Ingest files → Blob `/landing/`
2. Load to Snowflake → `RAW`
3. Transform → `STAGING`
4. Build marts → `MARTS`
5. Execute tests + freshness checks
6. Publish artifacts (dbt docs, run results, test reports)
7. Refresh Power BI semantic model (if applicable)

**Observability (recommended)**
- Persist artifacts:
    - dbt `run_results.json`, `manifest.json`
    - validation logs and rejected-file reasons
- Alerting:
    - notify on failures (email/Teams/Slack as applicable)
    - include run ID, failing models/tests, and links to logs

**Security & governance (recommended)**
- Snowflake RBAC with least privilege
    - separate roles for ingestion, transformation, consumption
    - environment isolation (`dev/staging/prod`)
- Data classification
    - PII tagging (if PII exists)
    - column-level security / masking policies where required
- Ownership & SLAs
    - named owner per mart
    - defined SLA for freshness and data-quality thresholds
    - documented change management for schema changes
- Auditability
    - end-to-end lineage (source file → RAW → STAGING → MARTS → report)
    - immutable storage and reproducible builds
