import pandas as pd
import mysql.connector

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Pr@santh001",
    database="fpa_variance_db"
)
cursor = conn.cursor()

df = pd.read_csv("data/budget_actuals.csv")
df['Date'] = pd.to_datetime(df['Date'])
df.columns = df.columns.str.strip()
print(f"✅ Loaded {len(df)} rows")
df = df.dropna()
print(f"✅ After cleaning: {len(df)} rows")

# dim_date
print("Loading dim_date...")
for d in df['Date'].drop_duplicates().sort_values():
    cursor.execute("""
        INSERT IGNORE INTO dim_date
        (full_date, day_of_week, day_num, month_num, month_name,
         quarter_num, fiscal_year, period_label, is_month_end)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        d.date(),
        d.strftime('%A'),
        d.day, d.month,
        d.strftime('%B'),
        (d.month - 1) // 3 + 1,
        d.year,
        f"FY{d.year}-Q{(d.month-1)//3+1}-M{d.month:02d}",
        False
    ))

# dim_department
print("Loading dim_department...")
for val in df['Department'].unique():
    cursor.execute("INSERT IGNORE INTO dim_department (dept_name) VALUES (%s)", (val,))

# dim_category
print("Loading dim_category...")
for val in df['Category'].unique():
    cursor.execute("INSERT IGNORE INTO dim_category (category_name) VALUES (%s)", (val,))

# dim_region
print("Loading dim_region...")
for val in df['Region'].unique():
    cursor.execute("INSERT IGNORE INTO dim_region (region_name) VALUES (%s)", (val,))

# dim_payment_method
print("Loading dim_payment_method...")
for val in df['Payment Method'].unique():
    cursor.execute("INSERT IGNORE INTO dim_payment_method (method_name) VALUES (%s)", (val,))

conn.commit()

# Build lookup maps
cursor.execute("SELECT full_date, date_id FROM dim_date")
date_map = {str(r[0]): r[1] for r in cursor.fetchall()}

cursor.execute("SELECT dept_name, dept_id FROM dim_department")
dept_map = {r[0]: r[1] for r in cursor.fetchall()}

cursor.execute("SELECT category_name, category_id FROM dim_category")
cat_map = {r[0]: r[1] for r in cursor.fetchall()}

cursor.execute("SELECT region_name, region_id FROM dim_region")
reg_map = {r[0]: r[1] for r in cursor.fetchall()}

cursor.execute("SELECT method_name, method_id FROM dim_payment_method")
method_map = {r[0]: r[1] for r in cursor.fetchall()}

# fact_transactions
print("Loading fact_transactions...")
for _, row in df.iterrows():
    cursor.execute("""
        INSERT IGNORE INTO fact_transactions
        (transaction_id, date_id, dept_id, category_id,
         region_id, method_id, budget_amount, actual_amount)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        row['Transaction ID'],
        date_map[str(row['Date'].date())],
        dept_map[row['Department']],
        cat_map[row['Category']],
        reg_map[row['Region']],
        method_map[row['Payment Method']],
        float(row['Budget Amount']),
        float(row['Actual Amount'])
    ))

conn.commit()
cursor.close()
conn.close()
print("✅ All data loaded successfully!")
