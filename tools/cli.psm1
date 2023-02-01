using namespace System.Management.Automation.Host

Set-StrictMode -Version Latest


function Install-Kit {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Topology,
        [ValidateNotNullOrEmpty()]
        [string]
        $StarterKitRoot = ".\kit",
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",        
        [bool]$AddSXA,
        [bool]$AddSMS,
        [bool]$AddHeadless,
        [bool]$CreateJSSApp,
        [bool]$AddCD
    )
    Write-Host "In Install-Kit" -ForegroundColor Blue
    $solutionFiles = Join-Path $StarterKitRoot "\solution\*"

    if (Test-Path $DestinationFolder) {
        Remove-Item $DestinationFolder -Force -Recurse
    }
    New-Item $DestinationFolder -ItemType directory

    if ((Test-Path $solutionFiles)) {
        Write-SuccessMessage "Copying solution and msbuild files for local docker setup..."
        Copy-Item $solutionFiles ".\" -Recurse -Force

        Rename-Item ".\Directory.build.props.sample" "Directory.build.props" -Force
        Rename-Item ".\Directory.build.targets.sample" "Directory.build.targets"
        Rename-Item ".\Docker.pubxml.sample" "Docker.pubxml"
    }

    if ($Topology -eq "xm1") {
        Copy-XM1Kit -DestinationFolder $DestinationFolder -AddHeadless $AddHeadless -AddCD $AddCD -CreateJSSApp $CreateJSSApp
        Update-Files -DestinationFolder $DestinationFolder -AddSXA $AddSXA -AddCD $AddCD -AddSMS $AddSMS -AddHeadless $AddHeadless -CreateJSSApp $CreateJSSApp
    }

    $dockerDataFolder = Join-Path $StarterKitRoot "\docker\data"
    Copy-Item $dockerDataFolder $DestinationFolder -Recurse
}

function Copy-XM1Kit {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [string]
        $kitRoot = ".\kit",
        [bool]$AddHeadless,
        [bool]$AddCD,
        [bool]$CreateJSSApp
    )
    Write-Host "In Copy-XM1Kit" -ForegroundColor Blue
    $foldersRoot = Join-Path $kitRoot "\docker\sitecore\"

    $xm1Services = "cm,solr-init,dotnetsdk"

    if ($AddCD) {
        $xm1Services = $xm1Services + ",cd"
    }
    if ($CreateJSSApp) {
        $xm1Services = $xm1Services + ",nodejs,rendering"        
    }

    if (Test-Path $DestinationFolder) {
        Remove-Item $DestinationFolder -Force
    }
    New-Item $DestinationFolder -ItemType directory
    
    $buildDirectoryPath = "$DestinationFolder\build"

    New-Item $buildDirectoryPath -ItemType directory

    $licenseDirectoryPath = "$DestinationFolder\license"

    New-Item $licenseDirectoryPath -ItemType directory

    Copy-Item "$kitRoot\docker\traefik" "$DestinationFolder" -Recurse

    Copy-Item "$kitRoot\docker\deploy" "$DestinationFolder" -Recurse    

    foreach ($folder in $xm1Services.Split(", ")) {
        $path = "$((Join-Path $foldersRoot $folder))"
        Write-Host "Copying $($path) to $buildDirectoryPath" -ForegroundColor Green
        # TODO::Implement
        Copy-Item $path $buildDirectoryPath -Force -Recurse
    }

    $composeFilesPath = Join-Path $kitRoot "\docker\xm1\*"    
    $sampleEnvFilePath = Join-Path $kitRoot "\docker\.env.sample"
    $envFilePath = Join-Path $DestinationFolder "\.env"

    Copy-Item $composeFilesPath $DestinationFolder -Force
    Write-SuccessMessage "Creating .env file at $envFilePath..."
    Copy-Item $sampleEnvFilePath $envFilePath -Force
    Write-SuccessMessage "Copying Dockerfile..."    
    $dockerFilePath = Join-Path $kitRoot "\docker\Dockerfile"
    Copy-Item $dockerFilePath ".\" -Force
}

