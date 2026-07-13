-- distinct collapses only exact duplicates (all three fields equal).
-- conflicting duplicates (same product_id, different attributes) survive
-- distinct and fail the unique test on product_id at severity error.
select distinct
    child_asin as product_id,
    product_name,
    product_marketing_category
from {{ ref('product_master_file') }}
where child_asin is not null
