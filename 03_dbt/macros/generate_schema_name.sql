{#
    Custom schema naming macro for Olist Analytics Platform

    Purpose: Override dbt's default schema naming to prevent username prefixes

    Default dbt behavior:
      - dev target: creates "dbt_ayan_staging"
      - prod target: creates "staging"

    Our override:
      - dev target: creates "staging" (clean name)
      - prod target: creates "staging" (same name)

    This allows DEV and PROD to have identical schema structures,
    differing only by database (OLIST_DEV_DB vs OLIST_ANALYTICS_DB)
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {#- If no custom schema specified, use target default -#}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}

    {#- If custom schema specified, use it directly (no prefix) -#}
    {%- else -%}
        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