function Start-Docker {
    param(
        [ValidateNotNullOrEmpty()]
        [string] 
        $DockerRoot = ".\docker",
        [bool]$SkipBuild,
        [bool]$SkipIndexing,
        [bool]$PushContent,
        [bool]$SkipOpen
    )
    if (!(Test-Path ".\docker-compose.yml")) {
        Push-Location $DockerRoot
    }

    $command = "docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.solr-init.override.yml"

    if ((Get-EnvValueByKey 'HAS_HEADLESS_APP') -eq "true") {
        $command = $command + " -f docker-compose.headless.override.yml"
    }

    if ((Get-EnvValueByKey "ADD_CD") -eq "true") {
        $command = $command + " -f docker-compose.cd.override.yml"
    }

    if ($SkipBuild -eq $false) {
        $cmd = $command + " build"
        Invoke-Expression $cmd
    }
    $command = $command + " up -d"  
    if ((Get-EnvValueByKey "FORCE_RECREATE") -eq "true") {
        $command = $command + " --force-recreate"
    }
    Write-Host "Executing: " $command
    Invoke-Expression $command
    Pop-Location
        
    Write-Host "Waiting for CM to become available..." -ForegroundColor Green
    $startTime = Get-Date

    do {
        Start-Sleep -Milliseconds 100
        try {
            $status = Invoke-RestMethod "http://localhost:8079/api/http/routers/cm-secure@docker"
        }
        catch {
            if ($_.Exception.Response.StatusCode.value__ -ne "404") {
                throw
            }
        }
    } while ($status.status -ne "enabled" -and $startTime.AddSeconds(20) -gt (Get-Date))
    if (-not $status.status -eq "enabled") {
        $status
        Write-Error "Timeout waiting for Sitecore CM to become available via Traefik proxy. Check CM container logs."
    }

    $idHost = Get-EnvValueByKey "ID_HOST"
    $cmHost = Get-EnvValueByKey "CM_HOST"

    if (Test-Path ".\sitecore.json") {
        Write-Host "Restoring Sitecore CLI..." -ForegroundColor Green
        dotnet tool restore

        Write-Host "Installing Sitecore CLI plugins..."
        dotnet sitecore --help | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Unexpected error installing Sitecore CLI Plugins"
        }

        Write-Host "Logging into Sitecore..." -ForegroundColor Green
        
        dotnet sitecore login --authority https://$idHost --cm https://$cmHost --allow-write true

        if ($PushContent) {
            # Deploy the serialised content items
            Write-Host "Pushing items to Sitecore..." -ForegroundColor Green
            dotnet sitecore ser push
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Serialization push failed, see errors above."
            }
        }
    }
    
    if (-not $SkipIndexing) {
        # Populate Solr managed schemas to avoid errors during item deploy
        Write-Host "Populating Solr managed schema..." -ForegroundColor Green
        dotnet sitecore index schema-populate
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Populating Solr managed schema failed, see errors above."
        }

        # Rebuild indexes
        Write-Host "Rebuilding indexes ..." -ForegroundColor Green
        dotnet sitecore index rebuild
    }    

    if (-not $SkipOpen) {
        Write-Host "Opening site..." -ForegroundColor Green
        Start-Process https://$cmHost/sitecore/
        if ((Get-EnvValueByKey 'HAS_HEADLESS_APP') -eq "true") {
            $renderingHost = Get-EnvValueByKey 'RENDERING_HOST'
            Start-Process "https://$renderingHost"
        }
    }

    # Write-Host "...now wait for about 20 to 25 seconds to make sure Traefik is ready...`n`n`n" -ForegroundColor DarkYellow
    # Write-Host "`ndon't forget to ""Populate Solr Managed Schema"" from the Control Panel`n`n`n" -ForegroundColor Yellow
    # Write-Host "`nIf the request fails with a 404 on the first attempt then the dance wasn't long enough - just hit refresh..`n`n" -ForegroundColor DarkGray
    # $cmUrl = Get-EnvValueByKey 'CM_HOST'
    # Start-Process "https://$cmUrl/sitecore/login"
    # if ((Get-EnvValueByKey 'HAS_HEADLESS_APP') -eq "true") {
    #     $renderingHost = Get-EnvValueByKey 'RENDERING_HOST'
    #     Start-Process "https://$renderingHost"
    # }
}

