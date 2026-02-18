# Data Quality & Testing Strategy

![Tests](https://img.shields.io/badge/Tests-559%20Automated-brightgreen?style=for-the-badge)
![Coverage](https://img.shields.io/badge/Coverage-100%25%20PK%2FFK-blue?style=for-the-badge)
![Revenue Quality](https://img.shields.io/badge/Revenue%20Quality-99.8%25%20Verified-success?style=for-the-badge)
![CI Gate](https://img.shields.io/badge/CI%20Gate-Blocking-critical?style=for-the-badge)

!!! warning "Portfolio Scenario — Data Quality"
⚠️ Portfolio Scenario: This document outlines the requirements for a simulated Digital Transformation project at Olist. It addresses real data quality issues found in the public dataset, treating them as live business risks.

> **📘 SSOT References**
>
> - **Architecture context:** [01_architecture.md](01_architecture.md) (layer responsibilities, data flow)
> - **Security controls:** Section 6 of architecture doc (RBAC, RLS details)
> - **Performance optimization:** [05_performance_optimization.md](05_performance_optimization.md) (speed = trust analysis)
> - **Business rules:** [00_business_requirements.md](00_business_requirements.md) (KPI definitions)

---

## 1. Quality Framework at a Glance

**Strategy:** Flag anomalies, preserve 100% of data, expose dual metrics.

**Evidence:** [Screenshot Index](#8-evidence-index) (15 screenshots showing test results, CI enforcement, reconciliation)

| Layer            | Test Count       | Focus Area             | Materialization    |
| :--------------- | :--------------- | :--------------------- | :----------------- |
| **RAW**          | 85 source tests  | Freshness, row counts  | Transient tables   |
| **STAGING**      | 456 generic      | PK/FK integrity, enums | Views              |
| **INTERMEDIATE** | 18 singular      | Business rules, flags  | Ephemeral/tables   |
| **MARTS**        | 100% FK coverage | Grain enforcement      | Tables/incremental |
| **Power BI**     | Schema contracts | Verified metrics       | Semantic model     |

**Quality Flow:**

```
Azure Blob → RAW (Freshness Check) → STAGING (PK/FK Tests) → INTERMEDIATE (Quality Flags) → MARTS (Contract Validation) → Power BI (Verified Measures)
         ↓              ↓                      ↓                         ↓                        ↓                          ↓
    85 source      456 generic           18 singular              Grain checks            Schema drift           Dual metrics
     tests          tests                 tests                   enforcement             protection              exposed
```

---

## 2. Decision Log

| Decision                 | Rationale                                                    | Trade-off                                         | Evidence                    |
| :----------------------- | :----------------------------------------------------------- | :------------------------------------------------ | :-------------------------- |
| **Flag vs. Delete**      | Finance requires 100% reconciliation with ERP                | Slightly more complex DAX (Total vs. Verified)    | [Revenue reconciliation](#) |
| **559 Automated Tests**  | Zero-trust validation at every layer                         | 5-minute CI runtime (acceptable for quality gate) | [CI pass screenshot](#)     |
| **dbt Singular Tests**   | Generic tests can't validate cross-column business rules     | Maintenance overhead (18 custom SQL tests)        | [Business rule tests](#)    |
| **Schema Contracts**     | Fail-fast on breaking changes (not silent errors)            | Requires explicit type definitions in YAML        | [Contract enforcement](#)   |
| **Dual Metric Strategy** | Stakeholders need both "Total" (audit) and "Verified" (exec) | Dashboard users must understand quality context   | [Trust tooltip UX](#)       |

---

## 3. Test Coverage Matrix

### 3.1 Test Pyramid

```
         ▲
        ╱ ╲        18 Singular Tests (10% of total)
       ╱   ╲       • No future order dates
      ╱     ╲      • Timestamp sequence validation
     ╱───────╲     • Negative price checks
    ╱         ╲
   ╱  456 Generic ╲   Generic Tests (82% of total)
  ╱   dbt Tests   ╱   • unique, not_null (100% PK coverage)
 ╱   (Unit Tests) ╲   • relationships (100% FK coverage)
╱─────────────────╲   • accepted_values (enums, states)
                   ╲
               85 Source Tests (15% of total)
               • Freshness < 14 days
               • Row count validation
               ✅ 559 total tests
```

### 3.2 Critical Business Rules

| Test Name                                    | Severity | Rule                                     | Impact                        |
| :------------------------------------------- | :------- | :--------------------------------------- | :---------------------------- |
| `assert_no_future_order_dates`               | ERROR    | `order_date <= CURRENT_DATE`             | Prevents timeline corruption  |
| `assert_order_timestamps_logical_sequence`   | WARN     | Ordered → Approved → Shipped → Delivered | Detects data quality issues   |
| `assert_no_negative_prices_or_freight`       | ERROR    | `price >= 0 AND freight >= 0`            | Protects revenue calculations |
| `assert_delivered_orders_have_delivery_date` | ERROR    | `status='delivered' → date NOT NULL`     | Ensures SLA accuracy          |

### 3.3 Coverage Summary

| Coverage Type        | Target | Actual          | Status |
| :------------------- | :----- | :-------------- | :----- |
| **Primary Keys**     | 100%   | 29/29 models    | ✅     |
| **Foreign Keys**     | 100%   | 17/17 relations | ✅     |
| **Source Freshness** | 100%   | 8/8 RAW tables  | ✅     |
| **State Enum**       | 100%   | 27 BR states    | ✅     |
| **Test Pass Rate**   | 100%   | 559/559 tests   | ✅     |

---

## 4. Problem → Fix → Impact

### Problem 1: Finance Can't Reconcile Revenue

**Problem:**

- Deleting anomalous orders breaks total reconciliation with source ERP
- 3 departments report different "Total Revenue" numbers
- Audit compliance at risk

**Fix:**

- Strategy: "Flag, Don't Delete"
- Implementation: Add `is_verified` column in INTERMEDIATE layer
- Expose dual metrics in Power BI: `[Total Revenue]` vs. `[Verified Revenue]`

**Impact:**

```
Total Revenue:     R$ 13,591,643  (100% - matches Finance ERP)
Verified Revenue:  R$ 13,564,851  (99.8% - executive reporting)
Revenue at Risk:   R$ 26,792      (0.2% - flagged for investigation)
```

- **Result:** Finance achieves 100% reconciliation, Executives use 99.8% verified subset
- **Evidence:** [UAT Revenue Reconciliation Screenshot](#)

---

### Problem 2: Schema Changes Break Dashboards Silently

**Problem:**

- Power BI refreshes succeeded despite column renames in dbt
- Visuals showed blank data, no error alerts
- 2-day delayed detection by business users

**Fix:**

- dbt: `contract: enforced: true` in MARTS models (compile-time validation)
- Power Query: `Table.SelectColumns()` explicit selection (fail-fast on missing columns)

**Impact:**

- **Before:** Silent failures → 2-day detection lag
- **After:** Immediate CI failure → < 5 minutes detection
- **Evidence:** [dbt Contract Enforcement Screenshot](#), [Power BI Schema Error](#)

---

### Problem 3: Timestamp Violations Corrupt SLA Metrics

**Problem:**

- 127 orders have `delivered_at < ordered_at` (impossible timeline)
- SLA "Days to Deliver" metric shows **negative values**
- Operations team loses trust in dashboard accuracy

**Fix:**

- Singular Test: `assert_order_timestamps_logical_sequence.sql`
- Quality Flag: `has_timestamp_violation` column
- DAX Filter: `[SLA Metrics]` only use `is_verified = TRUE` orders

**Impact:**

- **Before:** Negative SLA values → Dashboard credibility failure
- **After:** 99.8% clean SLA metrics → Operations trust restored
- **Evidence:** [Timestamp Validation Test Results](#)

---

## 5. Quality Flag Logic

**Implementation Layer:** `int_orders_enriched.sql` (INTERMEDIATE)

**Flag Columns:**

| Flag Name                 | Condition                               | Count | % of Total |
| :------------------------ | :-------------------------------------- | :---- | :--------- |
| `has_missing_product`     | `product_id IS NULL`                    | 610   | 0.6%       |
| `has_invalid_price`       | `order_total <= 0 OR freight_value < 0` | 235   | 0.2%       |
| `has_timestamp_violation` | `delivered_at < ordered_at`             | 127   | 0.1%       |
| **Master Switch**         | `is_verified = ALL FLAGS PASS`          | 98.9% | ✅         |

**Data Flow:**

```sql
-- INTERMEDIATE: int_orders_enriched.sql
SELECT
    order_id,
    order_total,
    -- Quality flags
    CASE WHEN product_id IS NULL THEN TRUE ELSE FALSE END AS has_missing_product,
    CASE WHEN order_total <= 0 THEN TRUE ELSE FALSE END AS has_invalid_price,
    CASE WHEN delivered_at < ordered_at THEN TRUE ELSE FALSE END AS has_timestamp_violation,
    -- Master flag
    CASE
        WHEN has_missing_product = FALSE
         AND has_invalid_price = FALSE
         AND has_timestamp_violation = FALSE
        THEN TRUE ELSE FALSE
    END AS is_verified
FROM {{ ref('stg_orders') }}
```

**Power BI Consumption:**

```dax
// Total Revenue (Finance reconciliation)
Total Revenue = SUM(fct_orders[order_total])

// Verified Revenue (Executive reporting)
Verified Revenue =
CALCULATE(
    SUM(fct_orders[order_total]),
    fct_orders[is_verified] = TRUE
)

// Transparency metric
Revenue at Risk = [Total Revenue] - [Verified Revenue]
```

---

## 6. CI/CD Quality Gate

**Enforcement Mechanism:** GitHub Actions blocks PRs on test failure.

**Workflow:**

```
Developer Push → CI Trigger → dbt build → Tests Run → [PASS/FAIL]
                                            ↓
                                         PASS: ✅ PR approval allowed
                                         FAIL: ❌ Merge blocked
                                               ↓
                                          Auto-create GitHub Issue
                                          Alert #data-quality-alerts
```

**Protection Rules:**

| Rule                        | Implementation           | Impact                         |
| :-------------------------- | :----------------------- | :----------------------------- |
| **Cannot merge on failure** | GitHub branch protection | 0% untested code in production |
| **< 5 min feedback**        | GitHub Actions runtime   | Fast iteration cycles          |
| **Auto-issue creation**     | Workflow orchestration   | Zero manual triage of failures |
| **100% traceability**       | Git commit history       | Audit-ready change log         |

---

## 7. Monitoring & Freshness

> **🔗 SSOT Reference**
> Performance monitoring details (dashboard refresh SLA, performance analyzer results) covered in [05_performance_optimization.md](05_performance_optimization.md).

### 7.1 dbt Source Freshness

**Configuration:**

| Threshold          | Action         | Alert Channel   |
| :----------------- | :------------- | :-------------- |
| `warn_after: 7d`   | Slack alert    | #data-alerts    |
| `error_after: 14d` | Fail dbt build | CI blocks merge |

**Production Status:**

- ✅ 8/8 RAW tables within SLA
- ✅ < 1 hour ingestion latency
- ✅ 0 stale data incidents (30 days)

### 7.2 Data Currency Indicator

**Problem:** Users distrust dashboards without visible "Last Updated" timestamp.

**Fix:**

Multi-Layer Tracking:

| Layer     | Timestamp Column | Business Purpose                 |
| :-------- | :--------------- | :------------------------------- |
| **RAW**   | `_loaded_at`     | Azure → Snowflake ingestion time |
| **MARTS** | `_dbt_loaded_at` | dbt transformation completion    |

**Power BI Display:**

```dax
Last Refresh =
FORMAT(
    MAX('dim_date'[_dbt_loaded_at]),
    "MMMM DD, YYYY @ hh:mm AM/PM"
)
```

**Visual:** Card visual on every dashboard page header.

**Result:** Users trust data because currency is transparent.

---

## 8. Evidence Index

| Evidence                     | Location                                                        | Shows                                  |
| :--------------------------- | :-------------------------------------------------------------- | :------------------------------------- |
| **dbt Test Suite**           | `screenshots/03_dbt/test_passed_suite.png`                      | 100% pass rate (559 tests)             |
| **dbt Lineage DAG**          | `screenshots/03_dbt/lineage_dag.png`                            | Test coverage across layers            |
| **CI Pipeline Pass**         | `screenshots/05_dataops/ci_dbt_build_pass.png`                  | GitHub Actions blocking merge          |
| **GitHub PR Checks**         | `screenshots/05_dataops/github_pr_checks_pass.png`              | Branch protection rules                |
| **GitHub Issue Tracking**    | `screenshots/05_dataops/github_issue_tracking.png`              | Auto-created issues from test failures |
| **Revenue Reconciliation**   | `screenshots/04_powerbi/uat_revenue_reconciliation.png`         | Finance 100% match validation          |
| **Trust Tooltip UX**         | `screenshots/04_powerbi/trust_tooltip_ux.png`                   | Dual metric transparency               |
| **Data Quality Dashboard**   | `screenshots/04_powerbi/data_quality_audit.png`                 | Verified vs. At-Risk breakdown         |
| **dbt Contracts**            | `screenshots/03_dbt/data_contracts.png`                         | Schema drift protection                |
| **Power BI Schema Contract** | `screenshots/04_powerbi/data_contract.png`                      | Explicit column selection              |
| **Power BI Query Folding**   | `screenshots/04_powerbi/query_folding.png`                      | Snowflake pushdown optimization        |
| **Performance Analyzer**     | `screenshots/04_powerbi/performance_analyzer_excutive_page.png` | < 2s load times                        |
| **Snowflake RBAC**           | `screenshots/02_snowflake/RBAC.png`                             | Role hierarchy (least privilege)       |
| **Power BI RLS Validation**  | `screenshots/04_powerbi/uat_rls_validation.png`                 | State-level filtering                  |
| **Project Roadmap**          | `screenshots/05_dataops/project_milestones_roadmap.png`         | GitHub Projects SLA tracking           |

---

## 9. Measured Impact

### 9.1 Quality Scorecard

| Metric                   | Result                 | SLA/Target |
| :----------------------- | :--------------------- | :--------- |
| **Test Coverage**        | 100% (559 tests)       | 100%       |
| **Primary Key Coverage** | 29/29 models           | 100%       |
| **Foreign Key Coverage** | 17/17 relationships    | 100%       |
| **Test Pass Rate (30d)** | 100%                   | > 99%      |
| **Verified Revenue**     | 99.8% (R$ 13.56M)      | > 99%      |
| **Revenue at Risk**      | 0.2% (R$ 26.7K)        | < 1%       |
| **RAW Data Freshness**   | < 1 hour               | < 14 days  |
| **CI Feedback Loop**     | < 5 minutes            | < 10 min   |
| **Dashboard Load Time**  | 1.8s (95th percentile) | < 2s       |

### 9.2 Operational Impact

| Process                    | Before        | After        | Improvement     |
| :------------------------- | :------------ | :----------- | :-------------- |
| **Finance Reconciliation** | 4 days/month  | 0 hours      | 100% automation |
| **Ad-hoc SQL Requests**    | 12 hours/week | 0 hours      | Self-service    |
| **Data Quality Triage**    | 6 hours/week  | 2 hours/week | 67% reduction   |
| **Dashboard Load Time**    | No SLA        | 1.8s (avg)   | Performance SLA |

**Total Time Saved:** 112 hours/month (93% reduction in manual work)

---

## 10. Quality Framework Completeness

| Domain                | Coverage                      | Evidence              |
| :-------------------- | :---------------------------- | :-------------------- |
| **Test Automation**   | ✅ 559 tests, 100% PK/FK      | CI screenshots        |
| **Schema Contracts**  | ✅ dbt + Power BI enforced    | Contract screenshots  |
| **Business Rules**    | ✅ 18 singular tests          | Test result logs      |
| **Dual Metrics**      | ✅ Total vs. Verified exposed | Dashboard UX          |
| **CI/CD Gate**        | ✅ GitHub Actions blocking    | PR check failure demo |
| **Monitoring**        | ✅ Freshness + refresh SLA    | Monitoring dashboards |
| **Security & Access** | ✅ RBAC + RLS (see arch doc)  | Role matrix           |
| **Performance**       | ✅ < 2s SLA (see perf doc)    | Performance Analyzer  |

**Optional Enhancements (10/10+ Level):**

- Data quality dashboard embedded in Power BI (currently screenshots only)
- Automated Slack notifications on test failures (currently GitHub Issues only)
- Historical test failure trend analysis (currently point-in-time only)

---

## 11. Key Principles

**1. Flag, Don't Delete**
Preserve 100% of source data → Finance reconciliation possible

**2. Explicit Over Implicit**
Schema contracts fail fast → No silent breaking changes

**3. Trust Through Transparency**
Dual metrics exposed → Stakeholders understand quality scores

**4. Zero-Trust Validation**
559 automated tests → Every layer has quality gates

**5. Fail-Fast CI Gate**
< 5 min feedback → No untested code in production

---

**Quality is not a feature. It's the foundation of trust.**

Every layer has explicit validation. Every metric has transparent quality scoring. Every change is tested before production.

This framework demonstrates enterprise-grade data quality engineering.
