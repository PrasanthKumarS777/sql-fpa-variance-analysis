<div align="center">
  <h1>📊 SQL FP&amp;A Variance Analysis System</h1>
  <p>
    <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white"/>
    <img src="https://img.shields.io/badge/SQL-Advanced-orange?style=for-the-badge&logo=databricks&logoColor=white"/>
    <img src="https://img.shields.io/badge/FP%26A-Financial%20Analysis-2ea44f?style=for-the-badge"/>
    <img src="https://img.shields.io/badge/Git-Version%20Control-F05032?style=for-the-badge&logo=git&logoColor=white"/>
    <img src="https://img.shields.io/badge/VS%20Code-Editor-007ACC?style=for-the-badge&logo=visualstudiocode&logoColor=white"/>
  </p>
  <p><strong>A production-grade, SQL-only Financial Planning &amp; Analysis (FP&amp;A) system that tracks Budget vs Actuals, detects overspending, forecasts future costs, and delivers CFO-level executive insights — built entirely in MySQL 8.0.</strong></p>
  <br/>
</div>

---

<h2>📌 Table of Contents</h2>
<ol>
  <li><a href="#about">About the Project</a></li>
  <li><a href="#problem">Real Business Problem Solved</a></li>
  <li><a href="#dataset">Dataset</a></li>
  <li><a href="#architecture">Database Architecture</a></li>
  <li><a href="#analyses">SQL Analyses Built</a></li>
  <li><a href="#concepts">Advanced SQL Concepts Used</a></li>
  <li><a href="#insights">Key Business Insights</a></li>
  <li><a href="#structure">Project Structure</a></li>
  <li><a href="#run">How to Run</a></li>
  <li><a href="#stack">Tech Stack</a></li>
  <li><a href="#author">Author</a></li>
</ol>

---

<h2 id="about">🧠 About the Project</h2>
<p>This project simulates a <strong>real-world FP&amp;A (Financial Planning &amp; Analysis) system</strong> used by finance teams in mid-to-large enterprises. It is built entirely using <strong>advanced SQL</strong> — no BI tools, no Python analytics, no Excel — demonstrating that SQL alone is powerful enough to deliver complete financial intelligence.</p>
<p>The system ingests real transaction-level financial data, loads it into a <strong>Star Schema data model</strong>, and runs a series of increasingly complex SQL queries to answer the most critical questions a CFO, Finance Controller, or FP&amp;A Analyst faces every quarter.</p>

---

<h2 id="problem">💼 Real Business Problem Solved</h2>
<p>Finance teams across every industry face these recurring challenges:</p>
<table>
  <thead>
    <tr><th>Problem</th><th>How This System Solves It</th></tr>
  </thead>
  <tbody>
    <tr><td>Which departments are over budget?</td><td>Monthly variance analysis with status flags</td></tr>
    <tr><td>How much have we spent YTD vs plan?</td><td>Running totals using <code>SUM() OVER()</code> window functions</td></tr>
    <tr><td>Which cost categories are bleeding money?</td><td>Category-level P&amp;L pivot with <code>CASE WHEN</code> pivoting</td></tr>
    <tr><td>What will we spend next quarter?</td><td>Rolling 3-month forecast using <code>WITH RECURSIVE</code> CTE</td></tr>
    <tr><td>Give me a one-page financial health report</td><td>Executive summary chaining 4 CTEs into one CFO view</td></tr>
  </tbody>
</table>

---

<h2 id="dataset">📂 Dataset</h2>
<ul>
  <li><strong>Source:</strong> <a href="https://www.kaggle.com/datasets/kennathalexanderroy/budget-vs-actual-financial-dataset">Kaggle — Budget vs Actual Financial Dataset</a></li>
  <li><strong>Size:</strong> 10,010 rows → 9,992 clean transactions after null removal</li>
  <li><strong>Time Period:</strong> FY2021 — FY2023 (3 fiscal years)</li>
  <li><strong>Raw Columns:</strong> <code>Date</code>, <code>Department</code>, <code>Category</code>, <code>Region</code>, <code>Budget Amount</code>, <code>Actual Amount</code>, <code>Payment Method</code>, <code>Transaction ID</code></li>