function Stop-Docker {
    param(
        [ValidateNotNullOrEmpty()]
        [string] 
        $DockerRoot = ".\docker",
        [Switch]$TakeDown,
        [Switch]$PruneSystem
    )
    if (!(Test-Path $DockerRoot)) {
        Write-Host "Docker environment not found and hence nothing to stop..." -ForegroundColor DarkMagenta
        return
    }
    if (!(Test-Path ".\docker-compose.yml")) {
        Push-Location $DockerRoot
    }
    if (Test-Path ".\docker-compose.yml") {
        $command = "docker-compose -f docker-compose.yml -f docker-compose.override.yml  -f docker-compose.solr-init.override.yml"
        if ((Get-EnvValueByKey "HAS_HEADLESS_APP") -eq "true") {
            $command = $command + " -f docker-compose.headless.override.yml"
        }
        if ((Get-EnvValueByKey "ADD_CD") -eq "true") {
            $command = $command + " -f docker-compose.cd.override.yml"
        }
        if ($TakeDown) {
            $command = $command + " down"
        }
        else {
            $command = $command + " stop"
        }
        Write-Host "Command: $command"
        Invoke-Expression $command
        if ($PruneSystem) {
            docker system prune -f
        }
    }
    Pop-Location
}

function Install-SitecoreDockerTools {
    Import-Module PowerShellGet
    $sitecoreGallery = Get-PSRepository | Where-Object { $_.SourceLocation -eq "https://sitecore.myget.org/F/sc-powershell/api/v2" }
    if (-not $sitecoreGallery) {
        Write-SuccessMessage "Adding Sitecore PowerShell Gallery..."
        Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
        $SitecoreGallery = Get-PSRepository -Name SitecoreGallery
    }

    $dockerToolsVersion = "10.2.7"
    Remove-Module SitecoreDockerTools -ErrorAction SilentlyContinue
    if (-not (Get-InstalledModule -Name SitecoreDockerTools -RequiredVersion $dockerToolsVersion -ErrorAction SilentlyContinue)) {
        Write-SuccessMessage -Message "Installing SitecoreDockerTools..."
        Install-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion -Scope CurrentUser -Repository $sitecoreGallery.Name
    }
    Write-SuccessMessage -Message "Importing SitecoreDockerTools..."
    Import-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion
}

function Rename-SolutionFile {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $SolutionName,
        [ValidateNotNullOrEmpty()]
        [string] 
        $FileToRename = ".\_kit.sln"
    )
    if ((Test-Path $FileToRename) -and !(Test-Path ".\$($SolutionName).sln")) {
        Write-Host "Creating solution file: $($SolutionName).sln" -ForegroundColor Green
        Move-Item $FileToRename ".\$($SolutionName).sln"
    }
}

