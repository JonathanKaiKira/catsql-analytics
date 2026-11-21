-- ¿Qué gatos no tienen gastos registrados?
-- Técnica: NOT EXISTS.
SELECT c.cat_code
FROM catdb.cats AS c
WHERE NOT EXISTS (SELECT 1 FROM catdb.expenses AS e WHERE e.cat_id = c.cat_id)
ORDER BY c.cat_code;
