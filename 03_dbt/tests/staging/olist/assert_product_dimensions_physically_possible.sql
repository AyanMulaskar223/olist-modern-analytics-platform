{{
    config(
        severity='warn',
        tags=['singular_test', 'business_rule', 'products', 'logistics']
    )
}}

{#
    SINGULAR TEST: Product Dimensions Physically Possible

    PURPOSE: Validate product dimensions are within realistic bounds

    BUSINESS RULE: Product specifications must be physically realistic
    - Weight: 1g - 100kg (0.001kg - 100kg)
    - Length: 1cm - 300cm (max shipping box size)
    - Height: 1cm - 300cm
    - Width: 1cm - 300cm

    WHY: Unrealistic dimensions cause:
    1. Freight calculation errors
    2. Warehouse space planning issues
    3. Carrier rejection (oversized items)

    SEVERITY: WARN (not ERROR) because:
    - Some outliers may be legitimate (furniture, bulk items)
    - Phase 2 already flagged missing dimensions

    EXPECTED: <1% of products with extreme dimensions (investigate if higher)
#}

with products as (

    select
        product_id,
        category_name_pt,
        weight_g,
        length_cm,
        height_cm,
        width_cm
    from {{ ref('stg_olist__products') }}
    where not is_missing_dimensions  -- Exclude already-flagged missing dimensions

),

violations as (

    select
        product_id,
        category_name_pt,
        weight_g,
        length_cm,
        height_cm,
        width_cm,
        case
            when weight_g > 100000 then 'Weight > 100kg (unrealistic for e-commerce)'
            when length_cm > 300 then 'Length > 300cm (exceeds max shipping)'
            when height_cm > 300 then 'Height > 300cm (exceeds max shipping)'
            when width_cm > 300 then 'Width > 300cm (exceeds max shipping)'
            when weight_g < 1 and weight_g > 0 then 'Weight < 1g (likely data error)'
            when length_cm < 1 and length_cm > 0 then 'Length < 1cm (likely data error)'
            when height_cm < 1 and height_cm > 0 then 'Height < 1cm (likely data error)'
            when width_cm < 1 and width_cm > 0 then 'Width < 1cm (likely data error)'
        end as violation_type
    from products
    where
        -- Check upper bounds
        weight_g > 100000
        or length_cm > 300
        or height_cm > 300
        or width_cm > 300
        -- Check lower bounds (excluding exactly 0, which are imputed)
        or (weight_g < 1 and weight_g > 0)
        or (length_cm < 1 and length_cm > 0)
        or (height_cm < 1 and height_cm > 0)
        or (width_cm < 1 and width_cm > 0)

)

-- Test warns if physically impossible dimensions found
select * from violations
