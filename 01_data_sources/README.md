# Data Sources – Raw Input Overview

## Purpose

This folder documents the **raw data sources** used in the Olist Modern Analytics Platform project.

It exists to:

- Provide **transparency** about where data comes from
- Document **schemas and meanings** before ingestion
- Support **traceability** from source → Snowflake → dbt → Power BI
- Avoid committing large or sensitive datasets to Git

This folder is **documentation-first** and does **NOT** store full production datasets.

---

## Data Source Summary

| Source Name              | Domain               | Format               | Origin          | Refresh           |
| ------------------------ | -------------------- | -------------------- | --------------- | ----------------- |
| Olist E-commerce Dataset | Retail / Marketplace | CSV / JSON / Parquet | Kaggle (Public) | One-time (Static) |

---

## Folder Structure

```text
01_data_sources/
├── raw_sample_files/       # Small, non-sensitive samples
├── data_dictionary.md      # Column-level definitions
└── README.md               # This file
```

### raw_sample_files/

Contains small sample extracts only, used for:

- Schema understanding
- Testing ingestion logic
- Demonstrating multi-format ingestion (CSV / JSON / Parquet)

**Rules:**

- No full datasets
- No PII
- No secrets
- Max 20 rows per file
- Same column names as production files

### data_dictionary.md

Documents:

- Table purpose
- Column definitions
- Data types
- Business meaning
- Known data quality issues

Acts as the contract between raw data and downstream transformations.

---

## Related Documentation

- [Data Dictionary](./data_dictionary.md)
- [Snowflake Infrastructure](../02_snowflake/README.md)
- [Azure Storage Setup](../docs/02_azure_storage_setup.md)