function Update-Files {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [ValidateNotNullOrEmpty()]
        [string]
        $kitRoot = ".\kit",        
        [bool]$AddSXA,
        [bool]$AddCD,
        [bool]$AddSMS,
        [bool]$AddHeadless,
        [bool]$CreateJSSApp
    )
    Write-Host "In Update-Files" -ForegroundColor Blue
    $solrInit = "$((Join-Path $KitRoot "\docker\docker-compose.solr-init.override.yml"))"
    Copy-Item $solrInit $DestinationFolder -Force

    if ($AddSXA) {
        Add-SXA -DestinationFolder $DestinationFolder -KitRoot $StarterKitRoot
    }

    if ($AddSMS) {
        Add-SMS -DestinationFolder $DestinationFolder -KitRoot $StarterKitRoot
    }
    if ($AddHeadless) {
        Add-Headless -DestinationFolder $DestinationFolder -KitRoot $StarterKitRoot
    }
    if ($CreateJSSApp) {
        Copy-Item "$((Join-Path $KitRoot "\docker\docker-compose.headless.override.yml"))" $DestinationFolder -Force        
    }    
    if ($AddCD) {
        Copy-Item "$((Join-Path $KitRoot "\docker\docker-compose.cd.override.yml"))" $DestinationFolder -Force
        Update-CDFiles -AddSXA $AddSXA -AddSMS $AddSMS -AddHeadless $AddHeadless
    }    
}

function Add-SXA {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [ValidateNotNullOrEmpty()]
        [string]
        $KitFolder = ".\kit",
        [bool]$AddCD
    )
    Write-Host "Adding the SXA module..." -ForegroundColor Green
    $fileToUpdate = Join-Path $DestinationFolder "\build\cm\Dockerfile"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#ARG_SXA_IMAGE", "ARG SXA_IMAGE") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#FROM_SXA_IMAGE", "FROM `${SXA_IMAGE} as sxa") | Set-Content -Path $fileToUpdate
    # ((Get-Content -Path $fileToUpdate -Raw) -replace "#SXA_Module", "# Add SXA module`nCOPY --from=sxa \module\cm\content .\`nCOPY --from=sxa \module\tools \module\tools`nRUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; `Remove-Item -Path C:\module -Recurse -Force; `nRUN Rename-Item -Path ""c:\inetpub\wwwroot\App_Config\Include\Spe\Spe.IdentityServer.config.disabled"" -NewName ""Spe.IdentityServer.config""`nRUN Rename-Item -Path ""c:\inetpub\wwwroot\App_Config\Include\z.Feature.Overrides\z.SPE.Sync.Enabler.Gulp.config.disabled"" -NewName ""z.SPE.Sync.Enabler.Gulp.config""") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#SXA_Module", "# Add SXA module`nCOPY --from=sxa \module\cm\content .\`nCOPY --from=sxa \module\tools \module\tools`nRUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; `Remove-Item -Path C:\module -Recurse -Force; ") | Set-Content -Path $fileToUpdate
    
    $fileToUpdate = Join-Path $DestinationFolder "\docker-compose.override.yml"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#SXA_IMAGE", "SXA_IMAGE: `${SITECORE_MODULE_REGISTRY}sitecore-sxa-`${TOPOLOGY}-assets:`${SXA_VERSION}") | Set-Content -Path $fileToUpdate
    
    $fileToUpdate = Join-Path $DestinationFolder "\build\solr-init\Dockerfile"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#ARG_SXA_IMAGE", "ARG SXA_IMAGE") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#FROM_SXA_IMAGE", "FROM `${SXA_IMAGE} as sxa") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#SXA_Module", "# Add SXA module`nCOPY --from=sxa C:\module\solr\cores-sxa.json C:\data\cores-sxa.json") | Set-Content -Path $fileToUpdate
    
    $solrInitFileToUpdate = Join-Path $DestinationFolder "\docker-compose.solr-init.override.yml"
    ((Get-Content -Path $solrInitFileToUpdate -Raw) -replace "#SXA_IMAGE", "SXA_IMAGE: `${SITECORE_MODULE_REGISTRY}sitecore-sxa-`${TOPOLOGY}-assets:`${SXA_VERSION}") | Set-Content -Path $solrInitFileToUpdate    
}

