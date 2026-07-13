select
    product_marketing_category,
    order_date
from {{ ref('mart_sales') }}
group by
    product_marketing_category,
    order_date
having count(*) > 1
