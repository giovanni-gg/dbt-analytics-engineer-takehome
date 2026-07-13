select
    product_marketing_category,
    activity_date
from {{ ref('mart_sales_and_ad_spend') }}
group by
    product_marketing_category,
    activity_date
having count(*) > 1