function Update-CDFiles {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [bool]$AddSXA,
        [bool]$AddSMS,
        [bool]$AddHeadless
    )
    if ($AddSXA) {
        $fileToUpdate = Join-Path $DestinationFolder "\build\cd\Dockerfile"
        ((Get-Content -Path $fileToUpdate -Raw) -replace "#ARG_SXA_IMAGE", "ARG SXA_IMAGE") | Set-Content -Path $fileToUpdate
        ((Get-Content -Path $fileToUpdate -Raw) -replace "#FROM_SXA_IMAGE", "FROM `$ {SXA_IMAGE} as sxa") | Set-Content -Path $fileToUpdate
        ((Get-Content -Path $fileToUpdate -Raw) -replace "#SXA_Module", "# Add SXA module`nCOPY --from=sxa \module\cd\content .\`nCOPY --from=sxa \module\tools \module\tools`nRUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; `Remove-Item -Path C:\module -Recurse -Force; ") | Set-Content -Path $fileToUpdate
        $fileToUpdate = Join-Path $DestinationFolder "\docker-compose.cd.override.yml"
        ((Get-Content -Path $fileToUpdate -Raw) -replace "#SXA_IMAGE", "SXA_IMAGE: `${SITECORE_MODULE_REGISTRY}sitecore-sxa-`${TOPOLOGY}-assets:`${SXA_VERSION}") | Set-Content -Path $fileToUpdate
    }

    if ($AddHeadless) {
        $fileToUpdate = Join-Path $DestinationFolder "\build\cd\Dockerfile"
            ((Get-Content -Path $fileToUpdate -Raw) -replace "#ARG_HEADLESS_IMAGE", "ARG HEADLESS_IMAGE") | Set-Content -Path $fileToUpdate
            ((Get-Content -Path $fileToUpdate -Raw) -replace "#FROM_HEADLESS_IMAGE", "FROM `${HEADLESS_IMAGE} as headless") | Set-Content -Path $fileToUpdate
            ((Get-Content -Path $fileToUpdate -Raw) -replace "#Headless_Module", "# Add Headless module`nCOPY --from=headless \module\cd\content .\`nCOPY --from=headless \module\tools \module\tools`nRUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; `Remove-Item -Path C:\module -Recurse -Force; ") | Set-Content -Path $fileToUpdate
    
        $fileToUpdate = Join-Path $DestinationFolder "\docker-compose.cd.override.yml"
        ((Get-Content -Path $fileToUpdate -Raw) -replace "#HEADLESS_IMAGE", "HEADLESS_IMAGE: `${SITECORE_MODULE_REGISTRY}sitecore-headless-services-`${TOPOLOGY}-assets:`$ {HEADLESS_VERSION:-latest}") | Set-Content -Path $fileToUpdate
    }
}

function Add-SMS {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [ValidateNotNullOrEmpty()]
        [string]
        $KitRoot = ".\kit"
    )
    Write-Host "Adding the Sitecore Management Services module..." -ForegroundColor Green
    $fileToUpdate = Join-Path $DestinationFolder "\build\cm\Dockerfile"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#ARG_SMS_IMAGE", "ARG SMS_IMAGE") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#FROM_SMS_IMAGE", "FROM `${SMS_IMAGE} as sms") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#Sms_Module", "# Add SMS module`nCOPY --from=sms \module\cm\content .\") | Set-Content -Path $fileToUpdate

    $fileToUpdate = Join-Path $DestinationFolder "\docker-compose.override.yml"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#SMS_IMAGE", "SMS_IMAGE: `${SITECORE_MODULE_REGISTRY}sitecore-management-services-`${TOPOLOGY}-assets:`${SMS_VERSION:-latest}") | Set-Content -Path $fileToUpdate
}

