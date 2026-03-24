-- ============================================================
-- ANALYSIS 1: Monthly Budget vs Actuals Variance
-- Skills: CTEs, Window Functions, CASE WHEN, ROUND, NULLIF
-- Business Use: Track which departments overspent each month
-- ============================================================

USE fpa_variance_db;

WITH monthly_data AS (
    SELECT
        dd.fiscal_year,
        dd.month_num,
        dd.month_name,
        dd.period_label,
        dp.dept_name,
        dc.category_name,
        dr.region_name,
        SUM(ft.budget_amount) AS total_budget,
        SUM(ft.actual_amount) AS total_actual
    FROM fact_transactions ft
    JOIN dim_date       dd ON ft.date_id     = dd.date_id
    JOIN dim_department dp ON ft.dept_id     = dp.dept_id
    JOIN dim_category   dc ON ft.category_id = dc.category_id
    JOIN dim_region     dr ON ft.region_id   = dr.region_id
    GROUP BY
        dd.fiscal_year, dd.month_num, dd.month_name,
        dd.period_label, dp.dept_name,
        dc.category_name, dr.region_name
),
variance_calc AS (
    SELECT
        fiscal_year,
        month_name,
        period_label,
        dept_name,
        category_name,
        region_name,
        month_num,
        ROUND(total_budget, 2)                                            AS budget_amount,
        ROUND(total_actual, 2)                                            AS actual_amount,
        ROUND(total_actual - total_budget, 2)                             AS variance_amount,
        ROUND((total_actual - total_budget) / NULLIF(total_budget,0) * 100, 1) AS variance_pct,
        -- Rank departments by overspend within each month
        RANK() OVER (
            PARTITION BY fiscal_year, month_num
            ORDER BY (total_actual - total_budget) DESC
        ) AS overspend_rank
    FROM monthly_data
)
SELECT
    period_label,
    dept_name,
    category_name,
    region_name,
    budget_amount,
    actual_amount,
    variance_amount,
    CONCAT(variance_pct, '%')  AS variance_pct,
    overspend_rank,
    CASE
        WHEN variance_pct > 20  THEN '🔴 Critical Overspend'
        WHEN variance_pct > 10  THEN '🟠 Moderate Overspend'
        WHEN variance_pct > 0   THEN '🟡 Slight Overspend'
        WHEN variance_pct = 0   THEN '✅ On Budget'
        ELSE                         '🟢 Under Budget'
    END AS budget_status
FROM variance_calc
ORDER BY fiscal_year, month_num, overspend_rank;
