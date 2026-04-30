USE olist_db;
-- loading customer dataset
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_customers_dataset.csv'
INTO TABLE raw_customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading seller dataset
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_sellers_dataset.csv'
INTO TABLE raw_sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading product dataset
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_products_dataset.csv'
INTO TABLE raw_products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading Category Translation
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/product_category_name_translation.csv'
INTO TABLE raw_category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading Order
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_orders_dataset.csv'
INTO TABLE raw_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading Order_items 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_order_items_dataset.csv'
INTO TABLE raw_order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading Order_payments
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_order_payments_dataset.csv'
INTO TABLE raw_order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- loading Reviews
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_order_reviews_dataset.csv'
INTO TABLE raw_order_reviews
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp);

-- loading geolocations
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.3/Data/olist_db/olist_geolocation_dataset.csv'
INTO TABLE raw_geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;