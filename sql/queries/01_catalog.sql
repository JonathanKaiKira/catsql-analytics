-- ¿Qué gatos tienen fecha de nacimiento conocida?
-- Técnica: SELECT, WHERE, ORDER BY.
SELECT cat_code, name, birth_date
FROM catdb.cats
WHERE birth_date IS NOT NULL
ORDER BY cat_code;
