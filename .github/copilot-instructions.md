## Project Overview

This repository contains an end-to-end modern analytics platform built using:

- Azure Blob Storage
- Snowflake
- dbt Core
- Power BI (.pbip)
- GitHub Actions for CI
- SQLFluff for SQL linting

The project follows a structured ADLC (Analytics Development Lifecycle).

---

## Project Phases

1. Phase 1 – Business Understanding & Requirements (Completed)
2. Phase 2 – Data Acquisition & Ingestion
3. Phase 3 – Data Transformation & Modeling (dbt)
4. Phase 4 – Analytics & Visualization (Power BI)
5. Phase 5 – CI/CD, Testing & Documentation

Copilot should always be aware of the **current phase** before suggesting solutions.

---

## Architectural Principles

- ELT architecture (transform inside Snowflake)
- Raw data is immutable
- All transformations happen in dbt
- Power BI contains no business logic beyond presentation
- Star schema is mandatory in MARTS
- Surrogate keys are generated in dbt, not Power BI

---

## Coding Guidelines

### SQL (Snowflake)

- Use CTEs for readability
- Avoid SELECT \*
- Use explicit data types
- Handle NULLs intentionally
- Prefer DATE/TIMESTAMP functions native to Snowflake

### dbt

- Naming conventions:
- stg*<source>*<table>
- int\_<business_logic>
- dim\_<entity>
- fct\_<process>
- Use dbt tests for:
- not_null
- unique
- accepted_values
- relationships
- Document models and columns using schema.yml
- Use refs, never hardcoded table names

### Power BI

- One semantic model
- Measures only (no calculated columns unless justified)
- Use DAX best practices
- Hide technical columns
- Single-direction relationships unless explicitly required

---

## Data Quality Rules

- Never silently drop records
- Outliers must be flagged, not removed
- Business rules must be documented before implementation
- Any filtering logic must be traceable to business requirements

---

## Documentation Expectations

When generating code, Copilot should:

- Explain business logic in comments
- Reference relevant docs in /docs
- Avoid assumptions without stating them

---

## What NOT to Do

- Do not invent new KPIs
- Do not move business logic into Power BI
- Do not bypass dbt for transformations
- Do not generate production credentials
- Do not over-optimize prematurely

---

## Copilot Behavior Preference

- Ask clarifying questions when requirements are unclear
- Prefer simple, readable solutions
- Explain trade-offs
- Assume this project will be reviewed by senior data engineers
