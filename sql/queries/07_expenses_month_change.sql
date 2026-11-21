-- ¿Cuánto cambia el gasto respecto del mes anterior?
-- Técnica: CTE, LAG, NULLIF.
WITH months AS (
    SELECT month::date FROM generate_series(DATE '2030-04-01', DATE '2030-06-01', INTERVAL '1 month') AS m(month)
), totals AS (
    SELECT m.month, COALESCE(SUM(e.amount_clp), 0) AS total_clp
    FROM months AS m
    LEFT JOIN catdb.expenses AS e
      ON e.incurred_on >= m.month AND e.incurred_on < m.month + INTERVAL '1 month'
    GROUP BY m.month
), compared AS (
    SELECT *, LAG(total_clp) OVER (ORDER BY month) AS previous_clp FROM totals
)
SELECT month, total_clp, total_clp - previous_clp AS delta_clp,
       ROUND(100.0 * (total_clp - previous_clp) / NULLIF(previous_clp, 0), 2) AS change_pct
FROM compared ORDER BY month;
