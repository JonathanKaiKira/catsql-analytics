-- Run as a complete script in one session. Closing the session also drops the temporary table.
-- Scale by editing the bounded row count below. The default is 120,000 rows.
BEGIN;
CREATE TEMP TABLE benchmark_expenses (LIKE catdb.expenses INCLUDING CONSTRAINTS) ON COMMIT DROP;

INSERT INTO benchmark_expenses (expense_id, cat_id, incurred_on, category, amount_clp)
SELECT n, 1 + (n * 37) % 128, DATE '2030-01-01' + ((n * 13) % 365)::int,
       (ARRAY['food', 'vet', 'supplies'])[1 + n % 3], (1000 + n % 50000)::int
FROM generate_series(1::bigint, 120000::bigint) AS rows(n);

ANALYZE benchmark_expenses;
SELECT COUNT(*) AS rows, COUNT(*) FILTER (
    WHERE cat_id = 42 AND incurred_on >= DATE '2030-05-01' AND incurred_on < DATE '2030-05-08'
) AS matching_rows FROM benchmark_expenses;

-- Same result before and after the index. No planner settings are overridden.
EXPLAIN
SELECT SUM(amount_clp) FROM benchmark_expenses
WHERE cat_id = 42 AND incurred_on >= DATE '2030-05-01' AND incurred_on < DATE '2030-05-08';

EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(amount_clp) FROM benchmark_expenses
WHERE cat_id = 42 AND incurred_on >= DATE '2030-05-01' AND incurred_on < DATE '2030-05-08';

CREATE INDEX benchmark_expenses_cat_date_idx ON benchmark_expenses (cat_id, incurred_on);
ANALYZE benchmark_expenses;

EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(amount_clp) FROM benchmark_expenses
WHERE cat_id = 42 AND incurred_on >= DATE '2030-05-01' AND incurred_on < DATE '2030-05-08';

-- Equality on a single cat and an ordered range with a small LIMIT.
EXPLAIN (ANALYZE, BUFFERS)
SELECT incurred_on, amount_clp FROM benchmark_expenses
WHERE cat_id = 42 AND incurred_on >= DATE '2030-05-01'
ORDER BY incurred_on LIMIT 10;

-- Equivalent rewrite for this date column; the predicate applies a function to each row.
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(amount_clp) FROM benchmark_expenses
WHERE cat_id = 42 AND incurred_on - DATE '2030-05-01' BETWEEN 0 AND 6;

SELECT
    SUM(amount_clp) FILTER (WHERE incurred_on >= DATE '2030-05-01' AND incurred_on < DATE '2030-05-08') AS range_total,
    SUM(amount_clp) FILTER (WHERE incurred_on - DATE '2030-05-01' BETWEEN 0 AND 6) AS expression_total
FROM benchmark_expenses WHERE cat_id = 42;
ROLLBACK;
