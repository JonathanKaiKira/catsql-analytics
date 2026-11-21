-- ¿Cuánto pesa cada categoría en el gasto registrado?
-- Técnica: SUM OVER, NULLIF.
SELECT category, SUM(amount_clp) AS total_clp,
       ROUND(100 * SUM(amount_clp) / NULLIF(SUM(SUM(amount_clp)) OVER (), 0), 2) AS share_pct
FROM catdb.expenses
GROUP BY category
ORDER BY total_clp DESC, category;
