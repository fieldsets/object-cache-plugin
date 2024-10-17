#!/usr/bin/env pwsh

Import-Module Pode
Import-Module PsRedis

$plugin_path = (Get-Location).Path
$script_path = [System.IO.Path]::GetFullPath((Join-Path -Path $plugin_path -ChildPath "./src/start-server.ps1"))

Write-Host "## Fieldsets Object Cache Plugin##"
Write-Host "$($plugin_path)"

Write-Host "Starting Rest API Server"
Start-PodeServer -FilePath "$($script_path)" -Threads 2 -Name 'Object Cache Rest API' #-DisableTermination
Write-Host "Rest API Server Started"

