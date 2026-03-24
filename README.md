```markdown
<div align="center">

<h1>📊 SQL FP&A Variance Analysis System</h1>

<p>
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white"/>
  <img src="https://img.shields.io/badge/SQL-Advanced-orange?style=for-the-badge&logo=databricks&logoColor=white"/>
  <img src="https://img.shields.io/badge/FP%26A-Financial%20Analysis-2ea44f?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Python-Data%20Loader-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Git-Version%20Control-F05032?style=for-the-badge&logo=git&logoColor=white"/>
</p>

<p><strong>A production-grade, SQL-only Financial Planning & Analysis (FP&A) system that tracks Budget vs Actuals, detects overspending, forecasts future costs, and delivers CFO-level executive insights — built entirely in MySQL 8.0.</strong></p>

</div>

***

## 📌 Table of Contents
- [About the Project](#about-the-project)
- [Real Business Problem Solved](#real-business-problem-solved)
- [Dataset](#dataset)
- [Database Architecture](#database-architecture)
- [SQL Analyses Built](#sql-analyses-built)
- [Advanced SQL Concepts Used](#advanced-sql-concepts-used)
- [Key Business Insights](#key-business-insights)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)
- [Tech Stack](#tech-stack)
- [Author](#author)

***

## 🧠 About the Project

This project simulates a **real-world FP&A (Financial Planning & Analysis) system** used by finance teams in mid-to-large enterprises. It is built entirely using **advanced SQL** — no BI tools, no Python analytics, no Excel — demonstrating that SQL alone is powerful enough to deliver complete financial intelligence.

The system ingests real transaction-level financial data, loads it into a **Star Schema data model**, and runs a series of increasingly complex SQL queries to answer the most critical questions a CFO, Finance Controller, or FP&A Analyst faces every quarter.

***

## 💼 Real Business Problem Solved

Finance teams across every industry face these recurring challenges:

| Problem | How This System Solves It |
|---|---|
| "Which departments are over budget?" | Monthly variance analysis with status flags |
| "How much have we spent YTD vs plan?" | Running totals using `SUM() OVER()` window functions |
| "Which cost categories are bleeding money?" | Category-level P&L pivot with `CASE WHEN` pivoting |
| "What will we spend next quarter?" | Rolling 3-month forecast using `WITH RECURSIVE` CTE |
| "Give me a one-page financial health report" | Executive summary chaining 4 CTEs into one CFO view |

***

## 📂 Dataset

- **Source:** [Kaggle — Budget vs Actual Financial Dataset](https://www.kaggle.com/datasets/kennathalexanderroy/budget-vs-actual-financial-dataset)
- **Size:** 10,010 rows → 9,992 clean transactions after null removal
- **Time Period:** FY2021 — FY2023 (3 fiscal years)
- **Raw Columns:** `Date`, `Department`, `Category`, `Region`, `Budget Amount`, `Actual Amount`, `Payment Method`, `Transaction ID`

***

## 🗄️ Database Architecture

The raw CSV data was normalised into a **Star Schema** with 1 fact table and 5 dimension tables:

```
                    ┌─────────────────┐
                    │   dim_date      │
                    │  (1,095 rows)   │
                    └────────┬────────┘
                             │
┌──────────────┐    ┌────────▼──────────┐    ┌─────────────────┐
│dim_department│    │  fact_transactions │    │  dim_category   │
│  (6 rows)    ├───►│   (9,992 rows)    │◄───┤   (6 rows)      │
└──────────────┘    │                   │    └─────────────────┘
                    │ • transaction_id  │
┌──────────────┐    │ • budget_amount   │    ┌─────────────────┐
│  dim_region  │    │ • actual_amount   │    │dim_payment_method│
│  (5 rows)    ├───►│ • variance_amount │◄───┤   (4 rows)      │
└──────────────┘    │ • variance_pct    │    └─────────────────┘
                    └───────────────────┘
