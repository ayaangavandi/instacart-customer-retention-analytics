-- ============================================================
-- Instacart Project — Phase 3: Exploratory Analysis (MySQL)
-- Each section maps to a Key Business Question from the BRD.
-- Run each block, save the output (screenshot or export CSV) —
-- you'll need these results for the dashboard in Phase 6.
-- ============================================================
USE instacart;

-- ============================================================
-- A. DATASET OVERVIEW (headline numbers for your report intro)
-- ============================================================
SELECT
  (SELECT COUNT(DISTINCT user_id) FROM orders) AS total_users,
  (SELECT COUNT(*) FROM orders WHERE eval_set IN ('prior','train')) AS total_orders_analyzed,
  (SELECT COUNT(DISTINCT product_id) FROM products) AS total_products,
  (SELECT COUNT(DISTINCT department_id) FROM departments) AS total_departments,
  (SELECT COUNT(DISTINCT aisle_id) FROM aisles) AS total_aisles,
  (SELECT ROUND(AVG(basket_size),2) FROM (
      SELECT order_id, COUNT(*) basket_size FROM order_products_prior GROUP BY order_id
  ) t) AS avg_basket_size;


-- ============================================================
-- B. ORDER TIMING PATTERNS (BRD Q5 — operational planning)
-- ============================================================

-- B1. Orders by day of week
SELECT order_dow, COUNT(*) AS order_count
FROM orders
WHERE eval_set IN ('prior','train')
GROUP BY order_dow
ORDER BY order_dow;

-- B2. Orders by hour of day
SELECT order_hour_of_day, COUNT(*) AS order_count
FROM orders
WHERE eval_set IN ('prior','train')
GROUP BY order_hour_of_day
ORDER BY order_hour_of_day;

-- B3. Day-of-week x hour heatmap data (feed this straight into a Power BI matrix/heatmap)
SELECT order_dow, order_hour_of_day, COUNT(*) AS order_count
FROM orders
WHERE eval_set IN ('prior','train')
GROUP BY order_dow, order_hour_of_day
ORDER BY order_dow, order_hour_of_day;


-- ============================================================
-- C. ORDER FREQUENCY / GAP BETWEEN ORDERS (BRD Q2)
-- ============================================================

-- C1. Distribution of days_since_prior_order (excluding first orders and the 30-day cap noise)
SELECT days_since_prior_order, COUNT(*) AS order_count
FROM orders
WHERE days_since_prior_order IS NOT NULL
GROUP BY days_since_prior_order
ORDER BY days_since_prior_order;

-- C2. Median days between orders (MySQL 8+ has no native MEDIAN() — this is the standard workaround)
SELECT AVG(days_since_prior_order) AS median_days_since_prior_order
FROM (
  SELECT
    days_since_prior_order,
    ROW_NUMBER() OVER (ORDER BY days_since_prior_order) AS rn,
    COUNT(*) OVER () AS total_cnt
  FROM orders
  WHERE days_since_prior_order IS NOT NULL
) ranked
WHERE rn IN (FLOOR((total_cnt + 1) / 2), CEIL((total_cnt + 1) / 2));