function Add-Headless {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [ValidateNotNullOrEmpty()]
        [string]
        $KitRoot = ".\kit"
    )
    Write-Host "Adding the Sitecore Headless module..." -ForegroundColor Green
    $fileToUpdate = Join-Path $DestinationFolder "\build\cm\Dockerfile"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#ARG_HEADLESS_IMAGE", "ARG HEADLESS_IMAGE") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#FROM_HEADLESS_IMAGE", "FROM `${HEADLESS_IMAGE} as headless") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#Headless_Module", "# Add Headless module`nCOPY --from=headless \module\cm\content .\`nCOPY --from=headless \module\tools \module\tools`nRUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; `Remove-Item -Path C:\module -Recurse -Force; ") | Set-Content -Path $fileToUpdate

    $fileToUpdate = Join-Path $DestinationFolder "\docker-compose.override.yml"
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#HEADLESS_IMAGE", "HEADLESS_IMAGE: `${SITECORE_MODULE_REGISTRY}sitecore-headless-services-`${TOPOLOGY}-assets:`${HEADLESS_VERSION:-latest}") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#JSS_DEPLOYMENT_SECRET", "JSS_DEPLOYMENT_SECRET: `${JSS_DEPLOYMENT_SECRET}") | Set-Content -Path $fileToUpdate
    ((Get-Content -Path $fileToUpdate -Raw) -replace "#JSS_EDITING_SECRET", "JSS_EDITING_SECRET: `${JSS_EDITING_SECRET}") | Set-Content -Path $fileToUpdate    
}

# Helper functions

function Initialize-HostNames {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $hostDomain
    )
    Write-SuccessMessage -Message "Adding hosts file entries..."

    Add-HostsEntry "cm.$($hostDomain)"
    Add-HostsEntry "cd.$($hostDomain)"
    Add-HostsEntry "id.$($hostDomain)"
    Add-HostsEntry "www.$($hostDomain)"

    Initialize-Certificates -hostDomain $hostDomain

    # if (!(Test-Path ".\docker\traefik\certs\cert.pem")) {
    #     & ".\tools\mkcert.ps1" -FullHostName $hostDomain
    # }
}

function Initialize-Certificates {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $hostDomain
    )
    if (!(Test-Path ".\docker\traefik\certs\cert.pem")) {        
        & ".\tools\mkcert.ps1" -FullHostName $hostDomain
    }
}

