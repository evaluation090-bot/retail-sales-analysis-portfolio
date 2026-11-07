import pandas as pd
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
RAW = BASE / "data" / "raw" / "retail_sales_raw.csv"
CLEAN = BASE / "data" / "cleaned" / "retail_sales_cleaned.csv"

df = pd.read_csv(RAW)
raw_rows = len(df)

print("Raw shape:", df.shape)
print("\nMissing values before cleaning:")
print(df.isna().sum())

# Remove exact duplicate records.
df = df.drop_duplicates().copy()

# Normalize text values and preserve missing values as missing.
for col in ["product", "category", "region", "payment_method"]:
    df[col] = df[col].astype("string").str.strip().str.title()

# Parse mixed date formats (pandas 2.x).
df["order_date"] = pd.to_datetime(df["order_date"], errors="coerce", format="mixed")

for col in ["quantity", "unit_price", "sales_amount"]:
    df[col] = pd.to_numeric(df[col], errors="coerce")

# Keep complete, valid transactions for this analysis.
df = df.dropna(subset=[
    "order_id", "order_date", "quantity", "unit_price", "sales_amount",
    "product", "category", "region"
]).copy()
df = df[
    (df["quantity"] > 0) &
    (df["unit_price"] > 0) &
    (df["sales_amount"] >= 0)
].copy()

df["month"] = df["order_date"].dt.to_period("M").astype(str)

# Illustrative estimate only: actual cost data is not supplied.
df["gross_profit"] = (df["sales_amount"] * 0.28).round(2)
df["profit_margin"] = (
    df["gross_profit"] / df["sales_amount"].where(df["sales_amount"] != 0)
).fillna(0).round(4)

df = df.sort_values(["order_date", "order_id"]).reset_index(drop=True)
CLEAN.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(CLEAN, index=False, date_format="%Y-%m-%d")

print("\nCleaned shape:", df.shape)
print("Rows excluded or removed:", raw_rows - len(df))
print("\nMissing values after cleaning:")
print(df.isna().sum())
print("\nCleaned file saved to:", CLEAN)
