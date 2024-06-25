#!/usr/bin/env pwsh

$plugin_path = (Get-Location).Path
$script_path = [System.IO.Path]::GetFullPath((Join-Path -Path $plugin_path -ChildPath "./src/start-server.ps1"))

Write-Host "## Fieldsets Object Cache Plugin##"
Write-Host "$($plugin_path)"

$shell = (Get-Command pwsh).Source
[ScriptBlock]$start_server_script_block = {
    param($Path)
    Import-Module Pode
    Start-PodeServer -FilePath "$($path)" -Thread 2 -DisableTermination -Name 'Object Cache Rest API'
    Exit
}
$process_command = &$start_server_script_block -Path "$($script_path)"

Write-Host "Starting Rest API Server"
Start-Process -FilePath "$($shell)" -PassThru -ArgumentList "-NoProfile -NonInteractive -WorkingDirectory $($plugin_path) -Command $($process_command)" &
Write-Host "Rest API Server Started"

Exit
Exit-PSHostProcess
