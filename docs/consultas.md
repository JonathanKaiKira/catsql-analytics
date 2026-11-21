# Catálogo analítico

Los gastos están en CLP, los pesos en gramos y los eventos con hora se agrupan en UTC. Los cortes de 2030 son deliberados. Cada consulta se ejecuta por separado sobre la muestra versionada. `<NULL>` representa un dato ausente en las salidas de referencia.

## 01 catalog · Básico

¿Qué gatos tienen fecha de nacimiento conocida?

Tablas: `cats`. Técnica principal: SELECT, WHERE, ORDER BY. La fecha es conocida para Luna, Milo y Pipa. Usar = NULL pierde el control de valores desconocidos.

[Código SQL](../sql/queries/01_catalog.sql) · [Resultado esperado](../tests/expected/01_catalog.tsv)

## 02 expense categories · Básico

¿Qué categorías de gasto están presentes?

Tablas: `expenses`. Técnica principal: DISTINCT. La muestra contiene food, supplies y vet. Un catálogo observado no indica todas las categorías permitidas.

[Código SQL](../sql/queries/02_expense_categories.sql) · [Resultado esperado](../tests/expected/02_expense_categories.tsv)

## 03 expenses missing · Básico

¿Qué gatos no tienen gastos registrados?

Tablas: `cats`, `expenses`. Técnica principal: NOT EXISTS. Pipa no tiene filas de gasto. Una fila ausente y un gasto de cero representan casos diferentes.

[Código SQL](../sql/queries/03_expenses_missing.sql) · [Resultado esperado](../tests/expected/03_expenses_missing.tsv)

## 04 expenses by cat · Intermedio

¿Cuánto se ha gastado por gato?

Tablas: `cats`, `expenses`. Técnica principal: LEFT JOIN, GROUP BY, COALESCE. Luna suma 47.000 CLP y Pipa aparece con cero. Agrupar por nombre podría unir gatos distintos.

[Código SQL](../sql/queries/04_expenses_by_cat.sql) · [Resultado esperado](../tests/expected/04_expenses_by_cat.tsv)

## 05 expenses by category · Intermedio

¿Cuánto pesa cada categoría en el gasto registrado?

Tablas: `expenses`. Técnica principal: SUM OVER, NULLIF. La categoría vet concentra 43.000 CLP y supplies alcanza 33.000 CLP. Usar división entera trunca los porcentajes.

[Código SQL](../sql/queries/05_expenses_by_category.sql) · [Resultado esperado](../tests/expected/05_expenses_by_category.tsv)

## 06 expenses monthly · Intermedio

¿Cuánto se gasta cada mes del segundo trimestre de 2030?

Tablas: `expenses`. Técnica principal: DATE_TRUNC, generate_series, LEFT JOIN. Abril y junio tienen cero; mayo suma 70.000 CLP. Agrupar solo eventos omite meses sin movimiento.

[Código SQL](../sql/queries/06_expenses_monthly.sql) · [Resultado esperado](../tests/expected/06_expenses_monthly.tsv)

## 07 expenses month change · Avanzado

¿Cuánto cambia el gasto respecto del mes anterior?

Tablas: `expenses`. Técnica principal: CTE, LAG, NULLIF. El cambio absoluto de mayo es 70.000 CLP y su variación porcentual es indefinida por la base cero. COALESCE aplicado al porcentaje confundiría indefinido con 0 %.

[Código SQL](../sql/queries/07_expenses_month_change.sql) · [Resultado esperado](../tests/expected/07_expenses_month_change.tsv)

## 08 expenses running · Avanzado

¿Cómo se acumula el gasto por gato?

Tablas: `cats`, `expenses`. Técnica principal: SUM OVER, PARTITION BY, ROWS. Luna pasa de 10.000 a 35.000 CLP. Sin expense_id, dos gastos en la misma fecha pueden quedar en orden indeterminado.

[Código SQL](../sql/queries/08_expenses_running.sql) · [Resultado esperado](../tests/expected/08_expenses_running.tsv)

## 09 highest expense · Avanzado

¿Cuál es el mayor gasto registrado por cada gato?

Tablas: `cats`, `expenses`. Técnica principal: ROW_NUMBER, LEFT JOIN. El máximo de Luna es 25.000 CLP y Pipa queda sin máximo. El desempate debe estar definido para elegir una sola fila.

[Código SQL](../sql/queries/09_highest_expense.sql) · [Resultado esperado](../tests/expected/09_highest_expense.tsv)

## 10 expense category ranking · Avanzado

¿Qué posiciones ocupan los gatos dentro de cada categoría?

Tablas: `cats`, `expenses`. Técnica principal: RANK, DENSE_RANK. Luna y Milo empatan en el primer lugar de supplies en la ampliación de muestra. Agregar cat_code al ORDER BY de la ventana rompería el empate.

[Código SQL](../sql/queries/10_expense_category_ranking.sql) · [Resultado esperado](../tests/expected/10_expense_category_ranking.tsv)

## 11 weight average · Intermedio

¿Cuál es el peso medio de los gatos con dos o más mediciones?

Tablas: `cats`, `weights`. Técnica principal: AVG, HAVING. Luna y Milo tienen historial suficiente para este filtro. HAVING filtra grupos; WHERE filtra mediciones antes de agrupar.

[Código SQL](../sql/queries/11_weight_average.sql) · [Resultado esperado](../tests/expected/11_weight_average.tsv)

## 12 weight latest · Intermedio

¿Cuál es el último peso conocido de cada gato?

Tablas: `cats`, `weights`. Técnica principal: Subconsulta correlacionada, LEFT JOIN. Pipa permanece visible con peso desconocido. MAX(grams) devolvería el peso más alto en vez del último.

