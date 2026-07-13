with orders as (

    select * from {{ ref('core_amazon_orders') }}

),

aggregated as (

    select
        product_marketing_category,
        order_date,
        sum(case when not is_refund then sales_amount else 0 end) as sales_no_refunds,
        sum(sales_amount) as sales_total
    from orders
    -- rows without a date cannot be placed on a daily grain; they stay
    -- queryable in core but are excluded from the daily mart
    where order_date is not null
    group by
        product_marketing_category,
        order_date

)

select * from aggregated
