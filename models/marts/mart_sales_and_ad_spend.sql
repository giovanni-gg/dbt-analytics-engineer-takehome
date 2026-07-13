with sales as (

    select * from {{ ref('mart_sales') }}

),

ad_spend as (

    select * from {{ ref('mart_ad_spend') }}

),

combined as (

    select
        coalesce(sales.product_marketing_category, ad_spend.product_marketing_category)
            as product_marketing_category,
        coalesce(sales.order_date, ad_spend.ad_date) as activity_date,
        coalesce(sales.sales_no_refunds, 0) as sales_no_refunds,
        coalesce(sales.sales_total, 0) as sales_total,
        coalesce(ad_spend.ad_spend_no_refunds, 0) as ad_spend_no_refunds,
        coalesce(ad_spend.ad_spend_total, 0) as ad_spend_total
    from sales
    full outer join ad_spend
        on sales.product_marketing_category = ad_spend.product_marketing_category
        and sales.order_date = ad_spend.ad_date

)

select
    *,
    sales_total - ad_spend_total as sales_minus_ad_spend
from combined
