{% macro drop_ci_schema(schema_name) %}
  {% set drop_query %}
    DROP SCHEMA IF EXISTS {{ target.database }}.{{ schema_name }} CASCADE
  {% endset %}

  {{ log("Dropping CI schema: " ~ schema_name, info=True) }}
  {% do run_query(drop_query) %}
  {{ log("Schema dropped successfully", info=True) }}
{% endmacro %}
