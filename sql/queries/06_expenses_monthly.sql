-- ¿Cuánto se gasta cada mes del segundo trimestre de 2030?
-- Técnica: DATE_TRUNC, generate_series, LEFT JOIN.
WITH months AS (
    SELECT month::date FROM generate_series(DATE '2030-04-01', DATE '2030-06-01', INTERVAL '1 month') AS m(month)
), totals AS (
    SELECT DATE_TRUNC('month', incurred_on::timestamp)::date AS month, SUM(amount_clp) AS total
    FROM catdb.expenses
    WHERE incurred_on >= DATE '2030-04-01' AND incurred_on < DATE '2030-07-01'
    GROUP BY 1
)
SELECT months.month, COALESCE(totals.total, 0) AS total_clp
FROM months LEFT JOIN totals USING (month)
ORDER BY months.month;
