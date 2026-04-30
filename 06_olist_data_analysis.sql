use olist_db;

-- 1.Business Growth

-- Revenue Trend
select
	d.year,
    d.month,
    sum(f.price+f.freight_value) as revenue,
    count(distinct f.order_id) as total_orders,
    round(sum(f.price+f.freight_value)/count(distinct f.order_id),2) as AOV
from fact_order_items f
join dim_date d
	on f.date_key = d.date_key
group by d.year,d.month
order by d.year,d.month;

/* 
Key findings
1. The early 2016 period shows extremely low transaction volume, indicating incomplete data.
These months were excluded from analysis.
2. Revenue shows strong growth throughout 2017, increasing from ~137k in January to over 1.1M in November.
3. Growth is primarily driven by increasing order volume (789 → 7451), while Average Order Value (AOV) remains relatively stable (~150–170), 
indicating customer acquisition rather than increased spending.
4. A significant spike in November 2017 suggests strong seasonality, likely driven by promotional events such as Black Friday.
5. Post-November, revenue declines and stabilizes, indicating normalization after peak demand.
6. In 2018, revenue plateaus around the 1M mark, suggesting the business has reached a more stable stage after rapid growth.
7. The final month (2018-09) shows incomplete data and was excluded from analysis.
*/

-- 2.Customer Behavior

-- Customer analysis

-- Monthly active customers
select 
	month(date(order_purchase_time)) as MONTH,
	year(date(order_purchase_time)) as YEAR,
	count(distinct customer_unique_id) as active_customers
from dim_customer c
join clean_orders o
	on c.customer_id=o.customer_id
group by
	year(date(order_purchase_time)), 
	month(date(order_purchase_time))
order by 
	year(date(order_purchase_time)), 
	month(date(order_purchase_time))
;

/*
Observation:
Customer growth shows a strong upward trend throughout 2017, aligning with revenue growth and indicating that business expansion is driven by 
customer acquisition. A notable spike in November suggests seasonal demand likely driven by promotions. 
In 2018, customer growth stabilizes, indicating a transition to a mature phase. Late-period data shows anomalies and was excluded from analysis.
*/


-- Single order vs Multiple order customers	
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM clean_orders o
    JOIN dim_customer c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    total_orders,
    COUNT(*) AS number_of_customers
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;

/*
The customer base shows very low repeat purchase behaviour, indicating weak retention. 
Growth is likely driven by new customer acquisition rather than customer loyalty, highlighting an opportunity to improve retention strategies.
*/

-- 3.Funnel analysis

SELECT
    YEAR(order_purchase_time) AS order_year,
    MONTH(order_purchase_time) AS order_month,
    COUNT(*) AS placed_orders,
    COUNT(order_approved_at) AS approved_orders,
    COUNT(delivered_date) AS delivered_orders,

    ROUND(COUNT(order_approved_at) * 100.0 / COUNT(*), 2) AS placed_to_approved_percentage,
    ROUND(COUNT(delivered_date) * 100.0 / COUNT(*), 2) AS placed_to_delivered_percentage,
    ROUND(COUNT(delivered_date) * 100.0 / NULLIF(COUNT(order_approved_at), 0), 2) AS approved_to_delivered_percentage
FROM clean_orders
GROUP BY
    YEAR(order_purchase_time),
    MONTH(order_purchase_time)
ORDER BY
    order_year,
    order_month;

/*
Despite strong funnel conversion and high delivery success rates, customer retention remains low.
This suggests that the issue is likely related to product experience, pricing, or competition rather than operational inefficiency
and the business should focus on improving post-purchase experience and retention strategies rather than acquisition alone.
*/


-- 4. Retention

-- Cohort analysis
WITH cohort_data AS (
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_time) OVER(PARTITION BY c.customer_unique_id),'%Y-%m') AS cohort_month,
        TIMESTAMPDIFF(MONTH,DATE_FORMAT(MIN(o.order_purchase_time) OVER (PARTITION BY c.customer_unique_id),'%Y-%m-01'),
        DATE_FORMAT(o.order_purchase_time, '%Y-%m-01')
        ) AS next_order_month_number
    FROM clean_orders o
    JOIN clean_customers c
        ON o.customer_id = c.customer_id
)
SELECT
    cohort_month,
    next_order_month_number,
    COUNT(DISTINCT customer_unique_id) AS retained_customers
FROM cohort_data
GROUP BY
    cohort_month,
    next_order_month_number
ORDER BY
    cohort_month,
    next_order_month_number;
    
/* observation
The cohort analysis shows extremely low retention across all cohorts,with less than 1% of customers returning after their first purchase.
The sharp drop between month 0 and month 1 indicates that most users are one-time buyers. This suggests the business is heavily reliant 
on new customer acquisition rather than repeat engagement.
 */


