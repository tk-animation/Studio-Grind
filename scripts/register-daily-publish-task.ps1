param(
  [string]$TaskName = "Publish Studio Grind Quartz",
  [string]$At = "20:00"
)

$ErrorActionPreference = "Stop"
$scriptPath = Resolve-Path (Join-Path $PSScriptRoot "publish-static-pages.ps1")
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

$action = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
  -WorkingDirectory $repoRoot

$trigger = New-ScheduledTaskTrigger -Daily -At $At
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force
Write-Host "Registered daily task '$TaskName' at $At."
