with ads as (

    select * from {{ ref('core_amazon_ads') }}

),

aggregated as (

    select
        product_marketing_category,
        ad_date,
        sum(case when not is_refund then ad_cost else 0 end) as ad_spend_no_refunds,
        sum(ad_cost) as ad_spend_total
    from ads
    -- rows without a date cannot be placed on a daily grain; they stay
    -- queryable in core but are excluded from the daily mart
    where ad_date is not null
    group by
        product_marketing_category,
        ad_date

)

select * from aggregated
