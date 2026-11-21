-- ¿Qué seguimientos hay en los 30 días desde el 15 de mayo de 2030?
-- Técnica: INNER JOIN, intervalo semiabierto.
SELECT c.cat_code, v.follow_up_on
FROM catdb.vet_visits AS v JOIN catdb.cats AS c USING (cat_id)
WHERE v.follow_up_on >= DATE '2030-05-15'
  AND v.follow_up_on < DATE '2030-05-15' + INTERVAL '30 days'
ORDER BY v.follow_up_on, c.cat_code, v.visit_id;
