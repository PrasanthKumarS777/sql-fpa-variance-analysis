-- ============================================================
-- ANALYSIS 3: Department P&L Pivot + Overspend Ranking
-- Skills: DENSE_RANK(), CASE WHEN pivot, GROUP BY ROLLUP
-- Business Use: Which dept is bleeding the most budget? 
-- ============================================================

USE fpa_variance_db;

-- ─────────────────────────────────────────
-- PART A: Department P&L Pivot by Category
-- Pivots categories into columns per dept
-- ─────────────────────────────────────────
WITH dept_category_totals AS (
    SELECT
        dp.dept_name,
        dd.fiscal_year,
        dc.category_name,
        SUM(ft.budget_amount) AS total_budget,
        SUM(ft.actual_amount) AS total_actual
    FROM fact_transactions ft
    JOIN dim_date       dd ON ft.date_id     = dd.date_id
    JOIN dim_department dp ON ft.dept_id     = dp.dept_id
    JOIN dim_category   dc ON ft.category_id = dc.category_id
    GROUP BY dp.dept_name, dd.fiscal_year, dc.category_name
)
SELECT
    dept_name,
    fiscal_year,
    -- Budget Pivot
    ROUND(SUM(CASE WHEN category_name = 'Salaries'       THEN total_budget ELSE 0 END), 2) AS salaries_budget,
    ROUND(SUM(CASE WHEN category_name = 'Marketing'      THEN total_budget ELSE 0 END), 2) AS marketing_budget,
    ROUND(SUM(CASE WHEN category_name = 'Infrastructure' THEN total_budget ELSE 0 END), 2) AS infra_budget,
    ROUND(SUM(CASE WHEN category_name = 'Travel'         THEN total_budget ELSE 0 END), 2) AS travel_budget,
    ROUND(SUM(CASE WHEN category_name = 'Utilities'      THEN total_budget ELSE 0 END), 2) AS utilities_budget,
    ROUND(SUM(CASE WHEN category_name = 'Training'       THEN total_budget ELSE 0 END), 2) AS training_budget,
    ROUND(SUM(total_budget), 2)                                                             AS total_budget,
    -- Actual Pivot
    ROUND(SUM(CASE WHEN category_name = 'Salaries'       THEN total_actual ELSE 0 END), 2) AS salaries_actual,
    ROUND(SUM(CASE WHEN category_name = 'Marketing'      THEN total_actual ELSE 0 END), 2) AS marketing_actual,
    ROUND(SUM(CASE WHEN category_name = 'Infrastructure' THEN total_actual ELSE 0 END), 2) AS infra_actual,
    ROUND(SUM(CASE WHEN category_name = 'Travel'         THEN total_actual ELSE 0 END), 2) AS travel_actual,
    ROUND(SUM(CASE WHEN category_name = 'Utilities'      THEN total_actual ELSE 0 END), 2) AS utilities_actual,
    ROUND(SUM(CASE WHEN category_name = 'Training'       THEN total_actual ELSE 0 END), 2) AS training_actual,
    ROUND(SUM(total_actual), 2)                                                             AS total_actual,
    -- Overall Variance
    ROUND(SUM(total_actual - total_budget), 2)                                              AS total_variance,
    ROUND(SUM(total_actual - total_budget) / NULLIF(SUM(total_budget), 0) * 100, 1)        AS variance_pct
FROM dept_category_totals
GROUP BY dept_name, fiscal_year
ORDER BY fiscal_year, total_variance DESC;


-- ─────────────────────────────────────────
-- PART B: Top Overspending Departments
-- Ranked per year using DENSE_RANK()
-- ─────────────────────────────────────────
WITH dept_variance AS (
    SELECT
        dd.fiscal_year,
        dp.dept_name,
        dc.category_name,
        ROUND(SUM(ft.actual_amount - ft.budget_amount), 2) AS variance_amount,
        ROUND(SUM(ft.actual_amount - ft.budget_amount) /
              NULLIF(SUM(ft.budget_amount), 0) * 100, 1)   AS variance_pct
    FROM fact_transactions ft
    JOIN dim_date       dd ON ft.date_id     = dd.date_id
    JOIN dim_department dp ON ft.dept_id     = dp.dept_id
    JOIN dim_category   dc ON ft.category_id = dc.category_id
    GROUP BY dd.fiscal_year, dp.dept_name, dc.category_name
)
SELECT
    fiscal_year,
    dept_name,
    category_name,
    variance_amount,
    CONCAT(variance_pct, '%') AS variance_pct,
    DENSE_RANK() OVER (
        PARTITION BY fiscal_year
        ORDER BY variance_amount DESC
    )                         AS overspend_rank,
    CASE
        WHEN variance_pct > 50  THEN '🚨 Escalate to CFO'
        WHEN variance_pct > 20  THEN '🔴 Needs Review'
        WHEN variance_pct > 0   THEN '🟡 Monitor'
        ELSE                         '🟢 Favourable'
    END                       AS action_required
FROM dept_variance
ORDER BY fiscal_year, overspend_rank
LIMIT 30;
