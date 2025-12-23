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

flowchart LR
%% 1. Source System
A[Azure Blob Storage\nRaw CSV Files]

    %% 2. Snowflake Environment (The "Box")
    subgraph SNOWFLAKE[Snowflake Data Warehouse]
        direction LR

        %% Nodes defined inside the subgraph appear inside the box
        B[(RAW DB\nImmutable landing)]
        C[(STAGING\nstg_* cleans & types)]
        D[(INTERMEDIATE\nint_* business logic)]
        E[(MARTS\nStar Schema: dim_* & fct_*)]

        %% Relationships inside Snowflake
        B -->|dbt models| C
        C -->|dbt models| D
        D -->|dbt models| E
    end

    %% 3. Connections & Quality
    A -->|"COPY INTO (Ingestion)"| B

    %% Quality Gate (Floating node)
    Q>Data Quality Checks\ndbt tests]
    C -.->|not_null\nunique| Q
    D -.->|relationships\naccepted_values| Q
    E -.->|referential\nintegrity| Q

    %% 4. Consumption
    E -->|"Power BI (DirectQuery)"| F[Power BI\nDashboard]

**Notes**

- **RAW is immutable**; all transformation and business logic live in **dbt** (STAGING → INTERMEDIATE → MARTS).
- **MARTS enforces a star schema** with dbt-generated surrogate keys (no business logic pushed into Power BI).
- **dbt tests act as quality gates** to prevent regressions in CI/CD.
