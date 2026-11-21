-- ¿Cómo se acumula el gasto por gato?
-- Técnica: SUM OVER, PARTITION BY, ROWS.
SELECT c.cat_code, e.incurred_on, e.amount_clp,
       SUM(e.amount_clp) OVER (
           PARTITION BY e.cat_id ORDER BY e.incurred_on, e.expense_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_clp
FROM catdb.expenses AS e JOIN catdb.cats AS c USING (cat_id)
ORDER BY c.cat_code, e.incurred_on, e.expense_id;
