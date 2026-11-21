INSERT INTO catdb.cats (cat_code, name, birth_date, coat) VALUES
    ('LUNA', 'Luna', '2022-04-12', 'negro'),
    ('MILO', 'Milo', '2021-09-02', 'atigrado naranja'),
    ('NUBE', 'Nube', NULL, 'blanco'),
    ('PIPA', 'Pipa', '2024-03-14', 'gris');

INSERT INTO catdb.caregivers (alias) VALUES ('Casa Norte'), ('Casa Sur'), ('Apoyo A');
INSERT INTO catdb.cat_caregivers (cat_id, caregiver_id, role)
SELECT c.cat_id, r.caregiver_id, s.role
FROM (VALUES ('LUNA', 'Casa Norte', 'owner'), ('LUNA', 'Apoyo A', 'caregiver'),
             ('MILO', 'Casa Norte', 'owner'), ('NUBE', 'Casa Sur', 'owner'))
    AS s(cat_code, alias, role)
JOIN catdb.cats AS c USING (cat_code)
JOIN catdb.caregivers AS r USING (alias);

INSERT INTO catdb.foods (name, food_type) VALUES ('Húmedo A', 'wet'), ('Seco B', 'dry');
INSERT INTO catdb.feedings (cat_id, food_id, fed_at, grams)
SELECT c.cat_id, f.food_id, s.fed_at::timestamptz, s.grams
FROM (VALUES ('LUNA', 'Húmedo A', '2030-05-10 12:00+00', 85),
             ('LUNA', 'Seco B', '2030-05-10 20:00+00', 30),
             ('MILO', 'Seco B', '2030-05-10 12:00+00', 45),
             ('MILO', 'Húmedo A', '2030-05-11 12:00+00', 75),
             ('NUBE', 'Húmedo A', '2030-05-11 12:00+00', 80))
    AS s(cat_code, food_name, fed_at, grams)
JOIN catdb.cats AS c USING (cat_code)
JOIN catdb.foods AS f ON f.name = s.food_name;

INSERT INTO catdb.weights (cat_id, measured_on, grams)
SELECT c.cat_id, s.measured_on::date, s.grams
FROM (VALUES ('LUNA', '2030-03-01', 4100), ('LUNA', '2030-04-01', 4200),
             ('LUNA', '2030-05-01', 4150), ('MILO', '2030-04-01', 5200),
             ('MILO', '2030-05-01', 5150), ('NUBE', '2030-05-01', 3600))
    AS s(cat_code, measured_on, grams)
JOIN catdb.cats AS c USING (cat_code);

INSERT INTO catdb.vet_visits (cat_id, visited_on, reason, follow_up_on)
SELECT c.cat_id, s.visited_on::date, s.reason, s.follow_up_on::date
FROM (VALUES ('LUNA', '2030-04-05', 'Control general', NULL),
             ('LUNA', '2030-05-03', 'Registro preventivo', '2030-06-03'),
             ('MILO', '2030-05-08', 'Consulta de seguimiento', '2030-06-08'),
             ('NUBE', '2030-05-09', 'Primera consulta', NULL))
    AS s(cat_code, visited_on, reason, follow_up_on)
JOIN catdb.cats AS c USING (cat_code);

INSERT INTO catdb.vaccines (name) VALUES ('Vacuna ficticia A'), ('Vacuna ficticia B');
INSERT INTO catdb.vaccinations (visit_id, vaccine_id)
SELECT v.visit_id, x.vaccine_id
FROM catdb.vet_visits AS v
JOIN catdb.cats AS c USING (cat_id)
JOIN catdb.vaccines AS x ON x.name = 'Vacuna ficticia A'
WHERE c.cat_code = 'LUNA' AND v.visited_on = DATE '2030-05-03';

INSERT INTO catdb.medications (name) VALUES ('Medicamento ficticio A'), ('Medicamento ficticio B');
INSERT INTO catdb.treatments (visit_id, medication_id, started_on, ended_on)
SELECT v.visit_id, m.medication_id, DATE '2030-05-08', DATE '2030-05-12'
FROM catdb.vet_visits AS v
JOIN catdb.cats AS c USING (cat_id)
JOIN catdb.medications AS m ON m.name = 'Medicamento ficticio A'
WHERE c.cat_code = 'MILO' AND v.visited_on = DATE '2030-05-08';

INSERT INTO catdb.expenses (cat_id, incurred_on, category, amount_clp)
SELECT c.cat_id, s.incurred_on::date, s.category, s.amount_clp
FROM (VALUES ('LUNA', '2030-05-01', 'food', 10000), ('LUNA', '2030-05-03', 'vet', 25000),
             ('MILO', '2030-05-08', 'vet', 18000), ('MILO', '2030-05-11', 'food', 8000),
             ('NUBE', '2030-05-09', 'supplies', 9000))
    AS s(cat_code, incurred_on, category, amount_clp)
JOIN catdb.cats AS c USING (cat_code);

INSERT INTO catdb.activities (cat_id, occurred_at, activity_type, note)
SELECT c.cat_id, s.occurred_at::timestamptz, s.activity_type, s.note
FROM (VALUES ('LUNA', '2030-05-10 18:00+00', 'play', 'Jugó con una pelota'),
             ('MILO', '2030-05-10 20:00+00', 'rest', 'Durmió en la manta'),
             ('NUBE', '2030-05-11 18:00+00', 'observation', 'Exploró una caja'))
    AS s(cat_code, occurred_at, activity_type, note)
JOIN catdb.cats AS c USING (cat_code);
