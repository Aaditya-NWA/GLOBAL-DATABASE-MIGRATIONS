# Downloads the PostgreSQL JDBC driver that Liquibase needs.
#
#   powershell -ExecutionPolicy Bypass -File scripts\fetch-jdbc-driver.ps1
#
# Liquibase 5.x no longer bundles database drivers, and its install directory
# under C:\Program Files is not writable without admin rights, so the jar lives
# in drivers\ (gitignored) and is passed with --classpath. See README.md.

param(
    [string]$Version = "42.7.9"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root "drivers"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$dest = Join-Path $dir "postgresql-$Version.jar"
if (Test-Path $dest) {
    Write-Host "Already present: $dest"
    exit 0
}

$url = "https://repo1.maven.org/maven2/org/postgresql/postgresql/$Version/postgresql-$Version.jar"
Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
Write-Host "Saved to $dest"
