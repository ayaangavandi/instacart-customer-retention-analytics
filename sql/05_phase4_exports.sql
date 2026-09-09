-- ============================================================
-- Instacart Project — Phase 4 Data Exports (run in MySQL, export each to CSV)
-- ============================================================
USE instacart;

-- ============================================================
-- EXPORT 1: customer_features.csv
-- One row per user — this feeds the customer segmentation script.
-- In MySQL Workbench: run this, then right-click results grid -> Export -> CSV
-- Save as: instacart_project/data/customer_features.csv
-- ============================================================
SELECT
  o.user_id,
  COUNT(DISTINCT o.order_id) AS total_orders,
  ROUND(AVG(o.days_since_prior_order), 2) AS avg_days_between_orders,
  ROUND(AVG(op_counts.item_count), 2) AS avg_basket_size,
  ROUND(100.0 * SUM(op_counts.reordered_count) / SUM(op_counts.item_count), 2) AS reorder_rate_pct,
  SUM(op_counts.item_count) AS total_items_purchased
FROM orders o
JOIN (
    SELECT order_id, COUNT(*) AS item_count, SUM(reordered) AS reordered_count
    FROM order_products_prior
    GROUP BY order_id
) op_counts ON o.order_id = op_counts.order_id
WHERE o.eval_set = 'prior'
GROUP BY o.user_id;


-- ============================================================
-- EXPORT 2: basket_data.csv
-- order_id + product_name, restricted to the top 30 best-selling products
-- (keeps the basket matrix small enough to run on a laptop).
-- Save as: instacart_project/data/basket_data.csv
-- ============================================================
SELECT op.order_id, p.product_name
FROM order_products_prior op
JOIN products p ON op.product_id = p.product_id
WHERE op.product_id IN (
    SELECT product_id FROM (
        SELECT product_id, COUNT(*) AS cnt
        FROM order_products_prior
        GROUP BY product_id
        ORDER BY cnt DESC
        LIMIT 30
    ) top_products
);
