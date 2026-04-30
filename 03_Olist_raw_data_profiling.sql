USE olist_db;

-- ROW COUNT CHECK
SELECT COUNT(*) FROM raw_orders;
SELECT COUNT(*) FROM raw_order_items;
SELECT COUNT(*) FROM raw_customers;
SELECT COUNT(*) FROM raw_products;
SELECT COUNT(*) FROM raw_sellers;
SELECT COUNT(*) FROM raw_category_translation;
SELECT COUNT(*) FROM raw_order_payments;
SELECT COUNT(*) FROM raw_order_reviews;
SELECT COUNT(*) FROM raw_geolocation;

-- 1.raw_orders table

select * from raw_orders;
-- Null checks
SELECT 
	sum(case when order_id is null then 1 else 0 end) as null_order_id,
    sum(case when customer_id is null then 1 else 0 end) as null_customer_id,
    sum(case when order_status is null then 1 else 0 end) as null_order_status,
    sum(case when order_purchase_timestamp is null then 1 else 0 end) as null_order_purchase_timestamp,
    sum(case when order_approved_at is null then 1 else 0 end) as null_order_approved_at,
    sum(case when order_delivered_carrier_date is null then 1 else 0 end) as null_order_delivered_carrier_date,
    sum(case when order_delivered_customer_date is null then 1 else 0 end) as null_order_delivered_customer_date,
    sum(case when order_estimated_delivery_date is null then 1 else 0 end) as null_order_estimated_delivery_date
from raw_orders;

-- Duplicate checks
select order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,
order_delivered_customer_date, order_estimated_delivery_date,count(*) as dupe_count
FROM raw_orders
GROUP BY
order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,
order_delivered_customer_date, order_estimated_delivery_date
HAVING dupe_count>1;

-- Blank checks
SELECT *
FROM raw_orders
WHERE 
order_id =''
    OR customer_id=''
    OR order_status=''
    OR order_purchase_timestamp=''
    OR order_approved_at=''
    OR order_delivered_carrier_date=''
    OR order_delivered_customer_date=''
    OR order_estimated_delivery_date='';

-- ORDER STATUS DISTRIBUTION
SELECT order_status, COUNT(*)
FROM raw_orders
GROUP BY order_status;

-- ANOMALY CHECKS
SELECT order_status,count(*)
FROM raw_orders
WHERE order_approved_at = ''
GROUP BY order_status;

SELECT order_status,count(*)
FROM raw_orders
WHERE order_delivered_carrier_date = '' 
GROUP BY order_status;

SELECT *
FROM raw_orders
WHERE order_delivered_carrier_date = '';

SELECT *
FROM raw_orders
WHERE order_delivered_carrier_date = '' and 
order_status not in ('canceled','invoiced','processing','unavailable');

/*
Most blanks are expected for cancelled and created ordersand reflect the business process rather than data quality issues.
A small number of delivered orders also contain missing intermediate timestamps, these rows are retained as valid transactions, 
but blanks are standardized to NULL and treated as anomalies for time-based analysis
*/

SELECT DISTINCT 
    TIME(order_estimated_delivery_date) AS time_part
FROM raw_orders;

-- Observation:The time part is 00:00:00 for all the values so it is better to delete as it offers no insights

-- 2.raw_order_items

-- Null checks
select 	
	SUM(order_id is null) as null_orderid,
    SUM(order_item_id is null) as null_order_item_id,
    SUM(product_id is null) as null_product_id,
    SUM(seller_id is null) as null_seller_id,
    SUM(shipping_limit_date is null) as null_shipping_limit_date,
    SUM(price is null) as null_price,
    SUM(freight_value is null) as null_freight_value
FROM raw_order_items;

-- blank checks
select 	
	SUM(order_id = '') as blank_orderid,
    SUM(order_item_id  = '') as blank_order_item_id,
    SUM(product_id = '') as blank_product_id,
    SUM(seller_id = '') as blank_seller_id,
    SUM(shipping_limit_date = '') as blank_shipping_limit_date,
    SUM(price = '') as blank_price,
    SUM(freight_value = '') as blank_freight_value
FROM raw_order_items;

-- Duplicate checks
select order_id, order_item_id, product_id, seller_id,
	shipping_limit_date, price, freight_value, count(*)
FROM raw_order_items
GROUP BY order_id, order_item_id, product_id, seller_id,
	shipping_limit_date, price, freight_value
HAVING count(*)>1;

-- Primary_key Duplicate check
SELECT 
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM raw_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Check price sanity
SELECT *
FROM raw_order_items
WHERE price <= 0 OR freight_value < 0;

