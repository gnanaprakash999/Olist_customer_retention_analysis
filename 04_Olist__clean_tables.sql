-- 1.clean_orders
DROP TABLE IF EXISTS clean_orders;
CREATE TABLE clean_orders AS
SELECT 
    TRIM(order_id) AS order_id,
    TRIM(customer_id) AS customer_id,
    LOWER(TRIM(order_status)) AS order_status,
    STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS order_purchase_time,
    STR_TO_DATE(NULLIF(order_approved_at, ''), '%Y-%m-%d %H:%i:%s') AS order_approved_at,
    STR_TO_DATE(NULLIF(order_delivered_carrier_date, ''), '%Y-%m-%d %H:%i:%s') AS carrier_date,
    STR_TO_DATE(NULLIF(order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') AS delivered_date,
    DATE(STR_TO_DATE(NULLIF(order_estimated_delivery_date,''), '%Y-%m-%d %H:%i:%s')) AS estimated_delivery_date
FROM raw_orders;

-- 2.clean_order_items
DROP TABLE IF EXISTS clean_order_items;
create table clean_order_items
select 
	trim(order_id) as order_id,
    cast(order_item_id as unsigned) as order_item_id,
    trim(product_id) as product_id,
    trim(seller_id) as seller_id,
    str_to_date(shipping_limit_date,'%Y-%m-%d %H:%i:%S') as shipping_limit_date,
    cast(price as decimal(10,2)) as price,
    cast(freight_value as decimal(10,2)) as freight_value
FROM raw_order_items;

-- 3.clean_order_payments
DROP TABLE IF EXISTS clean_order_payments;
CREATE TABLE clean_order_payments
select 
	trim(order_id) as order_id,
    cast(payment_sequential as unsigned) as payment_sequential,
    lower(trim(payment_type)) as payment_type,
    cast(payment_installments as unsigned) as payment_installments,
    cast(payment_value as decimal(10,2)) as payment_value
from raw_order_payments;

-- 4.clean_customers
DROP TABLE IF EXISTS clean_customers;
CREATE TABLE clean_customers AS 
SELECT 
	trim(customer_id) as customer_id,
    trim(customer_unique_id) as customer_unique_id,
	cast(customer_zip_code_prefix as unsigned) as customer_zip_code_prefix,
    trim(lower(customer_city)) as customer_city,
    trim(upper(customer_state)) as customer_state
FROM raw_customers;

-- 5.clean_category_transaltion
DROP TABLE IF EXISTS clean_category_translation;
CREATE TABLE clean_category_translation AS
SELECT
    TRIM(LOWER(product_category_name)) AS product_category_name,
    TRIM(LOWER(product_category_name_english)) AS product_category_name_english
FROM raw_category_translation;

-- 6.clean_product
DROP TABLE IF EXISTS clean_products;
CREATE TABLE clean_products AS
SELECT 
    TRIM(product_id) AS product_id,
    CASE
        WHEN product_category_name IS NULL
             OR TRIM(product_category_name) = ''
        THEN NULL
        ELSE TRIM(LOWER(product_category_name))
    END AS product_category_name,
    CAST(NULLIF(product_name_lenght, '') AS UNSIGNED) AS product_name_length,
    CAST(NULLIF(product_description_lenght, '') AS UNSIGNED) AS product_description_length,
    CAST(NULLIF(product_photos_qty, '') AS UNSIGNED) AS product_photos_qty,
    CAST(NULLIF(product_weight_g, '') AS UNSIGNED) AS product_weight_g,
    CAST(NULLIF(product_length_cm, '') AS UNSIGNED) AS product_length_cm,
    CAST(NULLIF(product_height_cm, '') AS UNSIGNED) AS product_height_cm,
    CAST(NULLIF(product_width_cm, '') AS UNSIGNED) AS product_width_cm
FROM raw_products;

-- 7.clean_sellers
DROP TABLE IF EXISTS clean_sellers;
CREATE TABLE clean_sellers AS
SELECT
    TRIM(seller_id) AS seller_id,
    CAST(NULLIF(seller_zip_code_prefix, '') AS UNSIGNED) AS seller_zip_code_prefix,
    TRIM(LOWER(seller_city)) AS seller_city,
    CASE
        WHEN seller_state IS NULL OR TRIM(seller_state) = '' THEN NULL
        ELSE TRIM(UPPER(seller_state))
    END AS seller_state
FROM raw_sellers;

-- 8.order_reviews
DROP TABLE IF EXISTS temp_reviews_clean;
CREATE TABLE temp_reviews_clean AS
SELECT
    TRIM(review_id) AS review_id,
    TRIM(order_id) AS order_id,
    CAST(NULLIF(review_score, '') AS UNSIGNED) AS review_score,
    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
    STR_TO_DATE(NULLIF(review_creation_date, ''), '%Y-%m-%d %H:%i:%s') AS review_creation_date,
    STR_TO_DATE(NULLIF(review_answer_timestamp, ''), '%Y-%m-%d %H:%i:%s') AS review_answer_timestamp
FROM raw_order_reviews;

DROP TABLE IF EXISTS clean_order_reviews;
CREATE TABLE clean_order_reviews AS
SELECT 
review_id,
order_id,
review_score,
review_comment_title,
review_comment_message,
review_creation_date,
review_answer_timestamp
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY review_id
               ORDER BY review_answer_timestamp DESC
           ) AS rn
    FROM temp_reviews_clean
) t
WHERE rn = 1;

-- 9.clean_geolocation
DROP TABLE IF EXISTS geo_stage;
CREATE TABLE geo_stage AS
SELECT
    geolocation_zip_code_prefix,
    CAST(geolocation_lat AS DECIMAL(10,6)) AS geolocation_lat,
    CAST(geolocation_lng AS DECIMAL(10,6)) AS geolocation_lng,
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        LOWER(geolocation_city),
                        '-', ' '
                    ),
                    '/', ' '
                ),
                '.', ''
            ),
            ',', ''
        )
    ) AS geolocation_city,
    UPPER(TRIM(geolocation_state)) AS geolocation_state
FROM raw_geolocation;

-- Ranking the most frequent city/zip
DROP TABLE IF EXISTS zip_city_ranked;
CREATE TABLE zip_city_ranked AS
SELECT *
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS city_count,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY COUNT(*) DESC, geolocation_state, geolocation_city
        ) AS rn
    FROM geo_stage
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
) t
WHERE rn = 1;

-- clean geolocation

CREATE TABLE clean_geolocation as
SELECT
	z.geolocation_zip_code_prefix,
	z.geolocation_city,
	z.geolocation_state,
    avg(g.geolocation_lat) as geolocation_lat,
    avg(g.geolocation_lng) as geolocation_lng
FROM zip_city_ranked z
JOIN geo_stage g 
	ON z.geolocation_zip_code_prefix = g.geolocation_zip_code_prefix
   AND z.geolocation_city = g.geolocation_city
   AND z.geolocation_state = g.geolocation_state
GROUP BY
    z.geolocation_zip_code_prefix,
    z.geolocation_city,
    z.geolocation_state;

-- Indexes
CREATE INDEX idx_orders_customer ON clean_orders(customer_id);
CREATE INDEX idx_items_product ON clean_order_items(product_id);
CREATE INDEX idx_items_seller ON clean_order_items(seller_id);