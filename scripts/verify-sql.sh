#!/usr/bin/env bash
set -euo pipefail
cd /tmp/catsql
run_sql() {
    psql -X -v ON_ERROR_STOP=1 -U postgres -d catsql "$@"
}
run_sql -q -1 -f sql/base/01_schema.sql -f sql/base/02_seed.sql
run_sql -q -f tests/base-integrity.sql >/dev/null
run_sql -q -1 -f sql/03_analytics.sql
run_sql -q -f tests/analytics.sql
count=0
for query in sql/queries/*.sql; do
    name="${query##*/}"
    actual="$(run_sql -qAt -F $'\t' -P 'null=<NULL>' -f "$query")"
    diff -u "tests/expected/${name%.sql}.tsv" - <<< "$actual"
    ((count += 1))
done
[[ "$count" -eq 23 ]]
benchmark="$(run_sql -qAt -F $'\t' -f sql/performance/benchmark.sql)"
read -r range_total expression_total <<< "$(tail -n 1 <<< "$benchmark")"
[[ "$range_total" =~ ^[1-9][0-9]*$ && "$range_total" == "$expression_total" ]]
echo "$count consultas comparadas. Esquema, integridad, vistas y equivalencia del benchmark verificados."
