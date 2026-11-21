**English** | [Español](README.es.md)

# CatSQL Analytics

CatSQL Analytics is the second CatHub portfolio project. It uses PostgreSQL 17 to turn fictional cat care records into reproducible reports on spending, weight, feeding, veterinary visits, and activity.

## Business problem and technical objectives

Cat care records originate at different levels of detail. A cat can have several visits, measurements, and expenses, and some cats have no records in a given domain. CatSQL reconciles these differences before joining metrics. Reports distinguish missing observations, zero activity, and undefined rates. The project also measures how a composite B-tree index changes a selective query plan.

## Stack, architecture, and data model

PostgreSQL 17 runs in an independent Linux container with a named volume. Podman and Bash handle the Fedora workflow. Docker Desktop and PowerShell 7 handle Windows. DBeaver Community provides a SQL editor, result grids, CSV export, and plan inspection.

The 13 base tables in `catdb` come from [CatDB commit 6478aaf](https://github.com/JonathanKaiKira/catdb-postgresql/tree/6478aaf106faa590f4b5d1d999827a3fb8170ad3). CatSQL adds two synthetic expense rows to exercise rank ties and four report views in `analytics`. The benchmark uses a session-scoped temporary table. Installation works independently of CatDB. See the [architecture and provenance](docs/arquitectura.md).

## Analysis

The [query catalog](docs/consultas.md) covers 23 standalone queries. It includes joins, aggregation, correlated subqueries, CTEs, date ranges, window functions, conditional counts, and percentiles. Each query links to its expected output. Run `22_cat_summary.sql` to see one row per cat. In the standard dataset, Luna has 47,000 CLP in expenses and a last recorded weight of 4,150 g. Pipa has zero reported expenses and an unknown weight.

## Windows 11 installation

Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) and start it in Linux container mode. Install Git and PowerShell 7, then open a fresh PowerShell 7 terminal.

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

The Docker check should print `linux`. If a local policy blocks scripts, use `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned` from the trusted clone, where organizational policy permits.

## Fedora/Linux installation

Use Podman as your normal user. On other distributions, install Git, Podman, Bash, and util-linux with your package manager.

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

## Usage and performance

Connect DBeaver while the demo is running. Use host `127.0.0.1`, port `55442`, database `catsql`, user `catsql_dev` and the generated password from the private file displayed by `info`. Select PostgreSQL and download the JDBC driver when prompted. Open `sql/queries/22_cat_summary.sql` in the CatSQL editor and press `Ctrl+Enter`. To export, use **Export Data** from the grid and choose CSV. See [operation and DBeaver](docs/operacion.md).

Open `sql/performance/benchmark.sql` and run the complete script in one session. It generates 120,000 temporary rows, measures the same aggregate before and after creating an index, and compares equivalent predicates. It rolls back the setup. See the [recorded plans and limitations](docs/rendimiento.md).

## Testing and data lifecycle

`test` runs on an isolated container with networking disabled. It checks the 13 base tables, constraints, all query rows, reporting views, and benchmark equivalence. `stop` keeps the data. To use a clean instance alongside the default one, set `CATSQL_INSTANCE=catsql-practice` and choose a free `CATSQL_PORT`, then keep the same values to restart it. GitHub Actions also runs the PowerShell lifecycle with Docker on Ubuntu and checks syntax and arguments on Windows.

## Repository structure

| Path | Contents |
| --- | --- |
| `sql/base/` | Pinned CatDB schema and fictional fixtures |
| `sql/03_analytics.sql` | Additional fixtures and four report views |
| `sql/queries/` | 23 analytical statements |
| `sql/performance/` | Side-by-side plan comparison |
| `tests/` | Integrity checks and expected query rows |
| `scripts/` | Bash and PowerShell entry points |
| `docs/` | Architecture, query catalog, operations, and measured results |

## Related project, license, and author

[CatDB](https://github.com/JonathanKaiKira/catdb-postgresql) provides the relational model. CatSQL Analytics is maintained by Jonathan Curiñan as part of CatHub under the [MIT License](LICENSE).
