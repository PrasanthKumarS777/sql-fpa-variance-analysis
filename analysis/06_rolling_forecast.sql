-- ============================================================
-- ANALYSIS 4: Rolling 3-Month Forecast using Recursive CTE
-- Skills: Recursive CTE, AVG run rate, projection logic
-- Business Use: Project next 3 months spend based on actuals
-- ============================================================

USE fpa_variance_db;

WITH RECURSIVE
monthly_actuals AS (
    SELECT
        dp.dept_name,
        dc.category_name,
        dd.fiscal_year,
        dd.month_num,
        SUM(ft.actual_amount) AS monthly_actual
    FROM fact_transactions ft
    JOIN dim_date       dd ON ft.date_id     = dd.date_id
    JOIN dim_department dp ON ft.dept_id     = dp.dept_id
    JOIN dim_category   dc ON ft.category_id = dc.category_id
    GROUP BY dp.dept_name, dc.category_name,
             dd.fiscal_year, dd.month_num
),
last_3_months AS (
    SELECT
        dept_name,
        category_name,
        month_num,
        fiscal_year,
        monthly_actual,
        ROW_NUMBER() OVER (
            PARTITION BY dept_name, category_name
            ORDER BY fiscal_year DESC, month_num DESC
        ) AS recency_rank
    FROM monthly_actuals
),
run_rate AS (
    SELECT
        dept_name,
        category_name,
        ROUND(AVG(monthly_actual), 2) AS avg_run_rate,
        MAX(fiscal_year)              AS last_year
    FROM last_3_months
    WHERE recency_rank <= 3
    GROUP BY dept_name, category_name
),
forecast (
    dept_name, category_name,
    forecast_step, forecast_amount, avg_run_rate, last_year
) AS (
    -- Base case: 1 month ahead
    SELECT
        dept_name,
        category_name,
        1,
        avg_run_rate,
        avg_run_rate,
        last_year
    FROM run_rate

    UNION ALL

    -- Recursive: up to 3 months with 2% MoM growth
    SELECT
        dept_name,
        category_name,
        forecast_step + 1,
        ROUND(forecast_amount * 1.02, 2),
        avg_run_rate,
        last_year
    FROM forecast
    WHERE forecast_step < 3
)
SELECT
    dept_name,
    category_name,
    CONCAT('FY', last_year + 1, '-Forecast-M+', forecast_step) AS forecast_period,
    ROUND(avg_run_rate, 2)                                      AS run_rate_base,
    ROUND(forecast_amount, 2)                                   AS projected_amount,
    ROUND(forecast_amount - avg_run_rate, 2)                    AS growth_vs_base,
    ROUND((forecast_amount - avg_run_rate)
          / NULLIF(avg_run_rate, 0) * 100, 1)                   AS growth_pct,
    'Run Rate + 2% MoM Growth'                                  AS forecast_method
FROM forecast
ORDER BY dept_name, category_name, forecast_step;
