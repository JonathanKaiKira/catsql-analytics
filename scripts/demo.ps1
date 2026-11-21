#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('start', 'info', 'test', 'stop')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$instance = if ($env:CATSQL_INSTANCE) { $env:CATSQL_INSTANCE } else { 'catsql-analytics-demo' }
$port = if ($env:CATSQL_PORT) { $env:CATSQL_PORT } else { '55442' }
$volume = "$instance-data"
$label = 'io.cathub.project'
$project = 'catsql-analytics'
$image = 'docker.io/library/postgres:17'
$config = ".catsql/$instance.env"
$lock = $null

function Invoke-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) {
        throw "Docker failed during '$($args[0])' (exit $LASTEXITCODE). Review the Docker output above."
    }
}

function Wait-Database([string]$Container, [string]$User) {
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        & docker exec $Container sh -ec 'test $(cat /proc/1/comm) = postgres && pg_isready -q -U $1 -d catsql' sh $User 2>$null
        if ($LASTEXITCODE -eq 0) { return }
        Start-Sleep -Seconds 1
    }
    Invoke-Docker logs $Container | Out-Host
    throw 'PostgreSQL did not become ready in 60 attempts. Review the container logs.'
}

function Get-CatSqlContainer {
    $names = @(Invoke-Docker container ls -a --format '{{.Names}}')
    if ($instance -cin $names) {
        $result = (Invoke-Docker container inspect $instance | Out-String | ConvertFrom-Json)
        if ($result.Config.Labels.$label -cne $project) {
            throw "Container $instance does not belong to CatSQL. Choose a different CATSQL_INSTANCE."
        }
        return $result
    }
}

function Show-Connection($Container) {
    if ($null -eq $Container) { throw 'Start the instance with .\scripts\demo.ps1 start.' }
    $binding = $Container.HostConfig.PortBindings.'5432/tcp'
    Write-Output "Host: $($binding.HostIp)`nPort: $($binding.HostPort)`nDatabase: catsql`nUser: catsql_dev`nSchemas: catdb, analytics"
    Write-Output "Local credential: $(Join-Path (Get-Location) $config) (POSTGRES_PASSWORD)"
}

function Protect-ConfigDirectory {
    $directory = New-Item -ItemType Directory -Path .catsql -Force
    if ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Use a regular local .catsql directory for credentials.'
    }
    if ($IsWindows) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
        $acl = [System.Security.AccessControl.DirectorySecurity]::new()
        $acl.SetAccessRuleProtection($true, $false)
        $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
            $identity, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
        )
        $acl.AddAccessRule($rule)
        Set-Acl -LiteralPath .catsql -AclObject $acl
    } else {
        & chmod 700 .catsql
        if ($LASTEXITCODE -ne 0) { throw 'Could not restrict access to .catsql.' }
    }
}

