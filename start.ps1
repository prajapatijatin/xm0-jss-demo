#Requires -RunAsAdministrator
param(    
    [switch]$StopBeforeStarting,
    [switch]$SkipBuild,
    [Switch]$SkipIndexing,
    [Switch]$PushContent,
    [Switch]$SkipOpen
)

Import-Module -Name (Join-Path $PSScriptRoot "tools\cli") -Force

if ($StopBeforeStarting) {
    Write-Host "Stopping any active and running containers before starting..." -ForegroundColor DarkYellow
    Stop-Docker -TakeDown -PruneSystem
}

# Check if license exists or not
$licenseExists = Test-Path ".\docker\license\license.xml"
if (-Not $licenseExists) {
    Write-Host "License file not found. Please place the license file in .\docker\license folder" -ForegroundColor Red
    return
}

$envFileExists = Test-Path ".\docker\.env"
if (-Not $envFileExists) {
    Write-Host ".env file not found." -ForegroundColor Red
    return
}
  
$hostDomain = Get-EnvValueByKey 'HOST_DOMAIN'
  
Initialize-Certificates -hostDomain $hostDomain

Install-SitecoreDockerTools
  
# Stop the IIS
Write-Host "Stopping IIS..." -ForegroundColor Yellow
iisreset.exe /stop
  
Start-Docker -SkipBuild $SkipBuild -PushContent $PushContent -SkipIndexing $SkipIndexing -SkipOpen $SkipOpen
  