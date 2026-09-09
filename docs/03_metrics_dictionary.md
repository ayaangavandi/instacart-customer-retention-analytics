# Metrics Dictionary

Every metric below states its exact formula, the table/columns it uses, and known caveats
(from the Data Quality Report) that affect interpretation.

---

### 1. Reorder Rate (overall)
**Definition:** Share of product line-items in an order that were previously ordered by that user.
**Formula:** `SUM(reordered) / COUNT(*)` over `order_products_prior` (+ `order_products_train` where noted)
**Caveat:** `reordered = 1` means the user ordered this product at least once before — it is a
line-item flag, not a product-level lifetime stat, unless aggregated by `product_id`.

### 2. Product-Level Reorder Rate
**Definition:** Of all times a specific product was ordered, what % were reorders (vs. first-time trials)?
**Formula:** `SUM(reordered) / COUNT(*) GROUP BY product_id`
**Use:** Identifies "loyalty" products (high reorder rate = staple items) vs. "trial" products
(low reorder rate = one-off purchases, possibly low satisfaction or low necessity).
**Minimum sample size rule:** Only report for products with ≥100 total orders, to avoid
small-sample noise (a product ordered twice with 1 reorder is not "50% reorder rate" material).

### 3. Order-to-Order Retention Rate (Cohort-based)
**Definition:** Of users who placed order N, what % went on to place order N+1?
**Formula:** `COUNT(DISTINCT user_id WHERE order_number = N+1) / COUNT(DISTINCT user_id WHERE order_number = N)`
**Use:** Builds a retention curve (order 1→2, 2→3, ... N→N+1) to find the biggest drop-off point.
**Caveat:** Since every user's dataset here already includes at least 4 orders (min order count
per user = 4, per Data Quality Report), this understates real-world first/second-order churn —
users who churned after 1–3 orders were excluded from this dataset entirely. This is stated
clearly as a limitation, not hidden.

### 4. Average Days Between Orders
**Definition:** Mean/median `days_since_prior_order`, excluding first orders (NULL) and treating
30 as a "30+" censored value.
**Formula:** `AVG(days_since_prior_order) WHERE days_since_prior_order IS NOT NULL`, reported
alongside `% of orders at the 30-day cap` so the censoring is visible, and median as a more
robust central measure.
**Caveat:** Do not report a single mean without the median and the % censored alongside it —
per Data Quality Report Finding 1, the true tail beyond 30 days is unknown.

### 5. Customer Segment (Behavioral, RFM-style)
**Definition:** Each user classified on 3 dimensions computed from `orders` + `order_products_prior`:
- **Frequency:** total number of orders placed (`order_number` max per user)
- **Recency proxy:** `days_since_prior_order` on their most recent prior order (lower = more recently active)
- **Reorder loyalty:** their personal reorder rate (`SUM(reordered)/COUNT(*)` across their own orders)
**Use:** Segments such as "frequent loyalists" (high frequency, high reorder rate) vs.
"frequent explorers" (high frequency, low reorder rate — always trying new products) vs.
"infrequent/at-risk" (low frequency, long gaps).
**Caveat:** No demographic or spend data exists — segments are purely behavioral, not tied to
customer value in dollars.

### 6. Basket Size
**Definition:** Number of distinct products in a single order.
**Formula:** `COUNT(product_id) GROUP BY order_id`

### 7. Product Affinity (Market Basket Analysis)
**Definition:** For product pairs frequently bought in the same order, calculated via:
- **Support:** `orders containing both A and B / total orders`
- **Confidence:** `orders containing both A and B / orders containing A`
- **Lift:** `confidence / (orders containing B / total orders)` — lift > 1 means the pair
  co-occurs more than random chance would predict.
**Use:** Cross-sell/bundling recommendations. Lift is the primary ranking metric (support and
confidence alone are biased toward very popular products like bananas).

### 8. Order Timing Distribution
**Definition:** Count/share of orders by `order_dow` (0–6) and `order_hour_of_day` (0–23).
**Caveat:** `order_dow` encoding (which day = 0) is not documented by the data source — we treat
it as relative/ordinal (day 0 through day 6 of the week) rather than assuming which real calendar
day it maps to, and note this assumption wherever the finding is presented.

---

## Metrics explicitly NOT calculated (and why)
- **Revenue / dollar value** — no price data exists in this dataset.
- **Customer lifetime value ($)** — requires revenue; not proxied without disclaimers.
- **True churn rate** — cannot know if a user churned or simply hasn't ordered again *yet*,
  since data is a snapshot in time, not an ongoing feed. We use "order gap" and "did they
  reach order N+1" as proxies, explicitly labeled as such.
