-- ¿Cuál es el percentil 75 del importe por tipo de gasto?
-- Técnica: PERCENTILE_CONT, HAVING.
SELECT category, COUNT(*) AS samples,
       ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount_clp)::numeric, 2) AS p75_clp
FROM catdb.expenses
GROUP BY category HAVING COUNT(*) >= 2
ORDER BY category;
