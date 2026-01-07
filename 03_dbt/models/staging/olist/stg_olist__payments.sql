{{
    config(
        materialized='view',
        schema='staging',
        tags=['staging', 'olist', 'payments', 'finance']
    )
}}

{#
    PURPOSE: Clean and standardize raw_order_payments
    GRAIN: Unique per order_id + payment_sequential
    SOURCE: raw_order_payments (CSV format, 103,886 rows)

    ADLC COMPLIANCE:
    ✅ Composite Surrogate Key Generation (order_id + sequential)
    ✅ Explicit Type Casting (Numeric safety for finance)
    ✅ Business Rule: Map 'not_defined' -> 'unknown'
    ✅ Data Fix: Impute 0 installments to 1 (prevent divide-by-zero)
    ✅ Audit: Flag zero-value payments

    DATA QUALITY SUMMARY (from Validation):
    - Integrity: 100% (No Null PKs, No Orphans)
    - Zero Installments: 2 rows (Fixed -> 1)
    - Zero Value: 9 rows (Flagged: is_zero_payment)
    - Payment Types: 'not_defined' (3 rows) -> 'unknown'
#}

with source as (

    select * from {{ source('olist', 'raw_order_payments') }}

),

renamed as (

    select
        -- 🔑 KEYS
        -- PK is Composite (Order + Sequence). Hashing guarantees a unique ID per payment row.
        {{ dbt_utils.generate_surrogate_key([('order_id'), 'payment_sequential']) }} as payment_sk,

        -- FK to Orders (One-to-Many relationship)
        {{ dbt_utils.generate_surrogate_key([('order_id')])}} as order_sk,
        trim(order_id)::varchar(32) as order_id,

        -- 🔢 SEQUENCE
        -- Tracks if this was the 1st, 2nd, or 3rd card used for the order
        payment_sequential::integer as payment_sequence,

        -- 💳 PAYMENT TYPE (Standardized)
        -- DQ Fix: 3 rows were 'not_defined'. Mapped to 'unknown' for cleaner BI charts.
        case
            when lower(trim(payment_type)) = 'not_defined' then 'unknown'
            else lower(trim(payment_type))
        end::varchar(20) as payment_type,

        -- 📉 INSTALLMENTS (Data Fix)
        -- DQ Fix: 2 rows had 0 installments (Credit Card).
        -- We force to 1 to prevent "Divide by Zero" errors in downstream Marts.
        case
            when payment_installments = 0 then 1
            else payment_installments
        end::integer as installments,

        -- 💰 FINANCIAL VALUES
        -- Using NUMERIC(18,2) is mandatory for currency to avoid floating point errors.
        cast(payment_value as numeric(18, 2)) as payment_amount,

        -- 🚩 DATA QUALITY FLAGS

        -- Flag: Zero Value (9 rows)
        -- Likely vouchers (100% discount) or system glitches. Useful to filter out of "Avg Order Value".
        case
            when payment_value = 0 then true
            else false
        end as is_zero_payment,



        -- 📝 AUDIT
        _source_file::varchar as source_file,
        _loaded_at::timestamp_ntz as source_loaded_at_utc

    from source

)

select * from renamed
