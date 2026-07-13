-- Business rule: a category can never be refunded more than it has sold.
-- Refunds are negative sales_amount rows, so the lifetime net sales of a
-- category must stay >= 0. A negative net means we refunded money we never
-- collected, which points to broken or incomplete order data.
select
    product_marketing_category,
    sum(sales_amount) as net_sales
from {{ ref('core_amazon_orders') }}
group by product_marketing_category
having sum(sales_amount) < 0
