with ads as (

    select * from {{ ref('stg_amazon_ads') }}

),

products as (

    select * from {{ ref('stg_product_master') }}

),

enriched as (

    select
        ads.ad_id,
        ads.ad_date,
        ads.market,
        ads.product_id,
        coalesce(products.product_name, 'Unknown') as product_name,
        coalesce(products.product_marketing_category, 'Unknown') as product_marketing_category,
        ads.ad_cost,
        ads.ad_cost < 0 as is_refund
    from ads
    left join products using (product_id)

)

select * from enriched
