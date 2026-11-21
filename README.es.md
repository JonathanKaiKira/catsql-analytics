[English](README.md) | **Español**

# CatSQL Analytics

CatSQL Analytics es el segundo proyecto del portafolio CatHub. Utiliza PostgreSQL 17 para convertir registros ficticios de cuidado de gatos en informes reproducibles sobre gastos, peso, alimentación, visitas veterinarias y actividad.

## Problema de negocio y objetivos técnicos

Los registros de cuidado tienen distintos niveles de detalle. Un gato puede tener varias visitas, mediciones y gastos, y algunos gatos carecen de registros en un dominio. CatSQL concilia estas diferencias antes de unir las métricas. Los informes distinguen observaciones ausentes, actividad nula y tasas indefinidas. El proyecto también mide cómo un índice B-tree compuesto cambia el plan de una consulta selectiva.

## Tecnologías, arquitectura y modelo de datos

PostgreSQL 17 se ejecuta en un contenedor Linux independiente con un volumen nombrado. Podman y Bash administran el entorno en Fedora. Docker Desktop y PowerShell 7 lo administran en Windows. DBeaver Community permite editar SQL, explorar resultados, exportar CSV e inspeccionar planes.

Las 13 tablas de `catdb` provienen del [commit 6478aaf de CatDB](https://github.com/JonathanKaiKira/catdb-postgresql/tree/6478aaf106faa590f4b5d1d999827a3fb8170ad3). CatSQL agrega dos gastos sintéticos para comprobar empates y cuatro vistas en `analytics`. El laboratorio de rendimiento usa una tabla temporal de sesión. La instalación funciona de manera independiente de CatDB. Consulta la [arquitectura y procedencia](docs/arquitectura.md).

## Análisis

El [catálogo de consultas](docs/consultas.md) reúne 23 consultas independientes. Incluye uniones, agregaciones, subconsultas correlacionadas, CTE, rangos de fechas, ventanas, conteos condicionales y percentiles. Cada consulta enlaza a su salida esperada. Ejecuta `22_cat_summary.sql` para ver una fila por gato. En la muestra estándar, Luna tiene 47.000 CLP de gastos y su último peso registrado es de 4.150 g. Pipa tiene cero gastos registrados y su peso es desconocido.

## Instalación en Windows 11

Instala [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) e inícialo en modo de contenedores Linux. Instala Git y PowerShell 7 y abre una nueva terminal de PowerShell 7.

```powershell
winget install --exact --id Git.Git
winget install --exact --id Microsoft.PowerShell
docker info --format '{{.OSType}}'
git clone https://github.com/JonathanKaiKira/catsql-analytics.git
cd catsql-analytics
.\scripts\demo.ps1 start
.\scripts\demo.ps1 info
.\scripts\demo.ps1 test
.\scripts\demo.ps1 stop
```

La comprobación de Docker debe mostrar `linux`. Si una política local bloquea los scripts, usa `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned` desde el clon de confianza cuando tu organización lo permita.

## Instalación en Fedora/Linux

Usa Podman con tu usuario habitual. En otras distribuciones, instala Git, Podman, Bash y util-linux con el gestor de paquetes.

```bash
sudo dnf install git podman
podman info
git clone https://github.com/JonathanKaiKira/catsql-analytics.git
cd catsql-analytics
./scripts/demo.sh start
./scripts/demo.sh info
./scripts/demo.sh test
./scripts/demo.sh stop
```

## Uso y rendimiento

Conecta DBeaver mientras esté iniciada la demostración. Usa host `127.0.0.1`, puerto `55442`, base `catsql`, usuario `catsql_dev` y la contraseña generada del archivo privado que indica `info`. Selecciona PostgreSQL y descarga el controlador JDBC si se solicita. Abre `sql/queries/22_cat_summary.sql` con la conexión CatSQL y pulsa `Ctrl+Enter`. Para exportar el resultado, elige **Export Data** en la cuadrícula y selecciona CSV. Consulta la [guía de operación y DBeaver](docs/operacion.md).

Abre `sql/performance/benchmark.sql` y ejecuta el script completo en una sesión. Genera 120.000 filas temporales, mide la misma agregación antes y después de crear un índice y compara predicados equivalentes. Los cambios se revierten al final. Consulta los [planes medidos y sus límites](docs/rendimiento.md).

## Pruebas y ciclo de datos

`test` se ejecuta en un contenedor aislado sin red. Comprueba las 13 tablas base, las restricciones, las filas de todas las consultas, las vistas y la equivalencia de la prueba de rendimiento. `stop` conserva los datos. Para usar otra instancia limpia, define `CATSQL_INSTANCE=catsql-practice` y un `CATSQL_PORT` libre, y conserva los mismos valores para reiniciarla. GitHub Actions también prueba el ciclo PowerShell con Docker en Ubuntu, además de sintaxis y argumentos en Windows.

## Estructura del repositorio

| Ruta | Contenido |
| --- | --- |
| `sql/base/` | Esquema versionado de CatDB y datos ficticios |
| `sql/03_analytics.sql` | Datos adicionales y cuatro vistas |
| `sql/queries/` | 23 consultas analíticas |
| `sql/performance/` | Comparación de planes |
| `tests/` | Pruebas de integridad y resultados esperados |
| `scripts/` | Puntos de entrada Bash y PowerShell |
| `docs/` | Arquitectura, catálogo de consultas, operación y mediciones |

## Proyecto relacionado, licencia y autor

[CatDB](https://github.com/JonathanKaiKira/catdb-postgresql) proporciona el modelo relacional. CatSQL Analytics es mantenido por Jonathan Curiñan como parte de CatHub bajo la [licencia MIT](LICENSE).
