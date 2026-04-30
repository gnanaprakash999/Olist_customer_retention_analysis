E-commerce Customer Retention & Churn Analysis (SQL Project)


Project Overview-

This project explores Olist revenue, customer behavior, revenue trends, and retention patterns using the Olist Brazilian e-commerce dataset.  
The main goal was to understand how customers interact with the platform, where drop-offs happen, and why users don’t return after their first purchase.

The entire workflow was built using SQL, starting from raw data ingestion to final analysis.


Objective-

- Analyze revenue and order trends over time  
- Understand customer growth and activity  
- Identify drop-offs in the order lifecycle (funnel)  
- Measure retention using cohort analysis  
- Quantify churn and understand its causes  
- Segment customers based on behavior and spend  


Dataset-

The dataset contains e-commerce transactions from Brazil, including:

- Customers  
- Orders  
- Order items  
- Payments  
- Products  
- Reviews  
- Geolocation data  


Workflow-

1. Data ingestion (CSV → MySQL)  
2. Raw data checks (nulls, blanks, duplicates, anomalies)  
3. Data cleaning and transformation  
4. Analysis using SQL  
5. Extracting insights  


Data Cleaning Highlights-

- Converted blank values to NULL using `NULLIF`  
- Standardized text fields using `TRIM`, `LOWER`, `UPPER`  
- Parsed timestamps using `STR_TO_DATE`  
- Converted numeric fields (price, payments) to proper types  
- Removed duplicate reviews using `ROW_NUMBER()`  
- Kept missing product categories as NULL instead of forcing values  



Key Analysis Performed-

- Revenue trend analysis  
- Customer growth analysis  
- Funnel analysis (Placed → Approved → Delivered)  
- Cohort retention analysis  
- Churn analysis  
- Customer segmentation  



Key Insights-

- Revenue grew strongly through 2017, mainly due to more orders rather than higher spending per order  
- Around 90% of customers churn within 90 days  
- Most churn comes from users who placed only one order  
- Funnel conversion is strong, so operations are not the main issue  
- The bigger problem is getting customers to come back  
- Repeat customers are fewer but tend to spend more  



Business Implications-

- The biggest drop happens after the first order, so improving early experience is important  
- Retention strategies (offers, re-engagement) could have a big impact  
- The focus should shift from just acquiring users to keeping them  



Skills Demonstrated-

- SQL (CTEs, joins, aggregations, window functions)  
- Data cleaning and transformation  
- Cohort and retention analysis  
- Funnel analysis  
- Churn analysis  
- Translating data into business insights  



Project Structure-

- 01_Olist_database_setup.sql
- 02_Olist_load_raw_data.sql
- 03_Olist_raw_data_validation.sql
- 04_Olist_lean_tables.sql
- 05_Olist_data_modelling.sql
- 06_Olist_data_analysis

Final Note-

This project focuses on using SQL to explore customer behavior and understand where the business is losing users