function Invoke-SqlTests {
    $testContainer = Invoke-Docker run --detach --rm --network none `
        -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=catsql `
        $image postgres -c 'listen_addresses='
    try {
        Wait-Database $testContainer postgres
        Invoke-Docker exec $testContainer mkdir -p /tmp/catsql/scripts
        foreach ($path in @('sql', 'tests', 'scripts/verify-sql.sh')) {
            Invoke-Docker cp $path "${testContainer}:/tmp/catsql/$path"
        }
        Invoke-Docker exec $testContainer bash /tmp/catsql/scripts/verify-sql.sh
    } finally {
        Invoke-Docker stop $testContainer | Out-Null
    }
}

Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
try {
    if ($instance -cnotmatch '\Acatsql-[a-z0-9][a-z0-9-]*\z' -or
        $port -notmatch '\A[1-9][0-9]{0,4}\z' -or [int]$port -gt 65535) {
        throw 'Set CATSQL_INSTANCE to a name like catsql-practice and CATSQL_PORT to a valid TCP port.'
    }
    if (-not (Get-Command docker -CommandType Application -ErrorAction SilentlyContinue)) {
        throw 'Install Docker Desktop, start it, and reopen PowerShell.'
    }
    $engineOs = Invoke-Docker info --format '{{.OSType}}'
    if ($engineOs -ne 'linux') { throw 'Switch Docker Desktop to Linux containers.' }

    switch ($Action) {
        'test' { Invoke-SqlTests }
        'info' { Show-Connection (Get-CatSqlContainer) }
        'stop' {
            $container = Get-CatSqlContainer
            if ($container -and $container.State.Running) { Invoke-Docker stop $instance | Out-Null }
            Write-Output 'Demo stopped. The volume retains your data.'
        }
        'start' {
            Protect-ConfigDirectory
            try {
                $lock = [IO.File]::Open((Join-Path (Get-Location) ".catsql/$instance.lifecycle.lock"),
                    'OpenOrCreate', 'ReadWrite', 'None')
            } catch [IO.IOException] {
                throw "Could not lock $instance. Check whether another start is in progress and retry."
            }

            $container = Get-CatSqlContainer
            if ($container) {
                $binding = $container.HostConfig.PortBindings.'5432/tcp'
                if (@($binding).Count -ne 1 -or $binding.HostIp -ne '127.0.0.1' -or $binding.HostPort -ne $port) {
                    throw 'This instance uses a different binding. Use its original port or choose another instance.'
                }
            }

            $volumeNames = @(Invoke-Docker volume ls --format '{{.Name}}')
            if ($volume -cin $volumeNames -and -not (Test-Path -LiteralPath $config -PathType Leaf)) {
                throw "Restore the original credential file $config for the existing volume."
            }
            if (-not (Test-Path -LiteralPath $config -PathType Leaf)) {
                $bytes = [byte[]]::new(24)
                $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
                try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
                $hex = [BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
                [IO.File]::WriteAllText((Join-Path (Get-Location) $config), "POSTGRES_PASSWORD=$hex`n")
                Remove-Variable hex
            }
            if ((Get-Item -LiteralPath $config).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Use a regular local file for credentials: $config."
            }
            if ((Get-Content -LiteralPath $config -Raw) -cnotmatch '\APOSTGRES_PASSWORD=[a-f0-9]{48}\r?\n?\z') {
                throw "Invalid local credential file $config. Restore the original generated file."
            }
            if ($volume -cnotin $volumeNames) {
                Invoke-Docker volume create --label "$label=$project" $volume | Out-Null
            }
            $details = (Invoke-Docker volume inspect $volume | Out-String | ConvertFrom-Json)
            if ($details.Labels.$label -cne $project) {
                throw "Volume $volume does not belong to CatSQL. Choose a different CATSQL_INSTANCE."
            }
            try {
                if (-not $container) {
                    Invoke-Docker run -d --name $instance --label "$label=$project" `
                        -p "127.0.0.1:${port}:5432" --env-file $config `
                        -e POSTGRES_USER=catsql_dev -e POSTGRES_DB=catsql `
                        -v "${volume}:/var/lib/postgresql/data" $image | Out-Null
                } elseif (-not $container.State.Running) {
                    Invoke-Docker start $instance | Out-Null
                }
            } catch {
                throw "$($_.Exception.Message) Check whether TCP $port is in use, free the port and retry."
            }
            Wait-Database $instance catsql_dev
            Invoke-Docker exec $instance mkdir -p /tmp/catsql/sql
            Invoke-Docker cp sql/. "${instance}:/tmp/catsql/sql/"
            Invoke-Docker cp scripts/install.sql "${instance}:/tmp/catsql/install.sql"
            Invoke-Docker exec $instance psql -X -v ON_ERROR_STOP=1 -U catsql_dev -d catsql -q -1 -f /tmp/catsql/install.sql
            Show-Connection (Get-CatSqlContainer)
        }
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
} finally {
    if ($lock) { $lock.Dispose() }
    Pop-Location
}