-- Check for extreme values
SELECT 
    MIN(price), MAX(price),
    MIN(freight_value), MAX(freight_value)
FROM raw_order_items;


-- 3.raw_order_payments table

-- Null checks
select 
	sum(order_id is null) as null_order_id,
    sum(payment_sequential is null) as null_payment_sequential,
	sum(payment_type is null) as null_payment_type,
	sum(payment_installments is null) as null_payment_type,
	sum(payment_value is null) as null_payment_value
FROM raw_order_payments;

-- Blank checks
select 
	sum(order_id = '') as blank_order_id,
	sum(payment_sequential = '') as blank_payment_sequential,
	sum(payment_type = '') as blank_payment_type,
	sum(payment_installments = '') as blank_payment_installments,
	sum(payment_value = '') as blank_payment_value
FROM raw_order_payments;

-- Duplicate check
select 
	order_id,
	payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    count(*)
FROM raw_order_payments
GROUP BY order_id,
	payment_sequential,
    payment_type,
    payment_installments,
    payment_value
HAVING count(*)>1;

-- Checking for anomalies in payment_type
select 
	count(*),
    payment_type 
FROM raw_order_payments
GROUP BY payment_type;

-- Checking for any outliers in payment_installment
SELECT 
	max(payment_installments),
	min(payment_installments) 
FROM raw_order_payments;

-- Checking for any outliers in payment_values
SELECT 
	max(payment_value),
	min(payment_value) 
FROM raw_order_payments;


-- 4.raw_customer

-- Null checks
select 
	sum(customer_id is null),
    sum(customer_unique_id is null),
    sum(customer_zip_code_prefix is null),
    sum(customer_city is null),
    sum(customer_state is null)
FROM raw_customers;

-- Blank checks
select 
	sum(customer_id = ''),
    sum(customer_unique_id = ''),
    sum(customer_zip_code_prefix = ''),
    sum(customer_city = ''),
    sum(customer_state = '')
FROM raw_customers;

-- duplicate checks
select 
	customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    COUNT(*)
FROM raw_customers
GROUP BY
	customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
HAVING count(*) >1;

-- primary_key duplicate check
select customer_id,count(*) from raw_customers
GROUP BY customer_id
HAVING count(*) >1;

select customer_id,customer_unique_id,count(*) from raw_customers
GROUP BY customer_id,customer_unique_id
HAVING count(*) >1;

-- zip_code check
select customer_zip_code_prefix 
from raw_customers
where length(customer_zip_code_prefix)<> 5;

-- city check(casing,spacing or abnormal values)
SELECT customer_city, COUNT(*) 
FROM raw_customers
GROUP BY customer_city
ORDER BY COUNT(*) asc
LIMIT 100;

-- Checking for customers with no orders;
SELECT COUNT(*)
FROM raw_customers c
LEFT JOIN raw_orders o
ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- Orders with no customers
SELECT COUNT(*)
FROM raw_orders o
LEFT JOIN raw_customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5.Raw_category_translation

-- Null checks
SELECT
    SUM(product_category_name IS NULL OR TRIM(product_category_name) = '') AS bad_category_name,
    SUM(product_category_name_english IS NULL OR TRIM(product_category_name_english) = '') AS bad_category_name_english
FROM raw_category_translation;

-- Duplicate checks
SELECT product_category_name,product_category_name_english
FROM raw_category_translation
GROUP BY product_category_name,product_category_name_english
HAVING COUNT(*) > 1;


-- 6 raw_products

-- Null/Blank check
SELECT
    SUM(product_id IS NULL OR TRIM(product_id) = ''),
    SUM(product_category_name IS NULL OR TRIM(product_category_name) = ''),
    SUM(product_name_lenght IS NULL  OR TRIM(product_name_lenght) = ''),
    SUM(product_description_lenght IS NULL  OR TRIM(product_description_lenght) = ''),
    SUM(product_photos_qty IS NULL  OR TRIM(product_photos_qty) = ''),
    SUM(product_weight_g IS NULL  OR TRIM(product_weight_g) = ''),
    SUM(product_length_cm IS NULL  OR TRIM(product_length_cm) = '') ,
    SUM(product_height_cm IS NULL  OR TRIM(product_height_cm) = ''),
    SUM(product_width_cm IS NULL  OR TRIM(product_width_cm) = '')
FROM raw_products;


-- 610 records of blank values identified in product_category_name,product_name_length,product_description_length & product_photos_qty


-- Checking the impact on revenue and total products
 
 -- Total product impact
