function Copy-LabConfiguration {
<#
    .SYNOPSIS
        Copies the Lability configuration and .MOF files.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Lability bootstrap path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath,

        ## Source configurations path
        [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.String] $Path = (Get-Item -Path $ConfigurationData).DirectoryName,

        ## Lab VM/Node name
        [Parameter(ValueFromPipeline)]
        [System.String[]] $NodeName
    )
    process {

        $configurationPath = Join-Path -Path $DestinationPath -ChildPath $defaults.ConfigurationsPath;
        if (-not (Test-Path -Path $configurationPath)) {
            if ($PSCmdlet.ShouldProcess($configurationPath, $localized.CreateDirectoryConfirmation)) {
                [ref] $null = New-Item -Path $configurationPath -ItemType Directory -Force -Confirm:$false;
            }
        }

        ## Copy the actual configuration data before we start
        $configurationDataPath = Join-Path -Path $configurationPath -ChildPath 'ConfigurationData.psd1';
        Write-Verbose -Message ($localized.CopyingConfigurationDataFile -f $configurationDataPath);
        if ($PSCmdlet.ShouldProcess($configurationDataPath, $localized.CopyFileConfirmation)) {
            Copy-Item -Path $ConfigurationData -Destination $configurationDataPath -Force -Confirm:$false;
        }

        [System.Collections.Hashtable] $ConfigurationData = ConvertTo-ConfigurationData -ConfigurationData $ConfigurationData;

        if (-not $PSBoundParameters.ContainsKey('NodeName')) {
            $NodeName = Resolve-ConfigurationDataNode -ConfigurationData $ConfigurationData;
        }

        foreach ($vm in $NodeName) {
            Write-Verbose -Message ($localized.CopyingConfigurationFile -f $vm, $configurationPath);
            Get-ChildItem -Path $Path -Filter "$($vm).*" | ForEach-Object {
                $configurationDestinationPath = Join-Path -Path $configurationPath -ChildPath $_.Name;
                if ($PSCmdlet.ShouldProcess($configurationDestinationPath, $localized.CopyFileConfirmation)) {
                    $_ | Copy-Item -Destination $configurationPath -Force -Verbose:$false -Confirm:$false;
                }

            }
        }

    } #end process
} #end function Copy-LabConfiguration
