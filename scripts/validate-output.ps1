#Requires -Version 7.0
<#
.SYNOPSIS
    Renders the solution with test inputs, then validates the output compiles.
.DESCRIPTION
    Supports both provider and auth-handler plugin types via VALIDATE_PLUGIN_TYPE env var.
#>
$ErrorActionPreference = 'Stop'

$PluginType = if ($env:VALIDATE_PLUGIN_TYPE) { $env:VALIDATE_PLUGIN_TYPE } else { 'provider' }
$OutputDir = Join-Path ([System.IO.Path]::GetTempPath()) "scafctl-validate-$([System.Guid]::NewGuid().ToString('N').Substring(0, 8))"
$Name = "scafctl-plugin-validate-$PluginType"
$Module = "github.com/test/$Name"

try {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    Write-Host "=== Validating $PluginType plugin output ==="
    Write-Host "  Output dir: $OutputDir"

    $args = @(
        'run', 'solution', '-f', 'solution.yaml',
        '-r', "name=$Name",
        '-r', "module=$Module",
        '-r', "description=Validation test $PluginType plugin",
        '-r', "plugin_type=$PluginType",
        '-r', 'create_repo=false',
        '-r', 'repo_visibility=public',
        '--output-dir', $OutputDir
    )

    if ($PluginType -eq 'provider') {
        $args += @('-r', 'capabilities=from,transform')
    }

    & scafctl @args
    if ($LASTEXITCODE -ne 0) { throw "scafctl run failed with exit code $LASTEXITCODE" }

    Push-Location (Join-Path $OutputDir $Name)

    Write-Host ''
    Write-Host '  Running go mod tidy...'
    & go mod tidy
    if ($LASTEXITCODE -ne 0) { throw "go mod tidy failed" }

    Write-Host '  Running go build...'
    & go build ./...
    if ($LASTEXITCODE -ne 0) { throw "go build failed" }

    Write-Host '  Running go vet...'
    & go vet ./...
    if ($LASTEXITCODE -ne 0) { throw "go vet failed" }

    Write-Host '  Running go test...'
    & go test ./...
    if ($LASTEXITCODE -ne 0) { throw "go test failed" }

    Pop-Location

    Write-Host ''
    Write-Host "=== $PluginType output compiles and tests pass ==="

    # If no specific type was requested, also validate the other variant
    if (-not $env:VALIDATE_PLUGIN_TYPE) {
        Write-Host ''
        Write-Host '=== Validating auth-handler plugin output ==='

        $AuthDir = Join-Path ([System.IO.Path]::GetTempPath()) "scafctl-validate-auth-$([System.Guid]::NewGuid().ToString('N').Substring(0, 8))"
        New-Item -ItemType Directory -Path $AuthDir -Force | Out-Null

        $AuthName = 'scafctl-plugin-validate-auth'
        $AuthModule = "github.com/test/$AuthName"

        & scafctl run solution -f solution.yaml `
            -r "name=$AuthName" `
            -r "module=$AuthModule" `
            -r 'description=Validation test auth-handler plugin' `
            -r 'plugin_type=auth-handler' `
            -r 'create_repo=false' `
            -r 'repo_visibility=public' `
            --output-dir $AuthDir
        if ($LASTEXITCODE -ne 0) { throw "scafctl run (auth-handler) failed" }

        Push-Location (Join-Path $AuthDir $AuthName)

        Write-Host '  Running go mod tidy...'
        & go mod tidy
        if ($LASTEXITCODE -ne 0) { throw "go mod tidy failed" }

        Write-Host '  Running go build...'
        & go build ./...
        if ($LASTEXITCODE -ne 0) { throw "go build failed" }

        Write-Host '  Running go vet...'
        & go vet ./...
        if ($LASTEXITCODE -ne 0) { throw "go vet failed" }

        Write-Host '  Running go test...'
        & go test ./...
        if ($LASTEXITCODE -ne 0) { throw "go test failed" }

        Pop-Location

        Write-Host ''
        Write-Host '=== auth-handler output compiles and tests pass ==='

        Remove-Item -Recurse -Force $AuthDir -ErrorAction SilentlyContinue
    }
}
finally {
    Remove-Item -Recurse -Force $OutputDir -ErrorAction SilentlyContinue
}
