-- ¿Dónde hay más de 30 días entre dos mediciones observadas?
-- Técnica: LEAD, CTE, aritmética de fechas.
WITH series AS (
    SELECT cat_id, measured_on, LEAD(measured_on) OVER (PARTITION BY cat_id ORDER BY measured_on) AS next_on
    FROM catdb.weights
)
SELECT c.cat_code, s.measured_on, s.next_on, s.next_on - s.measured_on AS gap_days
FROM series AS s JOIN catdb.cats AS c USING (cat_id)
WHERE s.next_on - s.measured_on > 30
ORDER BY c.cat_code, s.measured_on;
