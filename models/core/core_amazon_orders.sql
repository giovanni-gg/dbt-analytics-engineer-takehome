with orders as (

    select * from {{ ref('stg_amazon_orders') }}

),

products as (

    select * from {{ ref('stg_product_master') }}

),

enriched as (

    select
        orders.order_id,
        orders.order_time,
        orders.order_date,
        orders.market,
        orders.product_id,
        coalesce(products.product_name, 'Unknown') as product_name,
        coalesce(products.product_marketing_category, 'Unknown') as product_marketing_category,
        orders.sales_amount,
        orders.sales_amount < 0 as is_refund
    from orders
    left join products using (product_id)

)

select * from enriched
