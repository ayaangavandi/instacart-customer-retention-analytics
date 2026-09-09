-- ============================================================
-- Instacart Project — Data Quality Checks (MySQL)
-- Run these after loading data, before any analysis.
-- Expected results are noted as comments — compare your output against them.
-- ============================================================
USE instacart;

-- 1. eval_set distribution — confirms 3 groups: prior / train / test
-- Expected: prior=3,214,874 (206,209 users) | train=131,209 | test=75,000
SELECT eval_set, COUNT(*) AS order_count, COUNT(DISTINCT user_id) AS distinct_users
FROM orders
GROUP BY eval_set;

-- 2. NULL check on days_since_prior_order — should equal orders where order_number = 1
-- Expected: both = 206,209
SELECT
  (SELECT COUNT(*) FROM orders WHERE days_since_prior_order IS NULL) AS null_days_count,
  (SELECT COUNT(*) FROM orders WHERE order_number = 1) AS first_order_count;

-- 3. Range checks — day of week and hour should be within valid bounds
-- Expected: dow 0-6, hour 0-23
SELECT
  MIN(order_dow) AS min_dow, MAX(order_dow) AS max_dow,
  MIN(order_hour_of_day) AS min_hour, MAX(order_hour_of_day) AS max_hour
FROM orders;

-- 4. days_since_prior_order distribution — look for the top-code spike at 30
-- Expected: big spike at 30.0 relative to 29.0 (top-coding, not organic)
SELECT days_since_prior_order, COUNT(*) AS cnt
FROM orders
WHERE days_since_prior_order IN (28, 29, 30)
GROUP BY days_since_prior_order
ORDER BY days_since_prior_order;

-- 5. Duplicate (order_id, product_id) pairs in order_products_prior
-- Expected: 0 rows returned
SELECT order_id, product_id, COUNT(*) AS cnt
FROM order_products_prior
GROUP BY order_id, product_id
HAVING cnt > 1
LIMIT 10;

-- 6. Orphan check — order_products referencing a product_id that doesn't exist
-- Expected: 0
SELECT COUNT(*) AS orphan_products
FROM order_products_prior op
LEFT JOIN products p ON op.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 7. Orphan check — order_products referencing an order_id that doesn't exist
-- Expected: 0
SELECT COUNT(*) AS orphan_orders
FROM order_products_prior op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 8. Products missing aisle/department mapping
-- Expected: 0
SELECT COUNT(*) AS missing_mapping
FROM products
WHERE aisle_id IS NULL OR department_id IS NULL;

-- 9. reordered flag values — should only ever be 0 or 1
-- Expected: only rows for 0 and 1 appear
SELECT reordered, COUNT(*) AS cnt
FROM order_products_prior
GROUP BY reordered;

-- 10. Orders per user (min/max/avg) — confirms the 4-order minimum selection bias
-- Expected: min=4, max=100, avg~16.6
SELECT MIN(order_cnt) AS min_orders, MAX(order_cnt) AS max_orders, AVG(order_cnt) AS avg_orders
FROM (
  SELECT user_id, COUNT(*) AS order_cnt
  FROM orders
  GROUP BY user_id
) t;

-- 11. Basket size (items per order) distribution
-- Expected: min=1, max=145, avg~10.1
SELECT MIN(basket_size) AS min_basket, MAX(basket_size) AS max_basket, AVG(basket_size) AS avg_basket
FROM (
  SELECT order_id, COUNT(*) AS basket_size
  FROM order_products_prior
  GROUP BY order_id
) t;

-- 12. Confirm test orders truly have zero product data anywhere
-- Expected: 0 for both
SELECT
  (SELECT COUNT(*) FROM order_products_prior op JOIN orders o ON op.order_id=o.order_id WHERE o.eval_set='test') AS test_in_prior,
  (SELECT COUNT(*) FROM order_products_train op JOIN orders o ON op.order_id=o.order_id WHERE o.eval_set='test') AS test_in_train;
