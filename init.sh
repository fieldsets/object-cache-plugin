#!/usr/bin/env pwsh

Install-Module Pode -Force
Install-Module PsRedis -Force

# Temporary patches
# https://github.com/Badgerati/Pode/pull/1413
# Only update 2.11.0
if (Test-Path -Path "~/.local/share/powershell/Modules/Pode/2.11.0/Public/Caching.ps1") {
    CopyItem -Path "/usr/local/plugins/object-cache-plugin/config/pode/patch-1413.ps1" -Destination "~/.local/share/powershell/Modules/Pode/2.11.0/Public/Caching.ps1" -Force
}

Exit
Exit-PSHostProcess