[Código SQL](../sql/queries/12_weight_latest.sql) · [Resultado esperado](../tests/expected/12_weight_latest.tsv)

## 13 weight changes · Avanzado

¿Cómo cambia el peso entre mediciones y cuál es el promedio móvil?

Tablas: `cats`, `weights`. Técnica principal: LAG, AVG OVER, ROWS. El último cambio de Luna es −50 g. La primera fila de cada gato carece de cambio. Una ventana de tres filas describe tres mediciones, aunque estén irregularmente espaciadas.

[Código SQL](../sql/queries/13_weight_changes.sql) · [Resultado esperado](../tests/expected/13_weight_changes.tsv)

## 14 weight gaps · Avanzado

¿Dónde hay más de 30 días entre dos mediciones observadas?

Tablas: `cats`, `weights`. Técnica principal: LEAD, CTE, aritmética de fechas. Marzo a abril en Luna tiene 31 días. Los extremos sin dos mediciones quedan fuera. Un intervalo entre dos observaciones no mide retrasos después de la última.

[Código SQL](../sql/queries/14_weight_gaps.sql) · [Resultado esperado](../tests/expected/14_weight_gaps.tsv)

## 15 visit counts · Intermedio

¿Cuántas visitas tienen seguimiento programado?

Tablas: `cats`, `vet_visits`. Técnica principal: COUNT FILTER, LEFT JOIN. Luna tiene dos visitas y una fecha de seguimiento. Pipa tiene cero visitas. COUNT(*) sobre LEFT JOIN cuenta la fila de relleno.

[Código SQL](../sql/queries/15_visit_counts.sql) · [Resultado esperado](../tests/expected/15_visit_counts.tsv)

## 16 upcoming followups · Básico

¿Qué seguimientos hay en los 30 días desde el 15 de mayo de 2030?

Tablas: `cats`, `vet_visits`. Técnica principal: INNER JOIN, intervalo semiabierto. Aparecen Luna el 3 de junio y Milo el 8 de junio. CURRENT_DATE cambiaría el resultado de la muestra y BETWEEN incluiría el límite superior.

[Código SQL](../sql/queries/16_upcoming_followups.sql) · [Resultado esperado](../tests/expected/16_upcoming_followups.tsv)

## 17 feeding counts · Intermedio

¿Cuántos registros de comida húmeda y seca tiene cada gato?

Tablas: `cats`, `feedings`, `foods`. Técnica principal: LEFT JOIN, agregación condicional. Luna y Milo tienen una toma de cada tipo y Pipa tiene cero. Un filtro WHERE sobre foods eliminaría los gatos sin tomas.

[Código SQL](../sql/queries/17_feeding_counts.sql) · [Resultado esperado](../tests/expected/17_feeding_counts.tsv)

## 18 feeding frequency · Avanzado

¿Cuántas tomas por día observado tiene cada gato?

Tablas: `cats`, `feedings`. Técnica principal: COUNT DISTINCT, UTC, NULLIF. Luna tiene dos tomas en un día y Milo dos tomas en dos días. El denominador son días observados. Comparar con días calendario cambiaría la métrica.

[Código SQL](../sql/queries/18_feeding_frequency.sql) · [Resultado esperado](../tests/expected/18_feeding_frequency.tsv)

## 19 latest activity · Intermedio

¿Cuál es la actividad más reciente de cada gato?

Tablas: `cats`, `activities`. Técnica principal: LEFT JOIN LATERAL, ORDER BY, LIMIT. Las tres actividades observadas aparecen y Pipa queda sin actividad. Un ORDER BY global elegiría un evento para todo el conjunto.

[Código SQL](../sql/queries/19_latest_activity.sql) · [Resultado esperado](../tests/expected/19_latest_activity.tsv)

## 20 events by week · Intermedio

¿Cuántas actividades, tomas y visitas se registraron por semana ISO?

Tablas: `activities`, `feedings`, `vet_visits`. Técnica principal: UNION ALL, EXTRACT, DATE_TRUNC. Los eventos del 6 al 12 de mayo quedan en la misma semana. UNION descartaría coincidencias legítimas en el mismo día.

[Código SQL](../sql/queries/20_events_by_week.sql) · [Resultado esperado](../tests/expected/20_events_by_week.tsv)

## 21 spending signal · Intermedio

¿Qué gatos superan el gasto medio entre gatos con gastos?

Tablas: `cats`, `expenses`. Técnica principal: CTE, CASE, EXISTS. El promedio de referencia excluye a Pipa; Luna y Milo lo superan. Calcular la media después de sumar ceros cambiaría la población comparada.

[Código SQL](../sql/queries/21_spending_signal.sql) · [Resultado esperado](../tests/expected/21_spending_signal.tsv)

## 22 cat summary · Avanzado

¿Cuál es el estado consolidado de cada gato?

Tablas: `cats`, `expenses`, `weights`, `vet_visits`, `activities`. Técnica principal: CTE por granularidad, LEFT JOIN. El gasto de Luna se mantiene aunque tenga varias mediciones y visitas. Unir hechos antes de agregarlos causa multiplicación de filas.

[Código SQL](../sql/queries/22_cat_summary.sql) · [Resultado esperado](../tests/expected/22_cat_summary.tsv)

## 23 expense percentile · Avanzado

¿Cuál es el percentil 75 del importe por tipo de gasto?

Tablas: `expenses`. Técnica principal: PERCENTILE_CONT, HAVING. El resultado interpola entre gastos observados. Se exigen al menos dos registros por categoría. Un percentil estima una posición y puede devolver un importe que no aparece como fila.

[Código SQL](../sql/queries/23_expense_percentile.sql) · [Resultado esperado](../tests/expected/23_expense_percentile.tsv)
