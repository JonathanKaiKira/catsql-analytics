BEGIN;
SET LOCAL search_path TO catdb, pg_catalog;

CREATE FUNCTION pg_temp.expect_sqlstate(statement text, expected text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE statement;
    RAISE EXCEPTION 'Se esperaba SQLSTATE % para %', expected, statement;
EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> expected THEN
        RAISE;
    END IF;
END;
$$;

SELECT pg_temp.expect_sqlstate($$UPDATE cats SET cat_code = 'LUNA' WHERE cat_code = 'MILO'$$, '23505');
SELECT pg_temp.expect_sqlstate($$UPDATE cats SET name = NULL$$, '23502');
SELECT pg_temp.expect_sqlstate($$INSERT INTO cat_caregivers (cat_id, caregiver_id, role) SELECT cat_id, -1, 'owner' FROM cats WHERE cat_code = 'LUNA'$$, '23503');
SELECT pg_temp.expect_sqlstate($$INSERT INTO cat_caregivers SELECT * FROM cat_caregivers$$, '23505');
SELECT pg_temp.expect_sqlstate($$UPDATE cat_caregivers SET role = 'guest'$$, '23514');
SELECT pg_temp.expect_sqlstate($$UPDATE feedings SET food_id = -1$$, '23503');
SELECT pg_temp.expect_sqlstate($$UPDATE feedings SET grams = 0$$, '23514');
SELECT pg_temp.expect_sqlstate($$UPDATE weights SET grams = -1$$, '23514');
SELECT pg_temp.expect_sqlstate(
    $$INSERT INTO weights (cat_id, measured_on, grams)
      SELECT cat_id, measured_on, grams FROM weights LIMIT 1$$, '23505');
SELECT pg_temp.expect_sqlstate($$UPDATE vet_visits SET follow_up_on = visited_on$$, '23514');
SELECT pg_temp.expect_sqlstate($$INSERT INTO vaccinations SELECT * FROM vaccinations$$, '23505');
SELECT pg_temp.expect_sqlstate($$UPDATE vaccinations SET vaccine_id = -1$$, '23503');
SELECT pg_temp.expect_sqlstate($$UPDATE treatments SET ended_on = started_on - 1$$, '23514');
SELECT pg_temp.expect_sqlstate($$UPDATE treatments SET medication_id = -1$$, '23503');
SELECT pg_temp.expect_sqlstate($$UPDATE expenses SET amount_clp = -1$$, '23514');
SELECT pg_temp.expect_sqlstate($$UPDATE activities SET note = '  '$$, '23514');
SELECT pg_temp.expect_sqlstate($$DELETE FROM cats WHERE cat_code = 'LUNA'$$, '23503');

DO $$
BEGIN
    IF (SELECT count(*) FROM cats) <> 4
       OR (SELECT count(*) FROM activities) <> 3
       OR (SELECT count(*) FROM vet_visits WHERE follow_up_on IS NULL) <> 2 THEN
        RAISE EXCEPTION 'La muestra de gatos, actividades o seguimientos opcionales es incorrecta';
    END IF;
END;
$$;

ROLLBACK;
\echo 'Integridad verificada (17 rechazos esperados y 3 comprobaciones de muestra).'
