-- ============================================================
-- FINAL REPORT: Executive Summary — CFO Dashboard View
-- Skills: Multiple CTEs chained, RANK, CASE, aggregations
-- Business Use: Single query giving full financial health view
-- ============================================================

USE fpa_variance_db;

WITH
-- 1. Overall company financials by year
company_totals AS (
    SELECT
        dd.fiscal_year,
        ROUND(SUM(ft.budget_amount), 2) AS total_budget,
        ROUND(SUM(ft.actual_amount), 2) AS total_actual,
        ROUND(SUM(ft.actual_amount - ft.budget_amount), 2) AS total_variance,
        ROUND(SUM(ft.actual_amount - ft.budget_amount)
              / NULLIF(SUM(ft.budget_amount), 0) * 100, 1) AS variance_pct
    FROM fact_transactions ft
    JOIN dim_date dd ON ft.date_id = dd.date_id
    GROUP BY dd.fiscal_year
),
-- 2. Best and worst department per year
dept_performance AS (
    SELECT
        dd.fiscal_year,
        dp.dept_name,
        ROUND(SUM(ft.budget_amount), 2) AS dept_budget,
        ROUND(SUM(ft.actual_amount), 2) AS dept_actual,
        ROUND(SUM(ft.actual_amount - ft.budget_amount)
              / NULLIF(SUM(ft.budget_amount), 0) * 100, 1) AS dept_variance_pct,
        RANK() OVER (
            PARTITION BY dd.fiscal_year
            ORDER BY SUM(ft.actual_amount - ft.budget_amount) DESC
        ) AS worst_rank,
        RANK() OVER (
            PARTITION BY dd.fiscal_year
            ORDER BY SUM(ft.actual_amount - ft.budget_amount) ASC
        ) AS best_rank
    FROM fact_transactions ft
    JOIN dim_date       dd ON ft.date_id = dd.date_id
    JOIN dim_department dp ON ft.dept_id = dp.dept_id
    GROUP BY dd.fiscal_year, dp.dept_name
),
-- 3. Worst spending category per year
category_performance AS (
    SELECT
        dd.fiscal_year,
        dc.category_name,
        ROUND(SUM(ft.actual_amount - ft.budget_amount), 2) AS cat_variance,
        RANK() OVER (
            PARTITION BY dd.fiscal_year
            ORDER BY SUM(ft.actual_amount - ft.budget_amount) DESC
        ) AS cat_rank
    FROM fact_transactions ft
    JOIN dim_date     dd ON ft.date_id     = dd.date_id
    JOIN dim_category dc ON ft.category_id = dc.category_id
    GROUP BY dd.fiscal_year, dc.category_name
),
-- 4. Best performing region per year
region_performance AS (
    SELECT
        dd.fiscal_year,
        dr.region_name,
        ROUND(SUM(ft.actual_amount - ft.budget_amount)
              / NULLIF(SUM(ft.budget_amount), 0) * 100, 1) AS region_variance_pct,
        RANK() OVER (
            PARTITION BY dd.fiscal_year
            ORDER BY SUM(ft.actual_amount - ft.budget_amount) ASC
        ) AS region_rank
    FROM fact_transactions ft
    JOIN dim_date   dd ON ft.date_id  = dd.date_id
    JOIN dim_region dr ON ft.region_id = dr.region_id
    GROUP BY dd.fiscal_year, dr.region_name
)
-- FINAL: Combine all into one executive view
SELECT
    ct.fiscal_year,
    ct.total_budget,
    ct.total_actual,
    ct.total_variance,
    CONCAT(ct.variance_pct, '%')          AS overall_variance_pct,
    -- Worst dept
    wd.dept_name                           AS worst_dept,
    CONCAT(wd.dept_variance_pct, '%')      AS worst_dept_variance,
    -- Best dept
    bd.dept_name                           AS best_dept,
    CONCAT(bd.dept_variance_pct, '%')      AS best_dept_variance,
    -- Worst category
    wc.category_name                       AS costliest_category,
    -- Best region
    br.region_name                         AS best_region,
    CONCAT(br.region_variance_pct, '%')    AS best_region_variance,
    -- Overall health
    CASE
        WHEN ct.variance_pct > 20 THEN '🚨 Critical — CFO Action Needed'
        WHEN ct.variance_pct > 10 THEN '🔴 Over Budget — Review Required'
        WHEN ct.variance_pct > 0  THEN '🟡 Slight Overspend — Monitor'
        ELSE                           '🟢 Healthy — On Track'
    END                                    AS financial_health
FROM company_totals ct
JOIN dept_performance wd ON ct.fiscal_year = wd.fiscal_year AND wd.worst_rank = 1
JOIN dept_performance bd ON ct.fiscal_year = bd.fiscal_year AND bd.best_rank  = 1
JOIN category_performance wc ON ct.fiscal_year = wc.fiscal_year AND wc.cat_rank = 1
JOIN region_performance   br ON ct.fiscal_year = br.fiscal_year AND br.region_rank = 1
ORDER BY ct.fiscal_year;