</ul>

---

<h2 id="architecture">🗄️ Database Architecture</h2>
<p>The raw CSV was normalised into a <strong>Star Schema</strong> — 1 fact table + 5 dimension tables:</p>

<table>
  <thead>
    <tr><th>Table</th><th>Type</th><th>Rows</th><th>Description</th></tr>
  </thead>
  <tbody>
    <tr><td><code>dim_date</code></td><td>Dimension</td><td>1,095</td><td>Fiscal calendar with year, quarter, month, period labels</td></tr>
    <tr><td><code>dim_department</code></td><td>Dimension</td><td>6</td><td>Cost centers: Sales, HR, IT, Finance, Marketing, Operations</td></tr>
    <tr><td><code>dim_category</code></td><td>Dimension</td><td>6</td><td>Chart of accounts: Salaries, Marketing, Infrastructure, Travel, Utilities, Training</td></tr>
    <tr><td><code>dim_region</code></td><td>Dimension</td><td>5</td><td>Geographic regions: North, South, East, West, Central</td></tr>
    <tr><td><code>dim_payment_method</code></td><td>Dimension</td><td>4</td><td>Payment types: Bank Transfer, Credit Card, etc.</td></tr>
    <tr><td><code>fact_transactions</code></td><td>Fact</td><td>9,992</td><td>Core transaction table with budget, actuals, computed variance</td></tr>
  </tbody>
</table>

<p><strong>Key design decisions:</strong></p>
<ul>
  <li><code>variance_amount</code> and <code>variance_pct</code> are <strong>GENERATED ALWAYS AS</strong> computed columns — auto-calculated by MySQL on every insert, zero manual computation needed</li>
  <li>All foreign keys are indexed for query performance</li>
  <li><code>INSERT IGNORE</code> used during load for idempotent data loading</li>
</ul>

---

<h2 id="analyses">📊 SQL Analyses Built</h2>

<h3>1. <code>analysis/03_monthly_variance.sql</code> — Monthly Budget vs Actuals</h3>
<p><strong>Answers:</strong> Which departments overspent in each month?</p>
<ul>
  <li>Multi-table JOIN across all 5 dimension tables</li>
  <li><code>RANK() OVER (PARTITION BY fiscal_year, month_num ORDER BY variance DESC)</code> to rank worst offenders per month</li>
  <li><code>CASE WHEN</code> status flags: 🔴 Critical / 🟠 Moderate / 🟡 Slight / 🟢 Under Budget</li>
</ul>

<h3>2. <code>analysis/04_ytd_cumulative.sql</code> — YTD Running Totals</h3>
<p><strong>Answers:</strong> How much has each department spent vs planned so far this fiscal year?</p>
<ul>
  <li><code>SUM() OVER (PARTITION BY fiscal_year, dept ORDER BY month_num ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)</code></li>
  <li>Dual window frames computing YTD budget, YTD actual, and YTD variance % simultaneously</li>
</ul>

<h3>3. <code>analysis/05_dept_pnl_ranking.sql</code> — Department P&amp;L Pivot + Ranking</h3>
<p><strong>Answers:</strong> What is each department's full P&amp;L breakdown by category? Who is the worst offender?</p>
<ul>
  <li><code>CASE WHEN</code> pivot transforms category rows into columns per department</li>
  <li><code>DENSE_RANK() OVER (PARTITION BY fiscal_year ORDER BY variance DESC)</code></li>
  <li>Action flags: 🚨 Escalate to CFO / 🔴 Needs Review / 🟡 Monitor / 🟢 Favourable</li>
</ul>

