# Planes y medición de rendimiento

La consulta suma `amount_clp` para un gato y siete días. Su filtro usa igualdad sobre `cat_id` y un rango sobre `incurred_on`. El orden de esas columnas en el B-tree permite acotar la búsqueda por gato y fecha. La tabla temporal reproduce las columnas y restricciones de fila de `catdb.expenses`. Dispone de sus propias claves sintéticas de prueba y queda aislada de las tablas de demostración.

## Reproducción

Inicia CatSQL y ejecuta completo [benchmark.sql](../sql/performance/benchmark.sql) en una sesión de DBeaver. Desde Fedora, con la instancia predeterminada, también puedes ejecutar:

```bash
podman exec -i catsql-analytics-demo psql -X -v ON_ERROR_STOP=1 -U catsql_dev -d catsql < sql/performance/benchmark.sql
```

Para comparar escalas, ajusta el segundo límite de `generate_series`, por ejemplo a 60.000 o 240.000 filas. El valor de referencia es 120.000. `ANALYZE` actualiza las estadísticas antes y después de crear el índice. El script muestra un `EXPLAIN` estimado y luego `EXPLAIN (ANALYZE, BUFFERS)`, que ejecuta las consultas y recoge tiempos y accesos a bloques. `ROLLBACK` revierte la carga temporal y el índice.

## Ejecución observada

PostgreSQL 17.12 en Podman 6.1.3, Fedora 45. Escala de 120.000 filas, 128 claves sintéticas, 20 coincidencias y una selectividad del 0,0167 %. Se ejecutó el script completo una vez para este registro. Los tiempos provienen de `Execution Time`.

| Consulta | Plan observado | Tiempo | Evidencia |
| --- | --- | ---: | --- |
| Agregado sin índice | `Seq Scan` | 7,097 ms | 924 bloques locales encontrados y 119.980 filas descartadas |
| Mismo agregado con índice | `Bitmap Index Scan` y `Bitmap Heap Scan` | 0,078 ms | 20 bloques exactos de heap y 20 filas recuperadas |
| Rango ordenado con `LIMIT 10` | `Index Scan` | 0,019 ms | Usa el orden de `benchmark_expenses_cat_date_idx` y se detiene en 10 filas |
| Agregado con resta de fechas | `Bitmap Index Scan` y filtro de fecha en el heap | 0,650 ms | El índice reduce a 938 por gato; el filtro posterior descarta 918 |

El agregado por rango y la resta sobre la fecha devuelven **373.796 CLP**. La resta aplica una expresión a la columna, por lo que en la ejecución observada `Index Cond` solo incluye el gato. En la consulta por rango, incluye también las fechas. El planificador estimó 18 coincidencias para el agregado indexado y observó 20.

## Límites

Las cifras reflejan una sesión con tabla temporal y un conjunto sintético. El orden de ejecución, la caché, la distribución y la escala influyen en las mediciones. El coste de construir y mantener el índice queda fuera de `Execution Time` de cada consulta. Las tablas persistentes y la concurrencia pueden producir otros planes. CI comprueba la equivalencia del importe, sin exigir tiempos ni tipos de escaneo.
