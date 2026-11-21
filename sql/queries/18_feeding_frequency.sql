-- ¿Cuántas tomas por día observado tiene cada gato?
-- Técnica: COUNT DISTINCT, UTC, NULLIF.
SELECT c.cat_code, COUNT(f.feeding_id) AS feedings,
       COUNT(DISTINCT (f.fed_at AT TIME ZONE 'UTC')::date) AS observed_days,
       ROUND(COUNT(f.feeding_id)::numeric /
             NULLIF(COUNT(DISTINCT (f.fed_at AT TIME ZONE 'UTC')::date), 0), 2) AS per_observed_day
FROM catdb.cats AS c LEFT JOIN catdb.feedings AS f USING (cat_id)
GROUP BY c.cat_code ORDER BY c.cat_code;
