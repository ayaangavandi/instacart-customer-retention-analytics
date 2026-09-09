"""
Phase 4b — Market Basket Analysis
Finds which products are commonly bought together (for cross-sell/bundling ideas).

BEFORE RUNNING:
  1. Run EXPORT 2 in sql/05_phase4_exports.sql
  2. Save the result as data/basket_data.csv

INSTALL (one time):
  pip install pandas mlxtend
"""

import pandas as pd
from mlxtend.frequent_patterns import apriori, association_rules

# ---------------------------------------------------------
# 1. Load the data
#    Format: order_id, product_name  (one row per item in a basket)
# ---------------------------------------------------------
df = pd.read_csv("data/basket_data.csv")
print("Loaded rows:", len(df))
print("Distinct orders:", df["order_id"].nunique())
print("Distinct products:", df["product_name"].nunique())

# ---------------------------------------------------------
# 2. Turn it into a "basket matrix"
#    One row per order, one column per product, True/False if it's in the basket.
#    This is the standard input shape for the apriori algorithm.
# ---------------------------------------------------------
basket = (
    df.groupby(["order_id", "product_name"])
    .size()
    .unstack(fill_value=0)
)
basket = basket > 0  # convert counts to True/False

print("Basket matrix shape (orders x products):", basket.shape)

# ---------------------------------------------------------
# 3. Find frequent itemsets
#    min_support=0.01 means: keep combos that appear in at least 1% of these orders.
#    Lower this if you get too few results, raise it if you get too many.
# ---------------------------------------------------------
frequent_itemsets = apriori(basket, min_support=0.01, use_colnames=True)
print("\nFrequent itemsets found:", len(frequent_itemsets))

# ---------------------------------------------------------
# 4. Generate association rules from those itemsets
#    Key columns to understand:
#      support    = % of orders containing this combo
#      confidence = if a customer buys A, % chance they also buy B
#      lift       = how much MORE likely B is bought when A is bought,
#                   vs B being bought on its own. lift > 1 = real association
#                   (lift = 1 means no relationship, just coincidence)
# ---------------------------------------------------------
rules = association_rules(frequent_itemsets, metric="lift", min_threshold=1.0)
rules = rules.sort_values("lift", ascending=False)

# Clean up the antecedents/consequents columns (they're frozensets by default)
rules["antecedents"] = rules["antecedents"].apply(lambda x: ", ".join(list(x)))
rules["consequents"] = rules["consequents"].apply(lambda x: ", ".join(list(x)))

print("\n=== TOP 15 PRODUCT ASSOCIATIONS BY LIFT ===")
print(rules[["antecedents", "consequents", "support", "confidence", "lift"]].head(15).to_string(index=False))

# ---------------------------------------------------------
# 5. Save results for the dashboard / report
# ---------------------------------------------------------
rules_out = rules[["antecedents", "consequents", "support", "confidence", "lift"]].round(4)
rules_out.to_csv("outputs/basket_association_rules.csv", index=False)
print("\nSaved: outputs/basket_association_rules.csv")

print("\nHow to read this for the business: sort by 'lift', the top rows are your")
print("strongest cross-sell/bundling candidates (e.g. 'if they buy A, recommend B').")
