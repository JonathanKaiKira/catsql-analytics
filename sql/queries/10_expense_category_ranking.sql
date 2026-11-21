-- ¿Qué posiciones ocupan los gatos dentro de cada categoría?
-- Técnica: RANK, DENSE_RANK.
WITH totals AS (
    SELECT c.cat_code, e.category, SUM(e.amount_clp) AS total_clp
    FROM catdb.expenses AS e JOIN catdb.cats AS c USING (cat_id)
    GROUP BY c.cat_code, e.category
)
SELECT *, RANK() OVER w AS rank, DENSE_RANK() OVER w AS dense_rank
FROM totals
WINDOW w AS (PARTITION BY category ORDER BY total_clp DESC)
ORDER BY category, rank, cat_code;
