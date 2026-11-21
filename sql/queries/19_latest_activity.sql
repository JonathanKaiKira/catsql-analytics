-- ¿Cuál es la actividad más reciente de cada gato?
-- Técnica: LEFT JOIN LATERAL, ORDER BY, LIMIT.
SELECT c.cat_code, a.occurred_at AT TIME ZONE 'UTC' AS occurred_utc, a.activity_type
FROM catdb.cats AS c
LEFT JOIN LATERAL (
    SELECT occurred_at, activity_type
    FROM catdb.activities WHERE cat_id = c.cat_id
    ORDER BY occurred_at DESC, activity_id DESC LIMIT 1
) AS a ON true
ORDER BY c.cat_code;
