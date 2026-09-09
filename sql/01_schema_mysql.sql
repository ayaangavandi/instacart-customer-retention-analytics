-- ============================================================
-- Instacart Project — MySQL Schema (DDL)
-- Run this first in MySQL Workbench / CLI to create the database structure
-- ============================================================

CREATE DATABASE IF NOT EXISTS instacart;
USE instacart;

DROP TABLE IF EXISTS order_products_prior;
DROP TABLE IF EXISTS order_products_train;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS aisles;
DROP TABLE IF EXISTS departments;

CREATE TABLE aisles (
    aisle_id   INT PRIMARY KEY,
    aisle      VARCHAR(100)
);

CREATE TABLE departments (
    department_id   INT PRIMARY KEY,
    department      VARCHAR(100)
);

CREATE TABLE products (
    product_id      INT PRIMARY KEY,
    product_name    VARCHAR(300),
    aisle_id        INT,
    department_id   INT,
    FOREIGN KEY (aisle_id) REFERENCES aisles(aisle_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE orders (
    order_id                  INT PRIMARY KEY,
    user_id                   INT NOT NULL,
    eval_set                  VARCHAR(10) NOT NULL,   -- 'prior' or 'train'
    order_number              INT NOT NULL,
    order_dow                 TINYINT NOT NULL,       -- 0=Sunday ... 6=Saturday
    order_hour_of_day         TINYINT NOT NULL,
    days_since_prior_order    DECIMAL(4,1)            -- NULL for a user's very first order
);

CREATE TABLE order_products_prior (
    order_id            INT NOT NULL,
    product_id           INT NOT NULL,
    add_to_cart_order    INT,
    reordered            TINYINT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE order_products_train (
    order_id            INT NOT NULL,
    product_id           INT NOT NULL,
    add_to_cart_order    INT,
    reordered            TINYINT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Indexes to speed up the analysis queries we'll run later
CREATE INDEX idx_orders_user       ON orders(user_id);
CREATE INDEX idx_orders_eval       ON orders(eval_set);
CREATE INDEX idx_opp_product       ON order_products_prior(product_id);
CREATE INDEX idx_opt_product       ON order_products_train(product_id);
CREATE INDEX idx_products_aisle    ON products(aisle_id);
CREATE INDEX idx_products_dept     ON products(department_id);
