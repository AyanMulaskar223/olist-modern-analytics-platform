# 🏗️ System Architecture Overview

![Pattern](https://img.shields.io/badge/Pattern-Modern%20Data%20Stack-EA580C?style=for-the-badge)
![Layers](https://img.shields.io/badge/Layers-RAW%E2%86%92STG%E2%86%92INT%E2%86%92MARTS-059669?style=for-the-badge)
![Quality Gate](https://img.shields.io/badge/Quality%20Gate-559%20CI%20Tests-7C3AED?style=for-the-badge)

!!! warning "Portfolio Scenario — Architecture"
⚠️ Portfolio Scenario: This architecture describes a simulated Digital Transformation implementation for the Olist public dataset. It documents design decisions and controls as production-style patterns for portfolio demonstration.

---

!!! abstract "Scope"
This file defines the **system architecture** and key engineering decisions.

!!! tip "Single Source of Truth (SSOT) Rule"
Definitions live once, then referenced:

    - Business definitions and KPI rules: [00_business_requirements.md](00_business_requirements.md)
    - Column-level semantics: [02_data_dictionary.md](02_data_dictionary.md)
    - Data quality framework and controls: [03_data_quality.md](03_data_quality.md)
    - Semantic model design and DAX standards: [04_semantic_model.md](04_semantic_model.md)
    - Engineering standards and DataOps controls: [06_engineering_standards.md](06_engineering_standards.md)

---

## 1. Architecture at a Glance

**System Pattern:** Modern Data Stack (Azure Blob → Snowflake → dbt → Power BI).

**Objective:** Provide a trustworthy, low-latency analytics platform with reproducible transformations, explicit quality gates, and governed semantic consumption.

![Modern Data Stack Architecture](architecture/architecture_hero.png){.architecture-preview-image}

### Evidence

### System Lineage (DAG)

![dbt Lineage DAG](screenshots/03_dbt/lineage_dag.png)

- Snowflake schema separation: [database.png](screenshots/02_snowflake/database.png)
- Semantic model implementation: [semantic_model.png](screenshots/04_powerbi/semantic_model.png)

---

## 2. Decision Log (Senior Format)

| Decision                                  | Rationale                                                                 | Trade-off                                                      | Evidence                                                                                                |
| :---------------------------------------- | :------------------------------------------------------------------------ | :------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------ |
| **Warehouse: Snowflake**                  | Separated compute/storage, zero-copy cloning, strong dbt adapter maturity | Cost discipline required via warehouse sizing and auto-suspend | [warehouse.png](screenshots/02_snowflake/warehouse.png)                                                 |
| **Modeling Pattern: Kimball Star Schema** | Faster BI queries, clear fact grain, reusable conformed dimensions        | More modeling upfront than wide flat-table approach            | [marts_data_model.png](architecture/marts_data_model.png)                                               |
| **Transform Engine: dbt Core**            | SQL-first workflows, test-native framework, lineage auto-generation       | Requires strict naming/testing discipline                      | [test_passed_suite.png](screenshots/03_dbt/test_passed_suite.png)                                       |
| **Consumption Mode: Power BI Import**     | Sub-2s dashboard interactions, predictable user experience                | Scheduled freshness vs real-time DirectQuery                   | [performance_analyzer_excutive_page.png](screenshots/04_powerbi/performance_analyzer_excutive_page.png) |
| **Quality Policy: Blocking CI gates**     | Prevents bad models/metrics from reaching reports                         | Slower merges when tests fail                                  | [github_pr_checks_pass.png](screenshots/05_dataops/github_pr_checks_pass.png)                           |

---

## 3. End-to-End Flow (Concise)

**Data Flow:** Azure Blob → Snowflake RAW → dbt STAGING/INTERMEDIATE/MARTS → Power BI Semantic Model.

### Flow Controls

- **Ingestion control:** idempotent load pattern into RAW (`FORCE = FALSE` policy in ingestion scripts).
- **Transformation control:** model dependencies enforced by dbt `ref()` lineage.
- **Quality control:** 559 blocking tests in CI (`dbt build --target dev/prod`).
- **Consumption control:** semantic model connects to MARTS only (no RAW/STAGING exposure).

!!! success "Quality Gate"
**559 automated tests** execute as blocking checks in CI. Failed tests block promotion.

---

## 4. Layer Responsibilities (No Repetition)

For detailed naming, columns, and business definitions, use linked SSOT docs. This section only states architectural ownership and contracts.

### 4.1 RAW Layer

- **Materialization:** Transient tables
- **Contract:** Immutable landing zone + audit columns
- **Owner:** Loader role
- **Purpose:** Preserve source fidelity for replay/audit

Evidence: [row_count.png](screenshots/02_snowflake/row_count.png)

### 4.2 STAGING Layer

- **Materialization:** Views
- **Contract:** Type casting, standardization, no business joins
- **Owner:** Analytics role
- **Purpose:** Stable technical interface to source data

Reference details: [02_data_dictionary.md](02_data_dictionary.md)

### 4.3 INTERMEDIATE Layer

- **Materialization:** Ephemeral models
- **Contract:** Business transformations and reusable joins
- **Owner:** Analytics role
- **Purpose:** Reusable business logic before mart serving

Reference details: [06_engineering_standards.md](06_engineering_standards.md)

### 4.4 MARTS Layer

- **Materialization:** Tables + incremental facts
- **Contract:** Star schema optimized for BI
- **Owner:** Analytics role (write), reporter role (read)
- **Purpose:** Trusted analytical interface

Evidence: [semantic_model.png](screenshots/04_powerbi/semantic_model.png)

---

## 5. Problem → Fix → Impact (Scan-Friendly)

### 5.1 Dashboard Latency

- **Problem:** Report interactions exceeded acceptable UX thresholds.
- **Fix:** Import mode + star schema + incremental refresh policy.
- **Impact:** Dashboard interactions reduced to sub-2s target range.
- **Evidence:** [incremental_refresh.png](screenshots/04_powerbi/incremental_refresh.png), [performance_analyzer_excutive_page.png](screenshots/04_powerbi/performance_analyzer_excutive_page.png)

### 5.2 Metric Inconsistency Across Stakeholders

- **Problem:** Different report logic produced inconsistent KPI values.
- **Fix:** Business logic centralized in dbt marts and semantic measures.
- **Impact:** Revenue and core KPI definitions aligned through one governed model.
- **Reference:** [00_business_requirements.md](00_business_requirements.md), [04_semantic_model.md](04_semantic_model.md)

### 5.3 Risk of Broken Production Changes

- **Problem:** Unvalidated model changes can break dashboards.
- **Fix:** PR approvals + CI test gates + linting + deployment workflow.
- **Impact:** Only validated changes are promoted.
- **Evidence:** [ci_dbt_build_pass.png](screenshots/05_dataops/ci_dbt_build_pass.png), [github_pr_checks_pass.png](screenshots/05_dataops/github_pr_checks_pass.png)

---

## 6. Security and Access Boundaries

### 6.1 Warehouse Security

- Role hierarchy applies least-privilege boundaries between loading, transformation, and reporting responsibilities.
- Production reporting role is read-only on marts.

Evidence: [RBAC.png](screenshots/02_snowflake/RBAC.png)

### 6.2 Semantic Security

- RLS enforced in semantic layer using mapping table policy.
- Regional access control validated through UAT scenarios.

Evidence: [uat_rls_validation.png](screenshots/04_powerbi/uat_rls_validation.png)

---

## 7. Cost and Performance Guardrails

- **Warehouse sizing:** X-Small defaults with aggressive auto-suspend.
- **Storage strategy:** RAW transient + STAGING views to reduce overhead.
- **Build strategy:** Incremental facts for shorter refresh windows.
- **Monitoring:** Query/runtime checks and CI results reviewed per release.

Reference details: [05_performance_optimization.md](05_performance_optimization.md)

---

## 9. Evidence Index

### Infrastructure

- Azure structure: [container_structure.png](screenshots/01_azure_blob_storage/container_structure.png)
- Snowflake schemas: [database.png](screenshots/02_snowflake/database.png)
- Snowflake warehouses: [warehouse.png](screenshots/02_snowflake/warehouse.png)

### Transformation and Quality

- dbt DAG: [lineage_dag.png](screenshots/03_dbt/lineage_dag.png)
- dbt tests: [test_passed_suite.png](screenshots/03_dbt/test_passed_suite.png)
- dbt contracts: [data_contracts.png](screenshots/03_dbt/data_contracts.png)

### BI and Governance

- Semantic model: [semantic_model.png](screenshots/04_powerbi/semantic_model.png)
- Incremental refresh: [incremental_refresh.png](screenshots/04_powerbi/incremental_refresh.png)
- RLS validation: [uat_rls_validation.png](screenshots/04_powerbi/uat_rls_validation.png)

### DataOps

- CI pass: [ci_dbt_build_pass.png](screenshots/05_dataops/ci_dbt_build_pass.png)
- PR quality gates: [github_pr_checks_pass.png](screenshots/05_dataops/github_pr_checks_pass.png)
- Roadmap tracking: [project_milestones_roadmap.png](screenshots/05_dataops/project_milestones_roadmap.png)

---
