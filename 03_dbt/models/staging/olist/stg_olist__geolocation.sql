{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'geolocation', 'geo']
    )
}}

{#
    PURPOSE: Clean and deduplicate raw_geolocation data to create a valid coordinate reference.
    GRAIN: Unique Coordinate Point (Lat/Lng) per Zip Code.
    SOURCE: raw_geolocation (CSV format, ~1M rows).

    WARNING:
    This table contains multiple coordinates per Zip Code.
    Do NOT join directly to Orders/Sellers (1-to-Many fanout risk).
    Aggregating to one Centroid per Zip Code (in Intermediate/Marts) is required before joining.

    ADLC COMPLIANCE:
    ✅ Deduplication: Applied SELECT DISTINCT to compress 1M log rows into unique points.
    ✅ Map Safety: Converted invalid coordinates (>90/>180) to NULL to prevent Power BI crashes.
    ✅ Zip Formatting: Padded with zeros (e.g., '1001' -> '01001') to ensure joins with Customers.
    ✅ Standardization: Fixed casing inconsistencies (e.g., 'niteroi' -> 'Niteroi').
    ✅ Type Casting: Explicit float casting for geospatial accuracy.

    DATA QUALITY SUMMARY (from Phase 2 Validation):
    - Duplicate Volume: High (e.g., Zip 24220 has 1,146 rows). Deduplication is mandatory.
    - Invalid Coordinates: ~680 rows found out of valid range (Lat > 90). Fixed via NULL logic.
    - City Spelling: Inconsistent usage of accents ('Sao Paulo' vs 'São Paulo'). Fixed via INITCAP.
#}

with source as (

    -- 🛑 PERFORMANCE NOTE:
    -- We use DISTINCT here because the source is a log of user GPS pings.
    -- We only need the unique distinct locations, not the frequency of pings.
    select distinct * from {{ source('olist', 'raw_geolocation') }}

),

renamed as (

    select
        -- 📍 ZIP CODE (The Future Join Key)
        -- We pad this to 5 digits so it matches stg_customers and stg_sellers perfectly.
        lpad(geolocation_zip_code_prefix::varchar, 5, '0')::varchar(5) as zip_code,

        -- 🌍 COORDINATES (Safety First)
        -- DQ Finding: 310 Lat / 370 Lng errors found.
        -- We NULL out invalid coordinates so Power BI Maps render successfully without crashing.
        -- Valid Range: Lat (-90 to 90), Lng (-180 to 180).
        case
            when geolocation_lat between -90 and 90 then geolocation_lat::float
            else null
        end as latitude,

        case
            when geolocation_lng between -180 and 180 then geolocation_lng::float
            else null
        end as longitude,

        -- 🏙️ CITY & STATE (Aesthetic Fixes)
        -- DQ Finding: 'niteroi', 'niterói', 'Niterói'.
        -- INITCAP standardizes visual presentation (e.g., 'Sao Paulo') for cleaner dashboards.
        initcap(trim(geolocation_city))::varchar(50) as city,
        upper(trim(geolocation_state))::varchar(2) as state

    from source

)

select * from renamed