<h3>4. <code>analysis/06_rolling_forecast.sql</code> — Rolling 3-Month Forecast</h3>
<p><strong>Answers:</strong> Based on recent spending, what will we spend next 3 months?</p>
<ul>
  <li><code>WITH RECURSIVE</code> CTE generates 3 forward projection rows per dept+category</li>
  <li>Run rate from last 3 closed months using <code>ROW_NUMBER() OVER (ORDER BY fiscal_year DESC, month_num DESC)</code></li>
  <li>2% Month-over-Month compounding growth applied recursively</li>
</ul>

<h3>5. <code>reports/07_executive_summary.sql</code> — CFO Executive Dashboard</h3>
<p><strong>Answers:</strong> What is the complete financial health of the company in one view?</p>
<ul>
  <li>Chains <strong>4 CTEs</strong> together: company totals + dept performance + category performance + region performance</li>
  <li><code>RANK()</code> windows inside each CTE to surface best/worst performers</li>
  <li>Final JOIN combines all dimensions into a single executive row per fiscal year</li>
</ul>

---

<h2 id="concepts">⚙️ Advanced SQL Concepts Used</h2>
<table>
  <thead>
    <tr><th>Concept</th><th>Where Used</th></tr>
  </thead>
  <tbody>
    <tr><td><code>WITH</code> CTE (non-recursive)</td><td>All 5 analysis files</td></tr>
    <tr><td><code>WITH RECURSIVE</code> CTE</td><td>Rolling 3-month forecast</td></tr>
    <tr><td><code>RANK()</code> Window Function</td><td>Monthly variance, executive summary</td></tr>
    <tr><td><code>DENSE_RANK()</code> Window Function</td><td>Department overspend ranking</td></tr>
    <tr><td><code>ROW_NUMBER()</code> Window Function</td><td>Last-3-months run rate selection</td></tr>
    <tr><td><code>SUM() OVER()</code> Running Totals</td><td>YTD cumulative analysis</td></tr>
    <tr><td><code>ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW</code></td><td>YTD window frame</td></tr>
    <tr><td><code>CASE WHEN</code> Pivot</td><td>Department P&amp;L pivot by category</td></tr>
    <tr><td><code>GENERATED ALWAYS AS</code> Computed Columns</td><td>variance_amount, variance_pct in fact table</td></tr>
    <tr><td>Multi-table JOINs (5 tables)</td><td>All analysis queries</td></tr>
    <tr><td><code>NULLIF()</code> for safe division</td><td>All variance % calculations</td></tr>
    <tr><td>Star Schema Design</td><td>Database architecture</td></tr>
    <tr><td>Indexing for performance</td><td>All FK columns indexed</td></tr>
    <tr><td><code>INSERT IGNORE</code> for idempotency</td><td>Data loader</td></tr>
  </tbody>
</table>

---

<h2 id="insights">📈 Key Business Insights Discovered</h2>
<ul>
  <li>📌 <strong>Operations</strong> was the worst-performing department in FY2021 — overspent by <strong>17.1%</strong> (₹6.86Cr above budget)</li>
  <li>📌 <strong>HR</strong> became the worst department in FY2022 and FY2023 — overspent by <strong>16.3%</strong> and <strong>15.1%</strong> respectively</li>
  <li>📌 <strong>Finance</strong> was consistently the best-performing department — variance improved from <strong>12.6% → 4.0%</strong> over 3 years</li>
  <li>📌 <strong>Salaries</strong> was the costliest category in FY2021 and FY2023</li>
  <li>📌 Company-wide overspend grew from <strong>₹3.07Cr (2021) → ₹3.63Cr (2022)</strong> before improving to <strong>₹2.74Cr (2023)</strong></li>
  <li>📌 <strong>South region</strong> was best in FY2021, <strong>North region</strong> best in FY2023</li>
</ul>

---

<h2 id="structure">📁 Project Structure</h2>

