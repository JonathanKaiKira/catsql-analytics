-- ¿Cuál es el mayor gasto registrado por cada gato?
-- Técnica: ROW_NUMBER, LEFT JOIN.
WITH ranked AS (
    SELECT e.*, ROW_NUMBER() OVER (
        PARTITION BY cat_id ORDER BY amount_clp DESC, incurred_on DESC, expense_id DESC
    ) AS position
    FROM catdb.expenses AS e
)
SELECT c.cat_code, r.category, r.amount_clp
FROM catdb.cats AS c LEFT JOIN ranked AS r ON r.cat_id = c.cat_id AND r.position = 1
ORDER BY c.cat_code;
