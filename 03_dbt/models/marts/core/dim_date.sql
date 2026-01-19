{{
    config(
        materialized='table',
        schema='marts',
        tags=['dates', 'marts', 'core', 'dimension']
    )
}}

{#
    PURPOSE: Date dimension for calendar-based time series analysis
    GRAIN: One row per calendar day
    SOURCE: Generated using dbt_date package

    BUSINESS CONTEXT:
    - Provides the master calendar for all date-based analysis
    - Includes hierarchies (year → quarter → month → day)
    - Includes sort keys for proper visualization ordering
    - Ready for Power BI relationship: date_day → fct_order_items.order_date_dt

    MARTS LAYER RULES:
    ✅ Star Schema dimension (conformed calendar)
    ✅ Business-friendly column names
    ✅ Explicit column selection
    ✅ Table materialization for fast Power BI queries
    ✅ Sort keys for dimension ordering

    DATE RANGE:
    - Start: 2016-01-01 (Olist dataset beginning)
    - End: 2018-12-31 (Olist dataset end)

#}

with date_spine as (

    select
        dateadd('day', row_number() over (order by null) - 1, '2016-01-01'::date) as date_day
    from table(generator(rowcount => 1096))  -- 1096 days from 2016-01-01 to 2018-12-31

)

select
    -- 🔑 PRIMARY KEY (Date)
    date_day,

    -- 📅 YEAR HIERARCHY
    extract(year from date_day)::integer as year_number,

    -- 📅 QUARTER HIERARCHY
    'Q' || extract(quarter from date_day)::varchar as quarter_name,

    -- 📅 MONTH HIERARCHY
    to_char(date_day, 'MMMM') as month_name,
    to_char(date_day, 'Mon') as month_short_name,
    extract(month from date_day)::integer as month_number,

    -- 📅 YEAR-MONTH COMBINED (For grouping)
    (extract(year from date_day) * 100 + extract(month from date_day))::integer as year_month_number,
    to_char(date_day, 'Mon-YY') as year_month_name,

    -- 📅 DAY OF WEEK HIERARCHY
    to_char(date_day, 'Day') as day_of_week_name,
    extract(dayofweek from date_day)::integer as day_of_week_number,

    -- 🚚 LOGISTICS FLAGS
    -- 1 = Weekend (Sat/Sun), 0 = Weekday
    case
        when extract(dayofweek from date_day) in (0, 6) then 1
        else 0
    end as is_weekend,

    -- ⏰ METADATA
    current_timestamp()::timestamp_ltz as dbt_updated_at

from date_spine
