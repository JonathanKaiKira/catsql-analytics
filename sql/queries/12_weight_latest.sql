-- ¿Cuál es el último peso conocido de cada gato?
-- Técnica: Subconsulta correlacionada, LEFT JOIN.
SELECT c.cat_code, w.measured_on, w.grams
FROM catdb.cats AS c
LEFT JOIN catdb.weights AS w ON w.cat_id = c.cat_id AND w.measured_on = (
    SELECT MAX(w2.measured_on) FROM catdb.weights AS w2 WHERE w2.cat_id = c.cat_id
)
ORDER BY c.cat_code;