function Initialize-EnvFile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $SolutionName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $HostDomain,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $Topology,
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder = ".\docker",
        [bool]$AddSXA,
        [bool]$AddSMS,
        [bool]$CreateJSSApp,
        [bool]$AddCD
    )
    Push-Location ".\docker"
    Set-EnvFileVariable "COMPOSE_PROJECT_NAME" -Value $SolutionName.ToLower()
    Set-EnvFileVariable "HOST_LICENSE_FOLDER" -Value ".\license"
    Set-EnvFileVariable "HOST_DOMAIN"  -Value $hostDomain
    Set-EnvFileVariable "CM_HOST" -Value "cm.$($hostDomain)"
    Set-EnvFileVariable "CD_HOST" -Value "cd.$($hostDomain)"
    Set-EnvFileVariable "TOPOLOGY" -Value $Topology
    
    Set-EnvFileVariable "ID_HOST" -Value "id.$($hostDomain)"
    if ($AddCD) {
        Set-EnvFileVariable "ADD_CD" -Value "true"        
    }
    if ($AddSXA) {
        Set-EnvFileVariable "ADD_SXA" -Value "true"
    }
    if ($AddSMS) {
        Set-EnvFileVariable "ADD_SMS" -Value "true"
    }
    if ($CreateJSSApp) {
        Set-EnvFileVariable "HAS_HEADLESS_APP" -Value "true"
        Set-EnvFileVariable "RENDERING_HOST" -Value "www.$($hostDomain)"
        Set-EnvFileVariable "JSS_DEPLOYMENT_SECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
        Set-EnvFileVariable "JSS_EDITING_SECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
        Set-EnvFileVariable "RENDERING_APP_LOCAL_PATH" -Value "../jss-app/$SolutionName"
    }
    # Set-EnvFileVariable "RENDERING_HOST" -Value "www.$($hostDomain)"
    Set-EnvFileVariable "REPORTING_API_KEY" -Value (Get-SitecoreRandomString 128 -DisallowSpecial)
    Set-EnvFileVariable "TELERIK_ENCRYPTION_KEY" -Value (Get-SitecoreRandomString 128)
    Set-EnvFileVariable "MEDIA_REQUEST_PROTECTION_SHARED_SECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
    Set-EnvFileVariable "SITECORE_IDSECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
    $idCertPassword = Get-SitecoreRandomString 8 -DisallowSpecial
    Set-EnvFileVariable "SITECORE_ID_CERTIFICATE" -Value (Get-SitecoreCertificateAsBase64String -DnsName "localhost" -Password (ConvertTo-SecureString -String $idCertPassword -Force -AsPlainText))
    Set-EnvFileVariable "SITECORE_ID_CERTIFICATE_PASSWORD" -Value $idCertPassword
    Set-EnvFileVariable "SQL_SA_PASSWORD" -Value (Get-SitecoreRandomString 19 -DisallowSpecial -EnforceComplexity)
    # Set-EnvFileVariable "SITECORE_VERSION" -Value (Read-ValueFromHost -Question "Sitecore image version`n(10.3-ltsc2019, 10.3-1909, 10.3-2004, 10.3-20H2 - press enter for 10.3-20H2)" -DefaultValue "10.3-20H2" -Required)
    Set-EnvFileVariable "SITECORE_VERSION" -Value "10.3-ltsc2019"
    Set-EnvFileVariable "SITECORE_ADMIN_PASSWORD" -Value (Read-ValueFromHost -Question "Sitecore admin password (press enter for 'b')" -DefaultValue "b" -Required)

    if (Confirm -Question "Would you like to adjust common environment settings?") {
        # Set-EnvFileVariable "SPE_VERSION" -Value (Read-ValueFromHost -Question "Sitecore Powershell Extensions version (press enter for 6.2-1809)" -DefaultValue "6.2-1809" -Required)
        # Set-EnvFileVariable "REGISTRY" -Value (Read-ValueFromHost -Question "Local container registry (leave empty if none, must end with /)")
        Set-EnvFileVariable "ISOLATION" -Value (Read-ValueFromHost -Question "Container isolation mode (press enter for default)" -DefaultValue "default" -Required)
    }

    if (Confirm -Question "Would you like to adjust container memory limits?") {
        Set-EnvFileVariable "MEM_LIMIT_SQL" -Value (Read-ValueFromHost -Question "SQL Server memory limit (default: 4GB)" -DefaultValue "4GB" -Required)
        Set-EnvFileVariable "MEM_LIMIT_SOLR" -Value (Read-ValueFromHost -Question "Solr memory limit (default: 2GB)" -DefaultValue "2GB" -Required)
        Set-EnvFileVariable "MEM_LIMIT_CM" -Value (Read-ValueFromHost -Question "CM Server memory limit (default: 4GB)" -DefaultValue "4GB" -Required)
        if ($Topology -eq "xm1") {
            Set-EnvFileVariable "MEM_LIMIT_CD" -Value (Read-ValueFromHost -Question "CD Server memory limit (default: 4GB)" -DefaultValue "4GB" -Required)
        }
    }
    Pop-Location
}