```

**Key design decisions:**
- `variance_amount` and `variance_pct` are **GENERATED ALWAYS AS** computed columns — auto-calculated by MySQL on every insert, zero manual computation needed
- All foreign keys are indexed for query performance
- `INSERT IGNORE` used during load for idempotent data loading

***

## 📊 SQL Analyses Built

### 1. `analysis/03_monthly_variance.sql` — Monthly Budget vs Actuals
**Answers:** Which departments overspent in each month?
- Multi-table JOIN across all 5 dimensions
- `RANK() OVER (PARTITION BY fiscal_year, month_num ORDER BY variance DESC)` to rank worst offenders per month
- `CASE WHEN` status flags: 🔴 Critical / 🟠 Moderate / 🟡 Slight / 🟢 Under Budget

**Sample Output:**
```
FY2021-Q1-M01 | Operations | Training | Central | Budget: 108,561 | Actual: 251,594 | Variance: +131.8% | 🔴 Critical Overspend
```

***

### 2. `analysis/04_ytd_cumulative.sql` — YTD Running Totals
**Answers:** How much has each department spent vs planned so far this fiscal year?
- `SUM() OVER (PARTITION BY fiscal_year, dept ORDER BY month_num ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` for running budget and actuals
- Dual window frames computing YTD budget, YTD actual, and YTD variance % simultaneously

**Sample Output:**
```
FY2021 | Finance | Infrastructure | Monthly: 796,875 | YTD Budget: 1,620,020 | YTD Actual: 1,717,631 | YTD Variance: +6.0%
```

***

### 3. `analysis/05_dept_pnl_ranking.sql` — Department P&L Pivot + Ranking
**Answers:** What is each department's full P&L breakdown by category? Who is the worst offender?
- `CASE WHEN` pivot transforms category rows into columns (Salaries / Marketing / Infrastructure / Travel / Utilities / Training)
- `DENSE_RANK() OVER (PARTITION BY fiscal_year ORDER BY variance DESC)` to rank departments
- Action flags: 🚨 Escalate to CFO / 🔴 Needs Review / 🟡 Monitor / 🟢 Favourable

**Sample Output:**
```
2021 | Operations | Salaries | Variance: 2,725,702 | +44.4% | Rank: 1 | 🔴 Needs Review
```

***

### 4. `analysis/06_rolling_forecast.sql` — Rolling 3-Month Forecast
**Answers:** Based on recent spending patterns, what will we spend next 3 months?
- `WITH RECURSIVE` CTE generates 3 forward projection rows per dept+category
- Run rate calculated from last 3 closed months using `ROW_NUMBER() OVER (ORDER BY fiscal_year DESC, month_num DESC)`
- 2% Month-over-Month compounding growth applied recursively

**Sample Output:**
```
Finance | Salaries | FY2024-Forecast-M+1 | Run Rate: 900,508 | Projected: 900,508
Finance | Salaries | FY2024-Forecast-M+2 | Run Rate: 900,508 | Projected: 918,518 (+2.0%)
Finance | Salaries | FY2024-Forecast-M+3 | Run Rate: 900,508 | Projected: 936,889 (+4.0%)
```

***

### 5. `reports/07_executive_summary.sql` — CFO Executive Dashboard
**Answers:** What is the complete financial health of the company in one view?
- Chains **4 CTEs** together: company totals + dept performance + category performance + region performance
- Uses `RANK()` windows inside each CTE to surface best/worst performers
- Final JOIN combines all dimensions into a single executive row per fiscal year

**Sample Output:**
```
2023 | Budget: 272M | Actual: 299M | Variance: +10.1% | Worst: HR (+15.1%) | Best: Finance (+4.0%) | Costliest: Salaries | Best Region: North | 🔴 Over Budget
```

***

## ⚙️ Advanced SQL Concepts Used

| Concept | Where Used |
|---|---|
| `WITH` CTE (non-recursive) | All 5 analysis files |
| `WITH RECURSIVE` CTE | Rolling forecast |
| `RANK()` Window Function | Monthly variance, executive summary |
| `DENSE_RANK()` Window Function | Department overspend ranking |
| `ROW_NUMBER()` Window Function | Last-3-months run rate selection |
| `SUM() OVER()` Running Totals | YTD cumulative analysis |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | YTD window frame |
| `CASE WHEN` Pivot | Department P&L pivot |
| `GENERATED ALWAYS AS` Computed Columns | variance_amount, variance_pct in fact table |
| Multi-table JOINs (5 tables) | All analysis queries |
| `NULLIF()` for safe division | All variance % calculations |
| `GROUP BY` with aggregations | All queries |
| `INSERT IGNORE` for idempotency | Data loader |
| Star Schema Design | Database architecture |
| Indexing for performance | All FK columns indexed |

***

## 📈 Key Business Insights Discovered

- 📌 **Operations** was the worst-performing department in FY2021 — overspent by **17.1%** (₹6.86Cr above budget)
- 📌 **HR** became the worst department in FY2022 and FY2023 — overspent by **16.3%** and **15.1%** respectively
- 📌 **Finance** was consistently the best-performing department — variance improved from **12.6% → 4.0%** over 3 years
- 📌 **Salaries** was the costliest category in FY2021 and FY2023
- 📌 Company-wide overspend grew from **₹3.07Cr (2021) → ₹3.63Cr (2022)** before improving to **₹2.74Cr (2023)**
- 📌 **South region** was best in FY2021, **North region** best in FY2023

***

## 📁 Project Structure

```
sql-fpa-variance-analysis/
│
├── schema/
│   └── 01_schema.sql              # Star schema DDL — 5 dims + 1 fact table
│
├── data/
│   ├── budget_actuals.csv         # Raw dataset (10,002 clean rows)
│   └── 02_load_data.py            # Python data loader script
│
├── analysis/
│   ├── 03_monthly_variance.sql    # Monthly budget vs actuals + status flags
│   ├── 04_ytd_cumulative.sql      # YTD running totals (window functions)
│   ├── 05_dept_pnl_ranking.sql    # Dept P&L pivot + DENSE_RANK
│   └── 06_rolling_forecast.sql    # Recursive CTE rolling forecast
│
├── reports/
│   └── 07_executive_summary.sql   # CFO executive dashboard query
│
└── README.md
```

***

## 🚀 How to Run

### Prerequisites
- MySQL 8.0+
- Python 3.x with `pandas` and `mysql-connector-python`

### Setup
```bash
# 1. Clone the repo
git clone https://github.com/PrasanthKumarS777/sql-fpa-variance-analysis.git
cd sql-fpa-variance-analysis

# 2. Create the database
mysql -u root -p -e "CREATE DATABASE fpa_variance_db;"

# 3. Create schema
mysql -u root -p fpa_variance_db < schema/01_schema.sql

# 4. Install Python dependencies
pip install pandas mysql-connector-python openpyxl

# 5. Load data (update password in script first)
python3 data/02_load_data.py

# 6. Run any analysis
mysql -u root -p fpa_variance_db < analysis/03_monthly_variance.sql
mysql -u root -p fpa_variance_db < analysis/04_ytd_cumulative.sql
mysql -u root -p fpa_variance_db < analysis/05_dept_pnl_ranking.sql
mysql -u root -p fpa_variance_db < analysis/06_rolling_forecast.sql
mysql -u root -p fpa_variance_db < reports/07_executive_summary.sql
```

***

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
|  | Primary database engine |
|  | Data loading script only |
|  | SQL development environment |
|  | Source control |
|  | Code hosting |

***

## 👨‍💻 Author

**Prasanth Kumar Sahu**  
Aspiring Financial Analyst. 


[

***

<div align="center">
  <sub>Built with ❤️ using pure SQL — no BI tools, no dashboards, just the power of SQL.</sub>
</div>
```