select 
	count(*),
    sum(product_category_name IS NULL OR TRIM(product_category_name) = '') as blank_row_count,
    round(sum(product_category_name IS NULL OR TRIM(product_category_name) = '')*100/count(*),2) as product_percentage_imapacted
FROM raw_products;
	
-- Revenue impacted
SELECT 
    concat(round(SUM(oi.price + oi.freight_value)/100000,2),'M') AS revenue_impacted_in_millions
FROM raw_products p
JOIN raw_order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL
   OR TRIM(p.product_category_name) = '';
   
-- Duplicate Checks
SELECT product_id, COUNT(*)
FROM raw_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Category_checks
SELECT COUNT(*) 
FROM raw_products
WHERE product_category_name IS NULL 
   OR TRIM(product_category_name) = '';

-- Extreme/Outlier values checks
SELECT
    MIN(product_weight_g), MAX(product_weight_g),
    MIN(product_length_cm), MAX(product_length_cm),
    MIN(product_height_cm), MAX(product_height_cm),
    MIN(product_width_cm), MAX(product_width_cm)
FROM raw_products;


SELECT 
    COUNT(*) AS total_products,
    SUM(product_category_name IS NULL OR TRIM(product_category_name) = '') AS missing_category,
    ROUND(
        SUM(product_category_name IS NULL OR TRIM(product_category_name) = '') * 100.0 
        / COUNT(*), 2
    ) AS missing_percentage
FROM raw_products;

-- Clean table
/* 
Identified 610 products with missing category values. Since these represent valid products with incomplete metadata, 
they were retained and stored as NULL to preserve data integrity.
 */


SELECT COUNT(DISTINCT p.product_id) AS unique_products_with_missing_category
FROM raw_products p
JOIN raw_order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL
   OR TRIM(p.product_category_name) = '';
   
   
   select count(*) from raw_order_items
   where product_id in (select product_id from
   raw_products where product_category_name='');

SELECT COUNT(DISTINCT p.product_id) AS unique_products_with_missing_category
FROM raw_products p
JOIN raw_order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL
   OR TRIM(p.product_category_name) = '';
   
-- 7.raw_sellers

-- Null/blank check
Select 
	sum(seller_id is null or seller_id =''),
    sum(seller_zip_code_prefix is null or seller_zip_code_prefix=''),
    sum(seller_city  is null or seller_city =''),
    sum(seller_state is null or seller_state='')
FROM raw_sellers;

-- Duplicate check
Select count(*) from raw_sellers
GROUP BY seller_id
having count(*)>1;

-- zip_code_prefix_check
select * from raw_sellers
where length(seller_zip_code_prefix)<>5;

-- 8. raw_order_reviews

-- Blank/Null checks
select 
	sum(review_id is null or review_id=''),
    sum(order_id is null or order_id = ''),
    sum(review_score is null or review_score = ''),
    sum(review_comment_title is null or review_comment_title = ''),
    sum(review_creation_date is null or review_creation_date = ''),
    sum(review_answer_timestamp is null or review_answer_timestamp = '')
FROM raw_order_reviews;

-- Score checks
SELECT review_score, COUNT(*) AS cnt
FROM raw_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Duplicate checks
select * from raw_order_reviews where review_id in (select review_id 
FROM raw_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1);

SELECT order_id, COUNT(*) AS cnt
FROM raw_order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 9 Geo-location

-- Null/Blank checks
SELECT
	SUM(geolocation_zip_code_prefix='' or geolocation_zip_code_prefix is null),
	SUM(geolocation_lat='' or geolocation_lat is null),
	SUM(geolocation_lng='' or geolocation_lng is null),
	SUM(geolocation_city='' or geolocation_city is null),
	SUM(geolocation_state='' or geolocation_state is null)
FROM raw_geolocation;

-- Duplicate checks
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    count(*)
FROM raw_geolocation
GROUP BY geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) >1;

-- potential primary key duplicate checks
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    count(*)
FROM raw_geolocation
GROUP BY geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) >1;


SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    count(*)
FROM raw_geolocation
GROUP BY geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng
HAVING COUNT(*) >1;

/* 
We happen to find multiple geolocation_lat and geolocation_lng values for zip_code_prefix we can average 
these values to make it one prefix per row grain
*/

SELECT geolocation_city, COUNT(*) AS cnt
FROM raw_geolocation
GROUP BY geolocation_city
ORDER BY cnt desc;

-- unique zip prefixes
SELECT COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_prefixes
FROM raw_geolocation;

-- Number of rows per zip prefix
SELECT 
	geolocation_zip_code_prefix,
	count(*)
FROM raw_geolocation
GROUP BY geolocation_zip_code_prefix
ORDER BY count(*) desc;


