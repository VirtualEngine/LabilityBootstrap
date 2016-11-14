function Add-LabIsoConfiguration {
<#
    .SYNOPSIS
        Prestages an ISO lab configuration.
#>
    [CmdletBinding(DefaultParameterSetName = 'PSCredential', SupportsShouldProcess)]
    param (
        ## Root ISO scratch path
        [Parameter(Mandatory)]
        [System.String] $Path,

        ## Lab configuration data
        [Parameter(Mandatory)]
        [System.String] $ConfigurationData,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationName,

        ## Local administrator password of the VM. The username is NOT used.
        [Parameter(ParameterSetName = 'PSCredential', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = (& $credentialCheckScriptBlock),

        ## Local administrator password of the VM.
        [Parameter(Mandatory, ParameterSetName = 'Password', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $Password,

        ## Path containing the lab .meta.mof and .mof files
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $ConfigurationPath = (Get-Item -Path $ConfigurationData).DirectoryName
    )
    begin {

        ## If we have only a secure string, create a PSCredential
        if ($PSCmdlet.ParameterSetName -eq 'Password') {
            $Credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'LocalAdministrator', $Password;
        }
        if (-not $Credential) {
            throw ($localized.CannotProcessCommandError -f 'Credential');
        }
        elseif ($Credential.Password.Length -eq 0) {
            throw ($localized.CannotBindArgumentError -f 'Password');
        }

    }
    process {

        ## Store the configuration file path for copying later
        $configurationDataPath =  $ConfigurationData;
        [System.Collections.Hashtable] $ConfigurationData = ConvertTo-ConfigurationData -ConfigurationData $ConfigurationData;
        if (-not $PSBoundParameters.ContainsKey('ConfigurationName')) {

            if ($null -ne $ConfigurationData.NonNodeData.Lability.EnvironmentName) {

                $ConfigurationName = $ConfigurationData.NonNodeData.Lability.EnvironmentName;
            }
            else {

                $ConfigurationName = (Get-Item -Path $configurationDataPath).BaseName;
            }
        }

        ## Ensure we have all required modules, DSC resources and binary resources
        Write-Verbose -Message ($localized.DownloadingLabilityModules);
        [ref] $null = Invoke-LabResourceDownload -ConfigurationData $ConfigurationData -Modules;
        Write-Verbose -Message ($localized.DownloadingLabilityDscResources);
        [ref] $null = Invoke-LabResourceDownload -ConfigurationData $ConfigurationData -DSCResources;
        Write-Verbose -Message ($localized.DownloadingLabilityResources);
        [ref] $null = Invoke-LabResourceDownload -ConfigurationData $ConfigurationData -Resources;

        ## Clean out any existing \Configurations directory
        $configurationsRootPath = Join-Path -Path $Path -ChildPath $defaults.ConfigurationsPath;
        $configurationRootPath = Join-Path -Path $configurationsRootPath -ChildPath $ConfigurationName;
        if (Test-Path -Path $configurationRootPath) {
            Write-Verbose -Message ($localized.RemovingConfigurationDirectory -f $configurationRootPath);
            Remove-Item -Path $configurationRootPath -Recurse -Force -Confirm:$false;
        }
        Write-Verbose -Message ($localized.CreatingConfigurationDirectory -f $configurationRootPath);
        [ref] $null = New-Item -Path $configurationRootPath -ItemType Directory -Force;

        $bootstrapPath = Join-Path -Path $configurationRootPath -ChildPath 'Bootstrap.ps1';
        Write-Verbose -Message ($localized.CopyingConfigurationBootstrap -f $bootstrapPath);
        [ref] $null = Copy-LabBootstrap -Credential $Credential -DestinationPath $bootstrapPath;

        Copy-LabCertificate -ConfigurationData $configurationDataPath -DestinationPath $configurationRootPath;
        Copy-LabConfiguration -ConfigurationData $configurationDataPath -DestinationPath $configurationRootPath -Path $ConfigurationPath;

        ## TODO: We need to invoke a download incase the modules aren't already cached
        $modulesPath = Join-Path -Path $configurationRootPath -ChildPath $defaults.ModulesPath;
        [ref] $null = Copy-LabModule -ConfigurationData $configurationDataPath -DestinationPath $modulesPath -ModuleType 'Module','DscResource';

        ## Copy resources..
        Push-Location -Path (Split-Path -Path $configurationDataPath -Parent);
        Copy-LabIsoResource -ConfigurationData $configurationDataPath -Path $Path;
        Pop-Location;

        Get-ChildItem -Path $ConfigurationPath -Filter ReadMe* |
            ForEach-Object {
                Write-Verbose -Message ($localized.CopyingReadMeFile -f $_.Name);
                Copy-Item -Path $_.FullName -Destination $configurationRootPath
            }

    } #end process
} #end function Add-LabIsoConfiguration
