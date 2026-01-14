{{
    config(
        materialized='view',
        schema='intermediate',
        tags=['products', 'intermediate', 'logistics']
    )
}}

{#
    ============================================================================
    MODEL: int_products__enriched
    ============================================================================

    PURPOSE:
        Enrich staging products with category translations and consolidate
        quality metrics into business-ready flags.

        Acts as the bridge between raw product data and final dim_products
        and fct_order_items fact tables.

    GRAIN:
        One row per product_id (unique product from stg_olist__products).

    KEY TRANSFORMATIONS:

    1. **Category Translation (Bilingual Strategy)**
       - Original: Preserve Portuguese category_name_pt (for audit trail)
       - Translation: Join with category translations for English names
       - Golden Name: COALESCE(English, Portuguese, 'Unknown')
       - Strategy: LEFT JOIN ensures no products are lost if translation missing

    2. **Quality Verification (Data Quality Compression)**
       - quality_issue_reason: Consolidate 3 flags into single diagnostic field
         Priority: Missing Photos > Missing Dimensions > Missing Category
       - is_verified: Master boolean (1=clean, 0=has issues)
         1 = All quality checks pass
         0 = At least one quality issue detected

    BUSINESS RULES:
        - Products without English translations retain Portuguese names
        - Quality flags flagged, NOT filtered (allows BI to decide filtering)
        - Missing dimensions imputed to 0 in staging (prevent math errors)
        - Missing photos imputed to 0 in staging (flag separately here)

    DEPENDENCIES:
        - {{ ref('stg_olist__products') }} (Phase 2 staging)
        - {{ ref('stg_olist__category_translations') }} (Phase 2 seeds)

    MATERIALIZATION:
        Ephemeral (compiled as CTE in downstream models, zero storage)

    OWNER: Analytics Engineering Team
    SLA: Real-time (no physical table)
    Tags: products, intermediate, logistics, translation
    ============================================================================
#}

WITH products AS (
    SELECT * FROM {{ ref('stg_olist__products') }}
),

translations AS (
    SELECT * FROM {{ ref('stg_olist__category_translations') }}
),

enriched AS (
    SELECT
        -- 🔑 Keys
        products.product_sk,
        products.product_id,

        -- 📦 Product Attributes (CRITICAL: Pass these through!)
        products.photos_qty,
        products.weight_g,
        products.length_cm,
        products.height_cm,
        products.width_cm,
        products.description_length,

        -- 🏷️ Category Logic (The "Bilingual" Strategy)
        -- 1. Original (for Audit)
        products.category_name_pt,
        -- 2. Translation (for Display)
        translations.category_name_en,
        -- 3. The Golden Coalesce (for convenience in downstream Marts)
        COALESCE(
            translations.category_name_en,
            products.category_name_pt,
            'Unknown'
        ) AS category_name,

        -- 🛡️ Quality Compression Strategy
        -- Prioritize the worst errors first.
        CASE
            WHEN products.is_missing_photos = 1 THEN 'Missing Photos'
            WHEN products.is_missing_dimensions = 1 THEN 'Missing Dimensions'
            WHEN products.category_name_pt IS NULL THEN 'Missing Category'
            ELSE NULL
        END AS quality_issue_reason

    FROM products
    -- 🧠 LEFT JOIN preserves products even if they have no translation
    LEFT JOIN translations
        ON products.category_name_pt = translations.category_name_pt
)

SELECT
    *,
    -- ✅ DRY Logic: Don't repeat the CASE WHEN conditions.
    -- If there is no failure reason, the product is verified.
    CASE
        WHEN quality_issue_reason IS NULL THEN 1
        ELSE 0
    END AS is_verified
FROM enriched
