DROP DATABASE IF EXISTS olist_db;
CREATE DATABASE Olist_db;
USE Olist_db;

-- Customers
DROP TABLE IF EXISTS raw_customers;
CREATE TABLE raw_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(20),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

-- Sellers
DROP TABLE IF EXISTS raw_sellers;
CREATE TABLE raw_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(20),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

-- Products
DROP TABLE IF EXISTS raw_products;
CREATE TABLE raw_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght VARCHAR(20),
    product_description_lenght VARCHAR(20),
    product_photos_qty VARCHAR(20),
    product_weight_g VARCHAR(20),
    product_length_cm VARCHAR(20),
    product_height_cm VARCHAR(20),
    product_width_cm VARCHAR(20)
);

-- Category Translation
DROP TABLE IF EXISTS raw_category_translation;
CREATE TABLE raw_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

-- Orders
DROP TABLE IF EXISTS raw_orders;
CREATE TABLE raw_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp VARCHAR(30),
    order_approved_at VARCHAR(30),
    order_delivered_carrier_date VARCHAR(30),
    order_delivered_customer_date VARCHAR(30),
    order_estimated_delivery_date VARCHAR(30)
);

-- Order Items
DROP TABLE IF EXISTS raw_order_items;
CREATE TABLE raw_order_items (
    order_id VARCHAR(50),
    order_item_id VARCHAR(20),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date VARCHAR(30),
    price VARCHAR(20),
    freight_value VARCHAR(20)
);

-- Order Payments
DROP TABLE IF EXISTS raw_order_payments;
CREATE TABLE raw_order_payments (
    order_id VARCHAR(50),
    payment_sequential VARCHAR(20),
    payment_type VARCHAR(30),
    payment_installments VARCHAR(20),
    payment_value VARCHAR(20)
);

-- Order Reviews
DROP TABLE IF EXISTS raw_order_reviews;
CREATE TABLE raw_order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score VARCHAR(20),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date VARCHAR(80),
    review_answer_timestamp VARCHAR(30)
);

-- Geolocation
DROP TABLE IF EXISTS raw_geolocation;
CREATE TABLE raw_geolocation (
    geolocation_zip_code_prefix VARCHAR(20),
    geolocation_lat VARCHAR(30),
    geolocation_lng VARCHAR(30),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);