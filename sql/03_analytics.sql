-- Tie for the category ranking, outside the reference quarter.
INSERT INTO catdb.expenses (cat_id, incurred_on, category, amount_clp)
SELECT cat_id, DATE '2030-07-02', 'supplies', 12000
FROM catdb.cats WHERE cat_code IN ('LUNA', 'MILO') ORDER BY cat_code;

CREATE SCHEMA analytics;

CREATE VIEW analytics.expenses_by_cat AS
SELECT c.cat_code, COUNT(e.expense_id) AS expense_count, COALESCE(SUM(e.amount_clp), 0) AS total_clp
FROM catdb.cats AS c LEFT JOIN catdb.expenses AS e USING (cat_id)
GROUP BY c.cat_code;

CREATE VIEW analytics.expenses_monthly AS
SELECT DATE_TRUNC('month', incurred_on::timestamp)::date AS month,
       COUNT(*) AS expense_count, SUM(amount_clp) AS total_clp
FROM catdb.expenses
GROUP BY 1;

CREATE VIEW analytics.weight_history AS
SELECT c.cat_code, w.measured_on, w.grams,
       w.grams - LAG(w.grams) OVER (PARTITION BY w.cat_id ORDER BY w.measured_on) AS delta_grams
FROM catdb.weights AS w JOIN catdb.cats AS c USING (cat_id);

CREATE VIEW analytics.latest_activity AS
SELECT DISTINCT ON (a.cat_id) c.cat_code, a.occurred_at, a.activity_type, a.note
FROM catdb.activities AS a JOIN catdb.cats AS c USING (cat_id)
ORDER BY a.cat_id, a.occurred_at DESC, a.activity_id DESC;
