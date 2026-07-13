# Sergio Murino - Analytics Engineering Take-Home - Solution

## Assumptions

- **currency**: not specified, my assumption is that the costs and sales_amount are reported with a standard currency, since I checked that the same child_asin has the same price in both DE and UK

- **different time between UK and DE**: not relevant to the current analysis.

## Note

The solution is organized by layer->model rather than by sections (data quality issues, modeling and join choices) as mentioned in the README.md file. I believe this it's more helpful while presenting the results.


## Staging layer

### stg_amazon_ads

- **negative costs** --> fine, it might be a refund according to my interpretation, e.g.: We overpaid the ad for a product 10 days ago, and today we receive a refund for the same product.
- **ad_id**: must be a primary key, that's why I test that it is unique and not null with a severity error
- **ad_date**: even though that's not happening in the data at my disposal, what if ad_date is NULL?
  That's for sure something annoying, and I wanna test it, but only with a warning severity: I keep NULL dates through staging and core so no cash flow is lost and future non-daily marts could still use those rows. The daily marts instead exclude them (a row without a date cannot be placed on a day) and enforce it with a not_null test at error severity, see the marts section below.
- **ad_cost / sales_amount**: I test not_null with warning severity. A NULL amount would not break the marts (SQL sum() simply ignores NULLs), but that's exactly the problem: the row would silently contribute nothing to the totals, so money would disappear from the marts without a trace. I wanna be warned so I can chase the source extract, but I don't wanna block the pipeline since the remaining rows are still good.
- **child_asin**: rename to product_id, because it's more declarative than child_asin
- **cost**: cast to decimal(18,2), we avoid long decimal numbers produced by double and float
- **market**: accepted values are only DE, UK, DK (as far as I know DK is part of amazon DE). However that's only a warning, I imagine that in the future someone adds a new amazon market, simply unioning it in the staging layer, he/she might forget to change the accepted values, so we wanna receive a warning but we don't want to stop the models.
- **child_asin/product_id**: it is a foreign key on product_master, that's why I test the relationship. In the order file we have a product_id that is not in the master, that's why I imagine it can happen also for ads. However the test is only a warning, because I wanna know if something is off with our (internal) catalogue, but still I am fine with proceeding with the pipeline, I don't wanna lose information about the cash flow. I will handle it in the core marts.

### stg_amazon_orders

- Everything that is stated above is also valid for orders.
- **order_id and ad_id**: My hypothesis is that one order can contain only one product because that's the evidence with the data at my disposal, if an unique order can be associated with more products that would change something (e.g. primary key). Same for ads.
- **order_time**: only difference is that we cast order_time to two columns, order_date and order_time, since the final marts model is aggregated by day, however we keep time for possible models in the future (e.g. analysis on time-seasonality of sales)

### stg_product_master

- **general**: we have an exact duplicate, meaning that all columns match. That's why I use a distinct in the model. I choose to deduplicate only if all the columns match, because if only the product_id/child_asin matches, we might have a situation in which we don't know which category the product belongs to. That's why we test the uniqueness of product_id with severity error.
Also I wanna exclude NULL product_id, because I am considering it as primary key.
- **product_name**: I am fine with it being both null and not unique, that's why I don't test anything.
- **product_marketing_category**: it can of course be not unique, if it's null I wanna raise a warning so that we can update our catalogue but I don't wanna stop the pipeline.

## Core layer

### core_amazon_ads and core_amazon_orders

- In this layer I only do two things, left join and map to 'Unknown' for product_name and category if they are NULL. If a product is not present in our catalogue, it will be mapped to 'Unknown' category. Same applies if we get an order/ad with NULL product_id. Finally I introduce a trivial flag is_refund (amount < 0), just to identify if a transaction is a regular one or a refund.
- I test that a product with Unknown product_id MUST have an 'Unknown' product category, I don't want someone to maybe force a NULL product_id, I follow the logic: If we don't know what it is, we cannot know which category it belongs to. (That's also why I removed the NULL row from master, how can you know it is an Accessory if you don't know what it is)
- I also test that a category can never be refunded more than it has sold: since refunds are negative sales_amount rows, the lifetime net sales of a category must stay >= 0. If it goes negative we refunded money we never collected, which means the order data is broken or incomplete (refunds_not_exceeding_sales test)

## Marts layer

### general (all marts)

- **NULL dates**: while staging and core tolerate NULL dates (warning severity) so the full cash flow stays queryable, the daily marts are a contract for reporting at category x day grain: a row without a date has no meaning there, so it is filtered out in the mart and the not_null test on the date/category columns runs at error severity. This way the test guards the contract (it can only fail if someone breaks the model), and the pipeline never stops because of a bad source row. One caveat I am aware of: if NULL dates ever appear, the mart totals would diverge from core totals, which is precisely what the warning test at staging alerts us about.
- **grain uniqueness**: for each mart I have a singular test asserting the category x day grain is really unique, since upstream tests cannot guarantee that the aggregation/join logic of the mart itself doesn't fan out rows.

### mart_ad_spend

- I simply aggregate by date and category, only thing worth mentioning is that I create two different columns, one for all ads (ad_spend_total) and one excluding refunds (ad_spend_no_refunds)

### mart_sales

- Same as ads, only difference is sales_amount instead of ad_cost.

### mart_sales_and_ad_spend

- We basically simply outer join the two marts, why outer? Because I still wanna have 0 values if no sales/ad was performed for a category in a day.
- date is renamed to a neutral 'activity_date'
- I introduce sales_minus_ad_spend which is simply sales_total - ad_spend_total. It wasn't requested but it might be useful to see for a category, day pair the sales we did minus what we have spent to advertise it (it might actually also be useful to compute a ratio, but I did not want to overkill with lack of information on the business)

## Next steps (with more time)

- **Market breakdown in the marts**: the required grain was category x day, so I aggregated across markets, but I kept the market column in the staging and core layers so a per-market breakdown is possible at any time. In my opinion this is something that should be discussed with the stakeholders, and I personally believe it is important: UK and DE are different businesses, so seeing sales and ad spend per market would make the marts much more actionable.
- **Full date spine in the marts**: today the combined mart only has rows for category-day pairs where at least one of sales or ads happened. I think it's important that for every day between min(min_day_ads, min_day_orders) and max(max_day_ads, max_day_orders) there is a row for every existing category, with 0 values where nothing happened. I would build it by generating a calendar model covering that date range (e.g. with generate_series  or date_spine), cross joining it with the distinct list of categories to get the full category x day scaffold, and then left joining the sales and ad spend aggregates onto it, coalescing the missing metrics to 0. This makes time-series analysis and charting in BI tools much cleaner, since "no activity" days are explicit instead of missing.
- **Add more metrics**: e.g. ROAS, it's nice to know how the investment of ads are paying off with sales by category.
- **Split the models per diffrent datasets**: probably bulding a macros for definfing a custom_schema if we needed to deploy everything in BigQuery for examples. As of now every model and table lie in the same dataset
- **Incremental models**: Maybe use incremental models, depending on the quantity of data we are handling.
