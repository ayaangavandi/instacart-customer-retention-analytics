-- ============================================================
-- Instacart Project — Load CSVs into MySQL
-- ============================================================
-- IMPORTANT SETUP (do this once, before running LOAD DATA):
--
-- 1. Find MySQL's secure file directory:
--      SHOW VARIABLES LIKE 'secure_file_priv';
--    This shows the ONLY folder MySQL is allowed to read files from
--    with LOAD DATA INFILE. Copy your 6 CSVs into that folder.
--    (On Windows this is often: C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/)
--
-- 2. If secure_file_priv is empty/disabled and you get permission errors,
--    use LOAD DATA LOCAL INFILE instead (see commented alternative below),
--    and make sure local_infile is enabled:
--      SET GLOBAL local_infile = 1;
--    (and in MySQL Workbench: Edit > Preferences > SQL Editor > check
--    "Enable LOAD LOCAL INFILE")
--
-- Replace the file paths below with wherever your CSVs actually sit.
-- ============================================================

USE instacart;

-- Disable checks temporarily for faster bulk load
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

-- --- aisles ---
LOAD DATA INFILE '/path/to/secure_file_priv/aisles.csv'
INTO TABLE aisles
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(aisle_id, aisle);

-- --- departments ---
LOAD DATA INFILE '/path/to/secure_file_priv/departments.csv'
INTO TABLE departments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(department_id, department);

-- --- products ---
LOAD DATA INFILE '/path/to/secure_file_priv/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, aisle_id, department_id);

-- --- orders ---
-- Note: days_since_prior_order is blank for a user's first order.
-- Use @var + NULLIF so blank strings become real SQL NULLs, not 0.
LOAD DATA INFILE '/path/to/secure_file_priv/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, @dspo)
SET days_since_prior_order = NULLIF(@dspo, '');

-- --- order_products__prior (32.4M rows — this will take a few minutes) ---
LOAD DATA INFILE '/path/to/secure_file_priv/order_products__prior.csv'
INTO TABLE order_products_prior
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, add_to_cart_order, reordered);

-- --- order_products__train ---
LOAD DATA INFILE '/path/to/secure_file_priv/order_products__train.csv'
INTO TABLE order_products_train
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, add_to_cart_order, reordered);

SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

-- ============================================================
-- ALTERNATIVE if secure_file_priv path is impractical:
-- Use LOAD DATA LOCAL INFILE (reads from YOUR machine, not the server)
-- Just swap "LOAD DATA INFILE" -> "LOAD DATA LOCAL INFILE" in each
-- block above, and use your actual local CSV file paths.
-- ============================================================

-- ============================================================
-- Sanity check row counts after loading — should match:
-- aisles: 134 | departments: 21 | products: 49,688
-- orders: 3,421,083 | order_products_prior: 32,434,489 | order_products_train: 1,384,617
-- ============================================================
SELECT 'aisles' AS tbl, COUNT(*) AS row_count FROM aisles
UNION ALL SELECT 'departments', COUNT(*) FROM departments
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_products_prior', COUNT(*) FROM order_products_prior
UNION ALL SELECT 'order_products_train', COUNT(*) FROM order_products_train;
