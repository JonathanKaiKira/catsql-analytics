-- ¿Qué gatos superan el gasto medio entre gatos con gastos?
-- Técnica: CTE, CASE, EXISTS.
WITH totals AS (
    SELECT c.cat_id, c.cat_code, COALESCE(SUM(e.amount_clp), 0) AS amount
    FROM catdb.cats AS c LEFT JOIN catdb.expenses AS e USING (cat_id)
    GROUP BY c.cat_id, c.cat_code
), baseline AS (
    SELECT AVG(t.amount) AS mean_clp FROM totals AS t
    WHERE EXISTS (SELECT 1 FROM catdb.expenses AS e WHERE e.cat_id = t.cat_id)
)
SELECT cat_code, amount,
       CASE WHEN amount = 0 THEN 'missing'
            WHEN amount > mean_clp THEN 'above_mean' ELSE 'at_or_below_mean' END AS spending_signal
FROM totals CROSS JOIN baseline ORDER BY cat_code;