-- Churn analysis
WITH customer_last_order AS (
    SELECT
        d.customer_unique_id,
        MAX(c.order_purchase_time) AS last_order_date
    FROM dim_customer d
    JOIN clean_orders c
        ON d.customer_id = c.customer_id
    GROUP BY d.customer_unique_id
),
dataset_max_date AS (
    SELECT MAX(order_purchase_time) AS max_order_date
    FROM clean_orders
)
SELECT
    clo.customer_unique_id,
    DATE(clo.last_order_date) AS last_order_date,
    TIMESTAMPDIFF(DAY, clo.last_order_date, dmd.max_order_date) AS days_inactive,
    CASE
        WHEN TIMESTAMPDIFF(DAY, clo.last_order_date, dmd.max_order_date) > 90 THEN 'churned'
        ELSE 'still_active'
    END AS churn_status
FROM customer_last_order clo
CROSS JOIN dataset_max_date dmd;

-- Creating a view table for further analysis
CREATE VIEW churn_analysis AS
WITH customer_last_order AS (
    SELECT
        d.customer_unique_id,
        MAX(c.order_purchase_time) AS last_order_date
    FROM dim_customer d
    JOIN clean_orders c
        ON d.customer_id = c.customer_id
    GROUP BY d.customer_unique_id
),
dataset_max_date AS (
    SELECT MAX(order_purchase_time) AS max_order_date
    FROM clean_orders
)

select * from view churn_analysis;
SELECT
    clo.customer_unique_id,
    clo.last_order_date,
    dmd.max_order_date,
    TIMESTAMPDIFF(DAY, clo.last_order_date, dmd.max_order_date) AS days_inactive,
    CASE
        WHEN TIMESTAMPDIFF(DAY, clo.last_order_date, dmd.max_order_date) > 90 THEN 'churned'
        ELSE 'active'
    END AS churn_status
FROM customer_last_order clo
CROSS JOIN dataset_max_date dmd;

-- Creating an index to optimze query
create index idx_churn_analysis on churn_analysis(customer_unique_id);

SELECT 
    churn_status,
    COUNT(*) AS users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM churn_analysis
GROUP BY churn_status;

WITH order_counts AS (
    SELECT 
        d.customer_unique_id,
        COUNT(*) AS total_orders
    FROM dim_customer d
    JOIN clean_orders c
        ON d.customer_id = c.customer_id
    GROUP BY d.customer_unique_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN '1 order'
        WHEN total_orders <= 3 THEN '2-3 orders'
        ELSE '4+ orders'
    END AS customer_type,
    churn_status,
    COUNT(*) AS users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM churn_analysis t
JOIN order_counts o
    ON t.customer_unique_id = o.customer_unique_id
GROUP BY customer_type, churn_status;

/*
Around 90% of users churn within 90 days
Breaking this down further, nearly all churn (~87%) comes from customers who placed only one order.

This indicates that the major drop-off happens after the first purchase,

This suggests that improving early-stage engagement and encouraging repeat purchases 
could have the biggest impact on retention
*/


-- Further analysis
WITH order_count AS (
    SELECT 
        d.customer_unique_id,
        COUNT(DISTINCT f.order_id) AS total_orders,
        SUM(f.price + f.freight_value) AS total_spent
    FROM dim_customer d
    JOIN fact_order_items f
        ON d.customer_key = f.customer_key
    GROUP BY d.customer_unique_id
),
segmented AS (
    SELECT 
        customer_unique_id,
        CASE
            WHEN total_spent < 100 THEN 'low_value'
            WHEN total_spent BETWEEN 100 AND 300 THEN 'mid_value'
            ELSE 'high_value'
        END AS total_purchase,
        CASE
            WHEN total_orders = 1 THEN '1_order'
            WHEN total_orders BETWEEN 2 AND 3 THEN '2-3_orders'
            ELSE '4+_orders'
        END AS no_of_orders
    FROM order_count
)
SELECT 
    no_of_orders,
    total_purchase,
    COUNT(*) AS users
FROM segmented
GROUP BY no_of_orders, total_purchase
ORDER BY no_of_orders, users DESC;

/*
Analysis shows that the customer base is heavily skewed towards one-time purchasers,
most of whom fall in low-to-mid spending segments. In contrast, 
repeat customers are significantly fewer but skew towards higher spending,
suggesting that early user experience and initial purchase value are key drivers of retention
 */
 
 /*
 Are low-value users causing churn?
 it is partially true
 churn is mostly driven by single-order users, most of whom fall in the low-to-mid value segment. However, high-value single-order users also exist, 
 indicating that low spend alone is not the sole driver
 */
 

 
 