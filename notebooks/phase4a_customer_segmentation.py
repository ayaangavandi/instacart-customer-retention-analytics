"""
Phase 4a — Customer Segmentation
Groups customers into behavioral segments using KMeans clustering.

BEFORE RUNNING:
  1. Run EXPORT 1 in sql/05_phase4_exports.sql
  2. Save the result as data/customer_features.csv

INSTALL (one time):
  pip install pandas scikit-learn matplotlib
"""

import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt

# ---------------------------------------------------------
# 1. Load the data
# ---------------------------------------------------------
df = pd.read_csv("data/customer_features.csv")
print("Loaded rows:", len(df))
print(df.head())

# Drop any rare rows with missing values (e.g. edge cases in the aggregation)
df = df.dropna()

# ---------------------------------------------------------
# 2. Pick the features that describe customer BEHAVIOR
#    (this is the "RFM-style" part — Frequency, Basket size, Loyalty)
# ---------------------------------------------------------
features = ["total_orders", "avg_days_between_orders", "avg_basket_size", "reorder_rate_pct"]
X = df[features]

# ---------------------------------------------------------
# 3. Scale the features
#    KMeans uses distance, so features must be on the same scale
#    (otherwise "total_orders" 4-100 would dominate "reorder_rate_pct" 0-100... but here it's close,
#    still always scale before clustering as standard practice)
# ---------------------------------------------------------
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# ---------------------------------------------------------
# 4. Choose number of clusters with the Elbow Method
#    Run this once, look at the plot, then set K in step 5.
# ---------------------------------------------------------
inertias = []
k_range = range(2, 9)
for k in k_range:
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    km.fit(X_scaled)
    inertias.append(km.inertia_)

plt.figure(figsize=(6, 4))
plt.plot(list(k_range), inertias, marker="o")
plt.xlabel("Number of clusters (K)")
plt.ylabel("Inertia")
plt.title("Elbow Method — look for the bend")
plt.savefig("outputs/elbow_plot.png", bbox_inches="tight")
print("Saved outputs/elbow_plot.png — open it and pick the K where the line bends")

# ---------------------------------------------------------
# 5. Fit final KMeans model
#    K=4 is a good, simple default for this dataset (adjust after viewing the elbow plot)
# ---------------------------------------------------------
K = 4
kmeans = KMeans(n_clusters=K, random_state=42, n_init=10)
df["segment"] = kmeans.fit_predict(X_scaled)

# ---------------------------------------------------------
# 6. Profile each segment — this is the actual business output
#    (the averages per cluster tell you what each segment MEANS)
# ---------------------------------------------------------
profile = df.groupby("segment")[features + ["total_items_purchased"]].mean().round(2)
profile["customer_count"] = df.groupby("segment").size()
profile["pct_of_customers"] = (100 * profile["customer_count"] / len(df)).round(1)

print("\n=== SEGMENT PROFILE ===")
print(profile)

# ---------------------------------------------------------
# 7. Save results
#    - segmented_customers.csv -> full user-level table for Power BI
#    - segment_profile.csv -> summary table for Power BI / your report
# ---------------------------------------------------------
df.to_csv("outputs/segmented_customers.csv", index=False)
profile.to_csv("outputs/segment_profile.csv")
print("\nSaved: outputs/segmented_customers.csv")
print("Saved: outputs/segment_profile.csv")

# ---------------------------------------------------------
# 8. Quick visual — basket size vs reorder rate, colored by segment
# ---------------------------------------------------------
plt.figure(figsize=(7, 5))
scatter = plt.scatter(
    df["avg_basket_size"], df["reorder_rate_pct"],
    c=df["segment"], cmap="viridis", alpha=0.3, s=5
)
plt.xlabel("Average Basket Size")
plt.ylabel("Reorder Rate (%)")
plt.title("Customer Segments")
plt.colorbar(scatter, label="Segment")
plt.savefig("outputs/segment_scatter.png", bbox_inches="tight")
print("Saved: outputs/segment_scatter.png")

print("\nDone. Open segment_profile.csv and name each segment based on its averages")
print("(e.g. high orders + high reorder rate = 'Loyal Regulars').")
