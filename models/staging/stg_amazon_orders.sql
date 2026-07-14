with unioned as (

    select
        order_id,
        order_time,
        market,
        child_asin,
        sales_amount
    from {{ ref('amazon_orders_de') }}

    union all

    select
        order_id,
        order_time,
        market,
        child_asin,
        sales_amount
    from {{ ref('amazon_orders_uk') }}

),

renamed as (

    select
        order_id,
        cast(order_time as timestamp) as order_time,
        cast(order_time as date) as order_date,
        market,
        child_asin as product_id,
        cast(sales_amount as decimal(18, 2)) as sales_amount
    from unioned

)

select *
from renamed
