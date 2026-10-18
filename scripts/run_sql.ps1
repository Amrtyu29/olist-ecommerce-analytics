# run_sql.ps1 — build the Olist warehouse in PostgreSQL end to end.
#
# Prompts for the postgres password (never stored), creates the `olist` database
# if needed, runs sql/01..04 in order and writes everything to sql/run_log.txt.
#
# Usage (from the repo root, in an interactive PowerShell):
#   .\scripts\run_sql.ps1
#   .\scripts\run_sql.ps1 -Queries   # re-run only 04_analysis_queries.sql

param([switch]$Queries)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$psql = Get-ChildItem "C:\Program Files\PostgreSQL\*\bin\psql.exe" | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $psql) { Write-Error "psql.exe not found under C:\Program Files\PostgreSQL"; exit 1 }

if (-not $env:PGPASSWORD) {
    $secure = Read-Host "Password for PostgreSQL user 'postgres'" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
}

$log = Join-Path $root "sql\run_log.txt"
"=== run_sql.ps1  $(Get-Date -Format s)  ($psql)" | Out-File $log -Encoding utf8

function Run-Sql($file) {
    "`n### $file" | Tee-Object -FilePath $log -Append
    & $psql -U postgres -h localhost -d olist -w -v ON_ERROR_STOP=1 -f $file 2>&1 | Tee-Object -FilePath $log -Append
    if ($LASTEXITCODE -ne 0) { "!! $file failed (exit $LASTEXITCODE)" | Tee-Object -FilePath $log -Append; exit $LASTEXITCODE }
}

if (-not $Queries) {
    $exists = & $psql -U postgres -h localhost -d postgres -w -tAc "SELECT 1 FROM pg_database WHERE datname='olist'"
    if ($LASTEXITCODE -ne 0) { "!! could not connect (wrong password?)" | Tee-Object -FilePath $log -Append; exit 1 }
    if ($exists -ne "1") {
        "creating database olist" | Tee-Object -FilePath $log -Append
        & $psql -U postgres -h localhost -d postgres -w -c "CREATE DATABASE olist;" | Tee-Object -FilePath $log -Append
    }
    Run-Sql "sql\01_create_tables.sql"
    Run-Sql "sql\02_load_data.sql"
    Run-Sql "sql\03_star_schema.sql"
}
Run-Sql "sql\04_analysis_queries.sql"

"`n=== done $(Get-Date -Format s)" | Tee-Object -FilePath $log -Append
Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
