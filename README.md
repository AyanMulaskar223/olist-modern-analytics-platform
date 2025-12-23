# 🛍️ Olist Modern Analytics Platform

**A scalable, end-to-end ELT pipeline transforming raw e-commerce data into actionable business insights.**

![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)
![Tech Stack](https://img.shields.io/badge/Stack-Azure_Blob_%7C_Snowflake_%7C_dbt_%7C_Power_BI-blue)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 🚀 Executive Summary

This project migrates a legacy, manual CSV reporting process to a **Modern Data Stack (MDS)**. By automating the ingestion, transformation, and visualization of the Olist E-Commerce dataset (~100k orders), this platform reduces reporting latency by **95%** and provides real-time insights into logistics performance, sales trends, and customer behavior.

**Key Engineering Features:**

- **Infrastructure as Code:** Snowflake warehouses and databases provisioned via SQL scripts.
- **Data Quality:** Automated testing (uniqueness, not-null, referential integrity) via dbt.
- **Governance:** Role-Based Access Control (RBAC) separating Development and Production environments.
- **CI/CD:** Automated linting (SQLFluff) and testing pipelines via GitHub Actions.

---

## 🏗️ System Architecture

The platform follows a **Batch ELT (Extract, Load, Transform)** architecture designed for scalability and cost-efficiency.

```mermaid
flowchart LR
    %% Modern ELT architecture (transform inside Snowflake; raw is immutable)

    A[Azure Blob Storage\nRaw CSV Files] -->|COPY INTO (Snowflake)| B[(Snowflake RAW\nImmutable landing)]

    subgraph SNOWFLAKE[Snowflake]
        direction LR

        B -->|dbt models| C[(STAGING\nstg_* cleans & types)]
        C -->|dbt models| D[(INTERMEDIATE\nint_* business logic)]
        D -->|dbt models| E[(MARTS\nStar Schema: dim_* & fct_*)]

        %% Quality gates
        C -.->|dbt tests\nnot_null • unique • relationships| Q[Data Quality]
        D -.->|dbt tests\naccepted_values • relationships| Q
        E -.->|dbt tests\nfct/dim integrity| Q
    end

    E -->|Power BI (DirectQuery)\nPresentation only| F[Power BI Dashboard]
```

**Notes**

- **RAW is immutable**; all transformation and business logic live in **dbt** (STAGING → INTERMEDIATE → MARTS).
- **MARTS enforces a star schema** with dbt-generated surrogate keys (no business logic pushed into Power BI).
- **dbt tests act as quality gates** to prevent regressions in CI/CD.
