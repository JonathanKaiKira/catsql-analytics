-- ¿Cuántas visitas tienen seguimiento programado?
-- Técnica: COUNT FILTER, LEFT JOIN.
SELECT c.cat_code, COUNT(v.visit_id) AS visits,
       COUNT(v.visit_id) FILTER (WHERE v.follow_up_on IS NOT NULL) AS visits_with_follow_up
FROM catdb.cats AS c LEFT JOIN catdb.vet_visits AS v USING (cat_id)
GROUP BY c.cat_code ORDER BY c.cat_code;
