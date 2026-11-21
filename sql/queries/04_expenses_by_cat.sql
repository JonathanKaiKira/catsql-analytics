-- ¿Cuánto se ha gastado por gato?
-- Técnica: LEFT JOIN, GROUP BY, COALESCE.
SELECT c.cat_code, COALESCE(SUM(e.amount_clp), 0) AS total_clp
FROM catdb.cats AS c
LEFT JOIN catdb.expenses AS e USING (cat_id)
GROUP BY c.cat_code
ORDER BY c.cat_code;
