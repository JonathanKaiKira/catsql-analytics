-- ¿Cuál es el estado consolidado de cada gato?
-- Técnica: CTE por granularidad, LEFT JOIN.
WITH spending AS (
    SELECT cat_id, SUM(amount_clp) AS total_clp FROM catdb.expenses GROUP BY cat_id
), latest_weight AS (
    SELECT DISTINCT ON (cat_id) cat_id, grams
    FROM catdb.weights ORDER BY cat_id, measured_on DESC
), visits AS (
    SELECT cat_id, COUNT(*) AS visits FROM catdb.vet_visits GROUP BY cat_id
), activity AS (
    SELECT cat_id, MAX(occurred_at) AS last_activity FROM catdb.activities GROUP BY cat_id
)
SELECT c.cat_code, COALESCE(s.total_clp, 0) AS total_clp, w.grams AS latest_grams,
       COALESCE(v.visits, 0) AS visits, a.last_activity AT TIME ZONE 'UTC' AS last_activity_utc
FROM catdb.cats AS c
LEFT JOIN spending AS s USING (cat_id)
LEFT JOIN latest_weight AS w USING (cat_id)
LEFT JOIN visits AS v USING (cat_id)
LEFT JOIN activity AS a USING (cat_id)
ORDER BY c.cat_code;
