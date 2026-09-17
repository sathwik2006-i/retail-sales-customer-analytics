/* ============================================================
   Retail Sales & Customer Analytics — SQL Analysis
   Dataset: UCI Online Retail II
   Engine: MySQL 8.0
   ============================================================ */

-- ------------------------------------------------------------
-- STEP 1: Create database and raw table (all-text columns to
-- safely absorb messy source data, incl. cancelled invoices
-- like "C489434" which break numeric types)
-- ------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS retail_analytics;
USE retail_analytics;

DROP TABLE IF EXISTS retail_transactions_raw;

CREATE TABLE retail_transactions_raw (
    Invoice      VARCHAR(20),
    StockCode    VARCHAR(20),
    Description  VARCHAR(255),
    Quantity     VARCHAR(20),
    InvoiceDate  VARCHAR(50),
    Price        VARCHAR(20),
    `Customer ID` VARCHAR(20),
    Country      VARCHAR(50)
);

-- ------------------------------------------------------------
-- STEP 2: Bulk load via command line (much faster than GUI
-- import wizard — ~1M rows in under 20 seconds vs 2+ hours)
-- ------------------------------------------------------------
-- Run from mysql CLI:
--   mysql --local-infile=1 -u root -p
--   SET GLOBAL local_infile = 1;
--   USE retail_analytics;
--   LOAD DATA LOCAL INFILE 'path/to/online_retail_ii.csv'
--   INTO TABLE retail_transactions_raw
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--   LINES TERMINATED BY '\n'
--   IGNORE 1 ROWS;

-- ------------------------------------------------------------
-- STEP 3: Data quality checks
-- ------------------------------------------------------------
SELECT
    SUM(CASE WHEN `Customer ID` IS NULL OR `Customer ID` = '' THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN Invoice IS NULL OR Invoice = '' THEN 1 ELSE 0 END) AS null_invoice,
    SUM(CASE WHEN CAST(Quantity AS SIGNED) <= 0 THEN 1 ELSE 0 END) AS non_positive_qty,
    SUM(CASE WHEN CAST(Price AS DECIMAL(10,2)) <= 0 THEN 1 ELSE 0 END) AS non_positive_price,
    COUNT(*) AS total_rows
FROM retail_transactions_raw;
-- Result: 243,007 null customer IDs | 22,950 bad qty | 6,225 bad price | 1,067,371 total rows

SELECT COUNT(*) AS cancelled_orders
FROM retail_transactions_raw
WHERE Invoice LIKE 'C%';
-- Result: 19,494 cancelled orders

-- ------------------------------------------------------------
-- STEP 4: Clean transactions view
-- Removes: null customer IDs, cancellations, non-positive
-- quantity/price. Casts types properly for analysis.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS clean_transactions;

CREATE VIEW clean_transactions AS
SELECT
    Invoice AS invoice_no,
    StockCode AS stock_code,
    Description AS description,
    CAST(Quantity AS SIGNED) AS quantity,
    STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s') AS invoice_date,
    CAST(Price AS DECIMAL(10,2)) AS unit_price,
    CAST(CAST(`Customer ID` AS DECIMAL(10,1)) AS UNSIGNED) AS customer_id,
    Country AS country,
    (CAST(Quantity AS SIGNED) * CAST(Price AS DECIMAL(10,2))) AS revenue
FROM retail_transactions_raw
WHERE `Customer ID` IS NOT NULL
  AND `Customer ID` != ''
  AND CAST(Quantity AS SIGNED) > 0
  AND CAST(Price AS DECIMAL(10,2)) > 0
  AND Invoice NOT LIKE 'C%';
-- Result: 805,531 clean rows (75.5% of raw data retained)

-- ------------------------------------------------------------
-- STEP 5: Business analysis queries
-- ------------------------------------------------------------

-- 5a. Monthly revenue trend (note: 'year_month' is a MySQL
-- reserved-adjacent alias — renamed to 'order_month' to avoid
-- a syntax error)
SELECT
    DATE_FORMAT(invoice_date, '%Y-%m') AS order_month,
    ROUND(SUM(revenue), 2) AS monthly_revenue,
    COUNT(DISTINCT invoice_no) AS num_orders
FROM clean_transactions
GROUP BY order_month
ORDER BY order_month;

-- 5b. Revenue by country
SELECT
    country,
    ROUND(SUM(revenue), 2) AS total_revenue,
    COUNT(DISTINCT customer_id) AS num_customers
FROM clean_transactions
GROUP BY country
ORDER BY total_revenue DESC;
-- Result: UK = £14.72M (97% of revenue) from 5,350 customers — highly UK-concentrated

-- 5c. Top 10 products by revenue
SELECT
    stock_code,
    description,
    ROUND(SUM(revenue), 2) AS product_revenue,
    SUM(quantity) AS units_sold
FROM clean_transactions
GROUP BY stock_code, description
ORDER BY product_revenue DESC
LIMIT 10;
-- Result: "REGENCY CAKESTAND 3 TIER" tops revenue (£286K) despite lower unit sales
-- than "WHITE HANGING HEART T-LIGHT HOLDER" (93,640 units) — different price tiers

-- 5d. Top 10 customers by revenue
SELECT
    customer_id,
    ROUND(SUM(revenue), 2) AS customer_revenue,
    COUNT(DISTINCT invoice_no) AS num_orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
FROM clean_transactions
GROUP BY customer_id
ORDER BY customer_revenue DESC
LIMIT 10;
-- Result: Customer 16446 — only 2 orders but £168K revenue (avg order £84,236)
-- — clear wholesale-buyer outlier

-- 5e. Repeat purchase rate
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT invoice_no) AS order_count
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;
-- Result: 72.39% repeat purchase rate (4,255 of 5,878 customers)
