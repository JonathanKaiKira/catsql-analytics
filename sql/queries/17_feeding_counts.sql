-- ¿Cuántos registros de comida húmeda y seca tiene cada gato?
-- Técnica: LEFT JOIN, agregación condicional.
SELECT c.cat_code, COUNT(f.feeding_id) AS feedings,
       COUNT(f.feeding_id) FILTER (WHERE d.food_type = 'wet') AS wet,
       COUNT(f.feeding_id) FILTER (WHERE d.food_type = 'dry') AS dry
FROM catdb.cats AS c
LEFT JOIN catdb.feedings AS f USING (cat_id)
LEFT JOIN catdb.foods AS d USING (food_id)
GROUP BY c.cat_code ORDER BY c.cat_code;
