-- ¿Cómo cambia el peso entre mediciones y cuál es el promedio móvil?
-- Técnica: LAG, AVG OVER, ROWS.
SELECT c.cat_code, w.measured_on, w.grams,
       w.grams - LAG(w.grams) OVER series AS delta_grams,
       ROUND(AVG(w.grams) OVER (series ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_grams
FROM catdb.weights AS w JOIN catdb.cats AS c USING (cat_id)
WINDOW series AS (PARTITION BY w.cat_id ORDER BY w.measured_on)
ORDER BY c.cat_code, w.measured_on;
