# Operación y DBeaver

1. Instala [DBeaver Community](https://dbeaver.io/download/) con el instalador para Windows o el RPM de Fedora. Desde la carpeta de descarga en Fedora, usa `sudo dnf install ./archivo-descargado.rpm` con el nombre real del paquete.
2. Ejecuta `start` y `info` desde el script de tu sistema. Abre **Database → New Database Connection → PostgreSQL**.
3. Usa host `127.0.0.1`, puerto `55442`, base `catsql` y usuario `catsql_dev`. Copia solo el valor de `POSTGRES_PASSWORD` del archivo privado indicado por `info` en el campo de contraseña. Pulsa **Test Connection** y descarga JDBC si se solicita.
4. En **Database Navigator**, expande **Schemas → catdb → Tables** y **Schemas → analytics → Views**. Abre `sql/queries/10_expense_category_ranking.sql` y usa **Ctrl+Enter**. Compara `rank` y `dense_rank` de `supplies`. Ordena mediante las cabeceras de la cuadrícula o mediante el `ORDER BY` final. Revisa el [catálogo](consultas.md) para interpretar cada resultado.
5. Abre `sql/performance/benchmark.sql` con la misma conexión. Ejecuta todo con **SQL Editor → Execute SQL Script**. Revisa cada resultado de `EXPLAIN` y sus bloques de buffers en las pestañas de resultados. Ejecutar una sentencia aislada antes de crear la tabla temporal provocará un error de relación inexistente.
6. Desconecta DBeaver y ejecuta `stop`. Conserva el volumen y su credencial. Ejecuta `start` para retomar los datos.

Para exportar localmente, abre el menú contextual del resultado y elige **Export Data → CSV**. Guarda el archivo fuera de Git o usa la extensión `.csv`, que el repositorio ignora.

## Diagnóstico

- Si falla la conexión, comprueba que `start` haya terminado y usa la dirección de `info`. CatDB usa otro puerto, otro usuario y otro nombre de base.
- Si el puerto está ocupado, conserva la configuración de la instancia existente. Para una instancia limpia, en Bash usa `CATSQL_INSTANCE=catsql-practice CATSQL_PORT=55444 ./scripts/demo.sh start`. En PowerShell usa `$env:CATSQL_INSTANCE = 'catsql-practice'` y `$env:CATSQL_PORT = '55444'`, luego `.\scripts\demo.ps1 start`. Repite los valores para las demás operaciones de esa instancia.
- Si falta la credencial de un volumen existente, recupera su archivo original desde el respaldo. Una instancia nueva permite retomar el trabajo y conservar el volumen anterior.
- Si el motor está detenido, abre Docker Desktop en modo Linux o revisa `podman info`. Si PostgreSQL falla, consulta los registros del contenedor con `podman logs catsql-analytics-demo` o `docker logs catsql-analytics-demo`.
