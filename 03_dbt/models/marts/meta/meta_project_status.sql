{{
    config(
        materialized='table',
        tags=['meta']
    )
}}

select
    -- 1. PROOF OF WORK: "My pipeline ran successfully at this time."
    current_timestamp() as pipeline_last_run_at,

    -- 2. PROOF OF DATA: "The data inside represents business up to this date."
    (select max(order_date_dt) from {{ ref('fct_order_items') }}) as data_valid_through
