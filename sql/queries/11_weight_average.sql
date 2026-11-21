-- ¿Cuál es el peso medio de los gatos con dos o más mediciones?
-- Técnica: AVG, HAVING.
SELECT c.cat_code, COUNT(*) AS measurements, ROUND(AVG(w.grams), 2) AS avg_grams
FROM catdb.weights AS w JOIN catdb.cats AS c USING (cat_id)
GROUP BY c.cat_code HAVING COUNT(*) >= 2
ORDER BY c.cat_code;
