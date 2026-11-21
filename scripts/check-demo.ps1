#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$env:CATSQL_INSTANCE = 'catsql-ci-' + [Guid]::NewGuid().ToString('N')
$env:CATSQL_PORT = '55443'
$instance = $env:CATSQL_INSTANCE
$demo = Join-Path $PSScriptRoot demo.ps1

function Invoke-Demo($Action) {
    & (Get-Process -Id $PID).Path -NoProfile -File $demo $Action
    if ($LASTEXITCODE -ne 0) { throw "demo.ps1 $Action failed." }
}

function Invoke-Query($Sql) {
    & docker exec $instance psql -X -v ON_ERROR_STOP=1 -qAt -U catsql_dev -d catsql -c $Sql
    if ($LASTEXITCODE -ne 0) { throw 'Lifecycle SQL assertion failed to execute.' }
}

try {
    Invoke-Demo start
    Invoke-Demo info
    if ((Invoke-Query "SELECT count(*) FROM catdb.cats") -ne '4') { throw 'Expected four seeded cats.' }
    if ((Invoke-Query "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'catdb' AND table_type = 'BASE TABLE'") -ne '13') {
        throw 'Expected 13 tables.'
    }
    Invoke-Query 'CREATE TABLE public.lifecycle_marker (id integer PRIMARY KEY); INSERT INTO public.lifecycle_marker VALUES (1);'
    Invoke-Demo test
    Invoke-Demo stop
    Invoke-Demo stop
    Invoke-Demo info
    Invoke-Demo start
    if ((Invoke-Query "SELECT id FROM public.lifecycle_marker") -ne '1') { throw 'Restart lost the marker.' }
    Invoke-Demo stop
} finally {
    & docker container rm -f $instance
    & docker volume rm "$instance-data"
}
