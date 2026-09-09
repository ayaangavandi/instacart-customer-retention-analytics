# Business Requirements Document (BRD)
## Project: Customer Retention & Reorder Behavior Analysis — Instacart

---

### 1. Background
Instacart is a grocery delivery/pickup platform. Revenue depends heavily on **repeat purchases**,
not one-time orders — acquiring a customer is expensive, so profitability hinges on how often
and how consistently customers reorder. The company has released anonymized historical order
data (~3.4M orders from ~206K users, ~50K products).

### 2. Business Problem
The VP of Growth wants to understand:
> "Why do some customers keep ordering while others drop off after one or two orders —
> and which products/behaviors predict long-term retention?"

Leadership suspects reorder behavior is not random — certain products, order timing, and
early-order patterns may signal whether a customer will stick around. Currently there is no
clear view of:
- How retention changes over a customer's lifecycle (order 1 → order 2 → order N)
- Which products/departments drive repeat purchases vs. one-off trial
- Whether there are distinct customer segments with different reorder behavior
- What operational timing patterns (day/hour) affect ordering habits

### 3. Stakeholders
| Stakeholder | Interest |
|---|---|
| VP of Growth | Retention strategy, reduce churn |
| Marketing Team | Target segments for reorder campaigns / reminders |
| Merchandising Team | Which products to promote/stock for repeat purchase |
| Operations | Staffing/inventory aligned to order time patterns |

> **Note (updated after data profiling):** Every user in this dataset already has 4+ historical
> orders (Instacart pre-filtered the export this way). This means we cannot observe true
> "first-order churn" — that population was excluded before we ever received the data. Question 1
> below is reframed accordingly: instead of "why do customers leave after order 1," we ask how
> engagement (frequency, reorder loyalty) evolves and varies *among customers who are already
> repeat-prone*. This is disclosed here and in the final report rather than glossed over.

### 4. Key Business Questions
1. Among repeat customers (4+ orders, per dataset scope), how does order-to-order retention evolve — where is the steepest drop-off in the sequence, and what distinguishes higher-frequency from lower-frequency customers? (retention curve)
2. How does "days since prior order" relate to the likelihood of continued ordering?
3. Which products/aisles/departments have the highest reorder rate (loyalty drivers) vs. highest one-time trial rate?
4. Can we segment customers (e.g., by order frequency, basket size, reorder ratio) into meaningful behavioral groups?
5. When do customers order (day of week / hour of day) — and does this affect operational planning?
6. Which products are commonly bought together (basket affinity) — supporting cross-sell/bundling recommendations?

### 5. Success Metrics / KPIs (defined precisely in `02_metrics_dictionary.md`)
- Order-to-order retention rate (cohort-based)
- Reorder rate (overall, by product/aisle/department)
- Average days between orders
- Customer segments by RFM-style behavior
- Basket affinity pairs (lift/support/confidence)

### 6. Scope
**In scope:** Historical order/product data analysis, retention/cohort analysis, product-level
reorder analysis, customer segmentation, basket affinity, dashboard, recommendations.

**Out of scope:** Real-time data pipelines, actual A/B test execution, pricing/promotions data
(not in dataset), demographic data (not in dataset — anonymized IDs only).

### 7. Deliverables
1. Cleaned, modeled SQL database (done)
2. Metrics dictionary
3. EDA notebook
4. SQL query bank answering each business question
5. Customer segmentation model (Python)
6. Power BI dashboard (exec-facing)
7. Insights & recommendations one-pager
8. GitHub portfolio repo with full documentation

### 8. Assumptions & Constraints
- Data is anonymized; no PII, no demographics, no revenue/pricing — so all "business impact"
  framing will use proxy metrics (reorder rate, order frequency) rather than $ revenue, clearly
  labeled as such.
- `eval_set = 'train'` orders represent each user's most recent order (used as a labeled next-order
  set in the original Kaggle competition) — we'll treat it as the "current/latest order" for
  retention framing where relevant, and prior orders as historical behavior.
- Dataset is a fixed historical snapshot (2017), not live — recommendations are analytical/strategic,
  not operationally deployed.