function Add-JSSApplication {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SolutionName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CMHost
    )
    Write-Host "Create JSS application via npx create-sitecore-jss..."

    New-Item "jss-app" -ItemType Directory

    if ($null -eq (Get-Command "npm" -ErrorAction SilentlyContinue)) {
        Write-Host "You must install node.js, see https://nodejs.org/" -ForegroundColor Red
        Exit 1
    }

    # always using the latest version of the JSS
    $JSSNPMVersion = Read-ValueFromHost -Question "Enter JSS version (press enter for latest)" -DefaultValue "latest" -Required
    if ($null -eq (Get-Command "jss" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Sitecore JSS CLI" -ForegroundColor Green
        npm install -g @sitecore-jss/sitecore-jss-cli @sitecore-jss/sitecore-jss-nextjs
    }
    # npm install -g @sitecore-jss/sitecore-jss-cli @sitecore-jss/sitecore-jss-nextjs
    Push-Location 'jss-app'

    try {
        Write-Host "Creating JSS Project for $solutionName" -ForegroundColor Green
        $jssProjectName = $solutionName

        $createArgs = @(
            "create-sitecore-jss@$JSSNPMVersion",
            "--destination", $jssProjectName,
            "--appName", $jssProjectName
        )
        $jssCreateParams = "--templates nextjs,nextjs-styleguide,nextjs-sxa --fetchWith REST --prerender SSR --hostName https://$cmHost --yes --force"
        $createArgs += $jssCreateParams.Split(' ')
        Write-Host $createArgs
        npx @createArgs

        # Remove .env file created along with the application
        Write-Host "Removing .env file" -ForegroundColor Yellow
        Remove-Item "$solutionName\.env"
    }
    finally {
        Pop-Location
    }
}

function Initialize-Certificates {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $hostDomain
    )
    if (!(Test-Path ".\docker\traefik\certs\cert.pem")) {
        & ".\tools\mkcert.ps1" -FullHostName $hostDomain
    }
}

function Read-ValueFromHost {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Question,
        [ValidateNotNullOrEmpty()]
        [string]
        $DefaultValue,
        [ValidateNotNullOrEmpty()]
        [string]
        $ValidationRegEx,
        [switch]$Required
    )
    Write-Host ""
    do {
        Write-PrePrompt
        $value = Read-Host $question
        if ($value -eq "" -band $defaultValue -ne "") { $value = $defaultValue }
        $invalid = ($required -and $value -eq "")
    }while ($invalid -bor $value -eq "q")
    $value
}

function Write-PrePrompt {
    Write-Host "> " -NoNewline -ForegroundColor Yellow
}

function Confirm {    
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $Question,
        [switch] 
        $DefaultYes
    )
    $options = [ChoiceDescription[]](
        [ChoiceDescription]::new("&Yes"), 
        [ChoiceDescription]::new("&No")
    )
    $defaultOption = 1;
    if ($DefaultYes) { $defaultOption = 0 }
    Write-Host ""
    Write-PrePrompt
    $result = $host.ui.PromptForChoice("", $Question, $options, $defaultOption)
    switch ($result) {
        0 { return $true }
        1 { return $false }
    }
}

function Remove-EnvHostsEntry {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $Key,
        [Switch]
        $Build        
    )
    $hostName = Get-EnvValueByKey $Key
    if ($null -ne $hostName -and $hostName -ne "") {
        Remove-HostsEntry $hostName
    }
}

function Write-SuccessMessage {
    param(
        [string]
        $message
    )
    Write-Host $message -ForegroundColor Green
}

function Write-ErrorMessage {
    param(
        [string]
        $message
    )
    Write-Host $message -ForegroundColor Red
}

function Test-IsEnvInitialized {
    $name = Get-EnvValueByKey "COMPOSED_PROJECT_NAME"
    return ($null -ne $name -and $name -ne "")
}

function Get-EnvValueByKey {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $key,
        [ValidateNotNullOrEmpty()]
        [string]
        $filePath = ".env",
        [ValidateNotNullOrEmpty()]
        [string]
        $dockerRoot = ".\docker"
    )
    if (!(Test-Path $filePath)) {
        $filePath = Join-Path $dockerRoot $filePath
    }
    # If .env file is not found, then return empty string
    if (!(Test-Path $filePath)) {
        return ""
    }
    select-string -Path $filePath -Pattern "^$key=(.+)$" | % { $_.Matches.Groups[1].Value }
}