# Data Quality Report

## Summary
The dataset is structurally clean — no duplicate rows, no orphaned foreign keys, no invalid
category references. However, there are **3 important data constraints** that must be factored
into every downstream analysis. Ignoring these would produce misleading metrics.

---

### Finding 1: `days_since_prior_order` is top-coded at 30
- 369,323 orders (10.8% of all orders) show exactly `30.0` days since prior order, vs. only
  19,191 at 29 days — an unnatural spike.
- **Implication:** Instacart capped/truncated this field at 30 days. The true gap for these
  orders could be 30, 60, 90+ days. Any "average days between orders" metric will
  *understate* true churn gaps unless we treat 30 as "30+" rather than a precise value.
- **Action:** Flag these as censored in the metrics dictionary; use median/percentile views
  and a separate "30+" bucket in retention analysis rather than treating 30 as exact.

### Finding 2: Every user's *most recent* order is held out as `train` or `test` — and `test` orders have zero product data
- Each of the 206,209 users has exactly one order marked `train` (131,209 users) or `test`
  (75,000 users) — their latest order — with all earlier orders marked `prior`.
- `order_products_train.csv` gives us the actual items for the `train` group's latest order.
- **The `test` group's latest order has no product data anywhere in this dataset** (verified:
  0 matches in either order_products file). Only the order's *metadata* (day, hour, gap since
  prior) is known for test orders — not what was purchased.
- **Implication:** This was originally a Kaggle competition test set (product-level labels
  withheld for scoring). For our purposes:
  - Use `prior` + `train` data for any analysis needing product-level detail (reorder rates,
    basket analysis, product affinity).
  - `test` orders can still be used for order-timing analysis (day/hour/gap) since that metadata
    exists, but must be excluded from any product-based metric.

### Finding 3: `order_number` starts at 1 with no null `days_since_prior_order` except first orders
- Every user's first order (`order_number = 1`) correctly has a NULL `days_since_prior_order`
  (206,209 nulls = exactly the number of users) — this is expected, not a data quality issue.
- **Action:** Exclude first orders when calculating "average gap between orders"; include them
  as the baseline "order 1" cohort entry point in retention curves.

---

## Other checks performed (all passed)
| Check | Result |
|---|---|
| Duplicate (order_id, product_id) rows in order_products_prior | 0 found |
| order_products_prior rows referencing non-existent orders | 0 found |
| products referencing invalid aisle_id | 0 found |
| order_dow range | 0–6 (valid) |
| order_hour_of_day range | 0–23 (valid) |
| reordered flag values | {0, 1} only (valid) |
| Orders per user | min 4, max 100, avg ~16.6 |
| Every train order has matching product-level rows | Yes, 0 mismatches |

## Table Relationships (ERD)
See diagram below. Key structure: `orders` is the fact table for order-level metadata;
`order_products_prior`/`order_products_train` are the line-item fact tables (one row per
product per order); `products` links to `aisles` and `departments` for category rollups.
