{{
    config(
        severity='error',
        tags=['singular_test', 'business_rule', 'reviews']
    )
}}

{#
    SINGULAR TEST: Review Scores Within Valid Range

    PURPOSE: Validate review scores follow Olist rating system

    BUSINESS RULE: Customer satisfaction scores must be integers 1-5
    - 1 = Very Dissatisfied
    - 2 = Dissatisfied
    - 3 = Neutral
    - 4 = Satisfied
    - 5 = Very Satisfied

    WHY: Invalid scores would:
    1. Break NPS (Net Promoter Score) calculations
    2. Corrupt customer satisfaction dashboards
    3. Indicate data corruption in review system

    EXPECTED: 0 violations (all scores in [1,2,3,4,5])
#}

with reviews as (

    select
        review_id,
        order_id,
        review_score
    from {{ ref('stg_olist__reviews') }}

),

violations as (

    select
        review_id,
        order_id,
        review_score,
        case
            when review_score is null then 'NULL score'
            when review_score < 1 then 'Score below minimum (< 1)'
            when review_score > 5 then 'Score above maximum (> 5)'
            when review_score::integer != review_score then 'Non-integer score'
        end as violation_type
    from reviews
    where
        review_score is null
        or review_score < 1
        or review_score > 5
        or review_score::integer != review_score

)

-- Test fails if ANY invalid scores found
select * from violations
