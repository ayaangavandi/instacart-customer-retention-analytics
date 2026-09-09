# Phase 5 — Power BI Dashboard Build Guide (One-Page Executive Dashboard)

## Files to import into Power BI
Get Data → Text/CSV → import each:

| File | Used for |
|---|---|
| `outputs/retention_curve.csv` | Retention curve line chart |
| `outputs/department_reorder_rate.csv` | Reorder rate by department bar chart |
| `outputs/order_timing_heatmap.csv` | Order timing matrix/heatmap |
| `outputs/segment_profile.csv` | Customer segments donut chart |
| `outputs/segmented_customers.csv` | KPI cards (customer-level averages) |
| `outputs/basket_association_rules.csv` | Cross-sell pairs table |

`data/basket_data.csv` is **not** imported into Power BI — it's raw line-item data only used as input to the Python basket analysis script.

**No relationships needed between these tables.** They're independent pre-aggregated summary tables, not raw transactional data — a flat "star of independent summary tables" is the correct, standard pattern for a KPI dashboard like this.

---

## Layout (single page, 16:9)

```
┌─────────────────────────────────────────────────────────────────┐
│  [Card] [Card] [Card] [Card]           ← KPI row                │
├───────────────────────────┬───────────────────────────────────┤
│  Retention Curve           │  Customer Segments                 │
├───────────────────────────┼───────────────────────────────────┤
│  Reorder Rate by Dept       │  Order Timing Heatmap               │
├─────────────────────────────────────────────────────────────────┤
│  Top Cross-Sell Pairs (table)                                     │
└─────────────────────────────────────────────────────────────────┘
```

## DAX measures (on `segmented_customers` table)

```dax
Total Customers = DISTINCTCOUNT(segmented_customers[user_id])
Avg Orders per Customer = ROUND(AVERAGE(segmented_customers[total_orders]), 1)
Overall Reorder Rate = ROUND(AVERAGE(segmented_customers[reorder_rate_pct]), 1)
Avg Basket Size = ROUND(AVERAGE(segmented_customers[avg_basket_size]), 1)
```

## Visual-by-visual

- **KPI cards**: the 4 measures above, one Card visual each.
- **Retention Curve**: line chart, `retention_curve` table, X = `order_number`, Y = `pct_continuing_to_next`. Annotate the order 3→4 drop with a text box/arrow — it's the single most important line on the page.
- **Customer Segments**: donut chart, `segment_profile` table, values = `pct_of_customers`, legend = `segment` (renamed to human labels via a Conditional Column in Power Query).
- **Reorder Rate by Department**: horizontal bar chart, `department_reorder_rate` table, sorted descending by `reorder_rate_pct`.
- **Order Timing Heatmap**: Matrix visual, `order_timing_heatmap` table — rows = `order_dow` (renamed Sun–Sat), columns = `order_hour_of_day`, values = `order_count`, with background color scale conditional formatting turned on.
- **Top Cross-Sell Pairs**: plain Table visual, `basket_association_rules` table, columns `antecedents`/`consequents`/`support`/`confidence`/`lift`, sorted by `lift` descending, Top N filter set to 8–10 rows. Dedupe symmetric pairs (A→B and B→A) before finalizing.

## Design polish
- One accent color + one neutral gray, applied via a custom theme (View → Themes).
- Consistent card styling, no default Power BI shadows/borders.
- Page title: *"Instacart Customer Retention & Reorder Behavior — Executive Overview"*.
- Small subtext under the KPI row noting the dataset scope (3.2M+ orders, 206K customers, 4+ orders minimum per customer).

## Export for the portfolio
- File → Export → PDF for a static copy.
- Full-page screenshot (PNG) for the GitHub README — saved as `assets/dashboard_screenshot.png` in this repo.