<pre>
sql-fpa-variance-analysis/
│
├── schema/
│   └── 01_schema.sql              # Star schema DDL — 5 dims + 1 fact table
│
├── data/
│   ├── budget_actuals.csv         # Raw dataset (9,992 clean rows)
│   └── 02_load_data.py            # One-time Python data loader script
│
├── analysis/
│   ├── 03_monthly_variance.sql    # Monthly budget vs actuals + status flags
│   ├── 04_ytd_cumulative.sql      # YTD running totals (window functions)
│   ├── 05_dept_pnl_ranking.sql    # Dept P&L pivot + DENSE_RANK
│   └── 06_rolling_forecast.sql    # Recursive CTE rolling 3-month forecast
│
├── reports/
│   └── 07_executive_summary.sql   # CFO executive dashboard query
│
├── .gitattributes                  # Forces GitHub to detect repo as SQL
└── README.md
</pre>

---

<h2 id="run">🚀 How to Run</h2>

<h3>Prerequisites</h3>
<ul>
  <li>MySQL 8.0+</li>
  <li>Python 3.x with <code>pandas</code> and <code>mysql-connector-python</code></li>
  <li>Git Bash or any terminal</li>
</ul>

<h3>Setup Steps</h3>

<pre><code># 1. Clone the repo
git clone https://github.com/PrasanthKumarS777/sql-fpa-variance-analysis.git
cd sql-fpa-variance-analysis

# 2. Create the database
mysql -u root -p -e "CREATE DATABASE fpa_variance_db;"

# 3. Create star schema
mysql -u root -p fpa_variance_db &lt; schema/01_schema.sql

# 4. Install Python dependencies
pip install pandas mysql-connector-python openpyxl

# 5. Load data (update your MySQL password in the script first)
python3 data/02_load_data.py

# 6. Run any analysis
mysql -u root -p fpa_variance_db &lt; analysis/03_monthly_variance.sql
mysql -u root -p fpa_variance_db &lt; analysis/04_ytd_cumulative.sql
mysql -u root -p fpa_variance_db &lt; analysis/05_dept_pnl_ranking.sql
mysql -u root -p fpa_variance_db &lt; analysis/06_rolling_forecast.sql
mysql -u root -p fpa_variance_db &lt; reports/07_executive_summary.sql
</code></pre>

---

<h2 id="stack">🛠️ Tech Stack</h2>
<table>
  <thead>
    <tr><th>Tool</th><th>Purpose</th></tr>
  </thead>
  <tbody>
    <tr><td><img src="https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white"/></td><td>Primary database engine — all analytics run here</td></tr>
    <tr><td><img src="https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white"/></td><td>One-time data loader script only (not for analysis)</td></tr>
    <tr><td><img src="https://img.shields.io/badge/VS%20Code-Editor-007ACC?logo=visualstudiocode&logoColor=white"/></td><td>SQL development environment</td></tr>
    <tr><td><img src="https://img.shields.io/badge/Git-Version%20Control-F05032?logo=git&logoColor=white"/></td><td>Source control with meaningful commits</td></tr>
    <tr><td><img src="https://img.shields.io/badge/GitHub-Repository-181717?logo=github&logoColor=white"/></td><td>Code hosting and portfolio showcase</td></tr>
  </tbody>
</table>

---

<h2 id="author">👨‍💻 Author</h2>
<table>
  <tr>
    <td><strong>Name</strong></td><td>Prasanth Kumar Sahu</td>
  </tr>
  <tr>
    <td><strong>Role</strong></td><td>Data Scientist | Financial Analyst | SQL Engineer</td>
  </tr>
  <tr>
    <td><strong>Location</strong></td><td>Bhubaneswar, Odisha, India</td>
  </tr>
  <tr>
    <td><strong>GitHub</strong></td><td><a href="https://github.com/PrasanthKumarS777">PrasanthKumarS777</a></td>
  </tr>
</table>

---

<div align="center">
  <sub>⭐ If this project helped you, consider giving it a star!</sub>
  <br/>
  <sub>Built with ❤️ using pure SQL — no BI tools, no dashboards, just the power of SQL.</sub>
</div>
