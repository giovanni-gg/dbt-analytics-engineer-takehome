
with unioned as (

    select
        ad_id,
        ad_date,
        market,
        child_asin,
        ad_cost
    from {{ ref('amazon_ads_de') }}

    union all

    select
        ad_id,
        ad_date,
        market,
        child_asin,
        ad_cost
    from {{ ref('amazon_ads_uk') }}

),

renamed as (

    select
        ad_id,
        cast(ad_date as date) as ad_date,
        market,
        child_asin as product_id,
        cast(ad_cost as decimal(18, 2)) as ad_cost
    from unioned

)

select *
from renamed
