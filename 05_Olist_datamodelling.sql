use olist_db;

-- dim_date
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_name VARCHAR(20),
    week_of_year INT,
    is_weekend VARCHAR(3)
);

INSERT INTO dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_name,
    week_of_year,
    is_weekend
)
SELECT DISTINCT
    CAST(DATE_FORMAT(DATE(order_purchase_time), '%Y%m%d') AS UNSIGNED) AS date_key,
    DATE(order_purchase_time) AS full_date,
    YEAR(DATE(order_purchase_time)) AS year,
    QUARTER(DATE(order_purchase_time)) AS quarter,
    MONTH(DATE(order_purchase_time)) AS month,
    MONTHNAME(DATE(order_purchase_time)) AS month_name,
    DAY(DATE(order_purchase_time)) AS day,
    DAYNAME(DATE(order_purchase_time)) AS day_name,
    WEEK(DATE(order_purchase_time)) AS week_of_year,
    CASE
        WHEN DAYOFWEEK(DATE(order_purchase_time)) IN (1, 7) THEN 'Yes'
        ELSE 'No'
    END AS is_weekend
FROM clean_orders;

-- Sample check
SELECT *
FROM dim_date
ORDER BY full_date
LIMIT 10;

-- Duplicate check
SELECT full_date, COUNT(*)
FROM dim_date
GROUP BY full_date
HAVING COUNT(*) > 1;

-- dim_customer
DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

INSERT INTO dim_customer (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY customer_id
        ) AS rn
    FROM clean_customers
    WHERE customer_id IS NOT NULL
) ranked
WHERE rn = 1;

-- Sample check
select * from dim_customer
limit 10;

-- Duplicate check
SELECT customer_id, COUNT(*)
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- dim_product
CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);

INSERT INTO dim_product (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT DISTINCT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM clean_products
WHERE product_id IS NOT NULL;

-- Sample check
SELECT * FROM dim_product LIMIT 10;

-- Duplicate check
SELECT product_id, COUNT(*)
FROM dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;

-- dim_sellers
DROP TABLE IF EXISTS dim_seller;

CREATE TABLE dim_seller (
    seller_key INT AUTO_INCREMENT PRIMARY KEY,
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(20),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

INSERT INTO dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM clean_sellers
WHERE seller_id IS NOT NULL;

-- Sample check
SELECT * FROM dim_seller LIMIT 10;

-- Duplicate check
SELECT seller_id, COUNT(*)
FROM dim_seller
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- Fact_order_item

CREATE TABLE fact_order_items (
    fact_order_item_key INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    date_key INT NOT NULL,
    customer_key INT NOT NULL,
    seller_key INT NOT NULL,
    product_key INT NOT NULL,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);
    
CREATE INDEX idx_clean_order_items_order_id ON clean_order_items(order_id);
CREATE INDEX idx_clean_order_items_seller_id ON clean_order_items(seller_id);
CREATE INDEX idx_clean_order_items_product_id ON clean_order_items(product_id);

CREATE INDEX idx_clean_orders_order_id ON clean_orders(order_id);
CREATE INDEX idx_clean_orders_customer_id ON clean_orders(customer_id);
CREATE INDEX idx_clean_orders_purchase_ts ON clean_orders(order_purchase_time);

CREATE INDEX idx_dim_date_full_date ON dim_date(full_date);
CREATE INDEX idx_dim_customer_customer_id ON dim_customer(customer_id);
CREATE INDEX idx_dim_seller_seller_id ON dim_seller(seller_id);
CREATE INDEX idx_dim_product_product_id ON dim_product(product_id);


INSERT INTO fact_order_items (
    order_id,
    order_item_id,
    date_key,
    customer_key,
    seller_key,
    product_key,
    price,
    freight_value
)
SELECT
    oi.order_id,
    oi.order_item_id,
    dd.date_key,
    dc.customer_key,
    ds.seller_key,
    dp.product_key,
    oi.price,
    oi.freight_value
FROM clean_order_items oi
JOIN clean_orders o
    ON oi.order_id = o.order_id
JOIN dim_date dd
    ON DATE(o.order_purchase_time) = dd.full_date
JOIN dim_customer dc
    ON o.customer_id = dc.customer_id
JOIN dim_seller ds
    ON oi.seller_id = ds.seller_id
JOIN dim_product dp
    ON oi.product_id = dp.product_id;
    
-- Row_count check

SELECT COUNT(*) AS source_rows
FROM clean_order_items;

SELECT COUNT(*) AS fact_rows
FROM fact_order_items;

-- Duplicate check
SELECT 
    order_id,
    order_item_id,
    COUNT(*) AS cnt
FROM fact_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
