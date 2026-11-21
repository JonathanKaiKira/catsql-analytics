-- ¿Cuántas actividades, tomas y visitas se registraron por semana ISO?
-- Técnica: UNION ALL, EXTRACT, DATE_TRUNC.
WITH events AS (
    SELECT (occurred_at AT TIME ZONE 'UTC')::date AS day, 'activity' AS kind FROM catdb.activities
    UNION ALL SELECT (fed_at AT TIME ZONE 'UTC')::date, 'feeding' FROM catdb.feedings
    UNION ALL SELECT visited_on, 'visit' FROM catdb.vet_visits
)
SELECT DATE_TRUNC('week', day::timestamp)::date AS week_start, EXTRACT(WEEK FROM day)::int AS iso_week,
       kind, COUNT(*) AS events
FROM events GROUP BY 1, 2, 3 ORDER BY 1, 3;
