-- A product absent from the master cannot be assigned a real category.
-- If we do not know what the product is, its category must be 'Unknown'.

with ads_violations as (

    select
        'core_amazon_ads' as source_model,
        ads.ad_id as record_id,
        ads.product_id,
        ads.product_marketing_category
    from {{ ref('core_amazon_ads') }} as ads
    left join {{ ref('stg_product_master') }} as products using (product_id)
    where products.product_id is null
        and ads.product_marketing_category != 'Unknown'

),

orders_violations as (

    select
        'core_amazon_orders' as source_model,
        orders.order_id as record_id,
        orders.product_id,
        orders.product_marketing_category
    from {{ ref('core_amazon_orders') }} as orders
    left join {{ ref('stg_product_master') }} as products using (product_id)
    where products.product_id is null
        and orders.product_marketing_category != 'Unknown'

)

select * from ads_violations
union all
select * from orders_violations
