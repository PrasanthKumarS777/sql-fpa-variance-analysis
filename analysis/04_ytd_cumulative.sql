-- ============================================================
-- ANALYSIS 2: Year-To-Date (YTD) Cumulative Budget vs Actuals
-- Skills: SUM() OVER(), running totals, partitioned window frames
-- Business Use: How much have we spent vs planned so far this year?
-- ============================================================

USE fpa_variance_db;

WITH monthly_totals AS (
    SELECT
        dd.fiscal_year,
        dd.month_num,
        dd.month_name,
        dd.period_label,
        dp.dept_name,
        dc.category_name,
        SUM(ft.budget_amount) AS monthly_budget,
        SUM(ft.actual_amount) AS monthly_actual
    FROM fact_transactions ft
    JOIN dim_date       dd ON ft.date_id     = dd.date_id
    JOIN dim_department dp ON ft.dept_id     = dp.dept_id
    JOIN dim_category   dc ON ft.category_id = dc.category_id
    GROUP BY
        dd.fiscal_year, dd.month_num, dd.month_name,
        dd.period_label, dp.dept_name, dc.category_name
)
SELECT
    fiscal_year,
    period_label,
    dept_name,
    category_name,
    ROUND(monthly_budget, 2)                   AS monthly_budget,
    ROUND(monthly_actual, 2)                   AS monthly_actual,
    -- YTD Running Budget
    ROUND(SUM(monthly_budget) OVER (
        PARTITION BY fiscal_year, dept_name, category_name
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                      AS ytd_budget,
    -- YTD Running Actual
    ROUND(SUM(monthly_actual) OVER (
        PARTITION BY fiscal_year, dept_name, category_name
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                      AS ytd_actual,
    -- YTD Variance
    ROUND(SUM(monthly_actual - monthly_budget) OVER (
        PARTITION BY fiscal_year, dept_name, category_name
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                      AS ytd_variance,
    -- YTD Variance %
    ROUND(SUM(monthly_actual - monthly_budget) OVER (
        PARTITION BY fiscal_year, dept_name, category_name
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) / NULLIF(SUM(monthly_budget) OVER (
        PARTITION BY fiscal_year, dept_name, category_name
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 0) * 100, 1)                            AS ytd_variance_pct
FROM monthly_totals
ORDER BY fiscal_year, dept_name, category_name, month_num;