-- C3. % of orders at the 30-day cap (report this alongside any average — per Data Quality Report)
SELECT
  SUM(CASE WHEN days_since_prior_order = 30 THEN 1 ELSE 0 END) AS capped_at_30,
  COUNT(*) AS total_non_null,
  ROUND(100.0 * SUM(CASE WHEN days_since_prior_order = 30 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_capped
FROM orders
WHERE days_since_prior_order IS NOT NULL;


-- ============================================================
-- D. RETENTION / ORDER SEQUENCE CURVE (BRD Q1 — core business question)
-- ============================================================

-- D1. How many distinct users reached each order_number? (the retention curve itself)
-- Plot order_number (x-axis) vs users_reaching (y-axis) in Power BI — this IS the retention curve.
SELECT order_number, COUNT(DISTINCT user_id) AS users_reaching_this_order
FROM orders
WHERE eval_set IN ('prior','train')
GROUP BY order_number
ORDER BY order_number;

-- D2. Step-over-step retention rate: of users who reached order N, what % reached order N+1?
-- This finds the steepest drop-off point.
WITH order_counts AS (
  SELECT order_number, COUNT(DISTINCT user_id) AS users_reaching
  FROM orders
  WHERE eval_set IN ('prior','train')
  GROUP BY order_number
)
SELECT
  a.order_number,
  a.users_reaching AS users_at_this_order,
  b.users_reaching AS users_at_next_order,
  ROUND(100.0 * b.users_reaching / a.users_reaching, 2) AS pct_continuing_to_next
FROM order_counts a
LEFT JOIN order_counts b ON b.order_number = a.order_number + 1
ORDER BY a.order_number;

-- D3. Distribution of "max order_number reached" per user — i.e. how many orders does a typical
-- user place in total? (their final observed order_number)
SELECT max_order_number, COUNT(*) AS num_users
FROM (
  SELECT user_id, MAX(order_number) AS max_order_number
  FROM orders
  GROUP BY user_id
) t
GROUP BY max_order_number
ORDER BY max_order_number;


-- ============================================================
-- E. REORDER RATE — OVERALL & BY CATEGORY (BRD Q3)
-- ============================================================

-- E1. Overall reorder rate (across all prior order line-items)
SELECT
  SUM(reordered) AS reordered_items,
  COUNT(*) AS total_items,
  ROUND(100.0 * SUM(reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_products_prior;

-- E2. Reorder rate by department (which departments drive loyalty vs. one-time trial)
SELECT
  d.department,
  COUNT(*) AS total_items_ordered,
  SUM(op.reordered) AS reordered_items,
  ROUND(100.0 * SUM(op.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY reorder_rate_pct DESC;

-- E3. Reorder rate by aisle — top 15 highest (loyalty/staple aisles)
SELECT
  a.aisle,
  COUNT(*) AS total_items_ordered,
  ROUND(100.0 * SUM(op.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
JOIN aisles a ON p.aisle_id = a.aisle_id
GROUP BY a.aisle
HAVING total_items_ordered >= 1000   -- minimum sample size, per Metrics Dictionary rule
ORDER BY reorder_rate_pct DESC
LIMIT 15;

-- E4. Reorder rate by aisle — bottom 15 lowest (one-off trial aisles)
SELECT
  a.aisle,
  COUNT(*) AS total_items_ordered,
  ROUND(100.0 * SUM(op.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
JOIN aisles a ON p.aisle_id = a.aisle_id
GROUP BY a.aisle
HAVING total_items_ordered >= 1000
ORDER BY reorder_rate_pct ASC
LIMIT 15;

-- E5. Top 20 products by total order volume (overall popularity)
SELECT
  p.product_name,
  COUNT(*) AS times_ordered,
  ROUND(100.0 * SUM(op.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
ORDER BY times_ordered DESC
LIMIT 20;

-- E6. Top 20 "most loyal" products (highest reorder rate, min 500 orders to avoid noise)
SELECT
  p.product_name,
  COUNT(*) AS times_ordered,
  ROUND(100.0 * SUM(op.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
HAVING times_ordered >= 500
ORDER BY reorder_rate_pct DESC
LIMIT 20;


-- ============================================================
-- F. BASKET SIZE ANALYSIS
-- ============================================================

-- F1. Basket size distribution (histogram buckets)
SELECT
  CASE
    WHEN basket_size BETWEEN 1 AND 5 THEN '1-5'
    WHEN basket_size BETWEEN 6 AND 10 THEN '6-10'
    WHEN basket_size BETWEEN 11 AND 20 THEN '11-20'
    WHEN basket_size BETWEEN 21 AND 40 THEN '21-40'
    ELSE '41+'
  END AS basket_size_bucket,
  COUNT(*) AS num_orders
FROM (
  SELECT order_id, COUNT(*) AS basket_size
  FROM order_products_prior
  GROUP BY order_id
) t
GROUP BY basket_size_bucket
ORDER BY MIN(basket_size);

-- F2. Average basket size by day of week and hour (does basket size change with timing?)
SELECT
  o.order_dow,
  ROUND(AVG(item_count), 2) AS avg_basket_size
FROM orders o
JOIN (
  SELECT order_id, COUNT(*) AS item_count
  FROM order_products_prior
  GROUP BY order_id
) items ON o.order_id = items.order_id
GROUP BY o.order_dow
ORDER BY o.order_dow;


-- ============================================================
-- G. DEPARTMENT-LEVEL SALES SHARE (merchandising view)
-- ============================================================
SELECT
  d.department,
  COUNT(*) AS total_items_ordered,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_products_prior), 2) AS pct_of_all_items
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY total_items_ordered DESC;
