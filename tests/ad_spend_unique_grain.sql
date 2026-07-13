select
    product_marketing_category,
    ad_date
from {{ ref('mart_ad_spend') }}
group by
    product_marketing_category,
    ad_date
having count(*) > 1
