function Copy-LabIsoResource {
<#
    .SYNOPSIS
        Copies the Lability custom resource files to an ISO root.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Lability ISO root path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $Path,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationName,

        ## Lab VM/Node name
        [Parameter(ValueFromPipeline)]
        [System.String[]] $NodeName,

        ## Overwrite any existing resource files, e.g. expanded Iso/Zip archives
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    begin {

        $configurationDataPath = $ConfigurationData;
        [System.Collections.Hashtable] $ConfigurationData = ConvertTo-ConfigurationData -ConfigurationData $ConfigurationData;
        if (-not $PSBoundParameters.ContainsKey('ConfigurationName')) {

            if ($null -ne $ConfigurationData.NonNodeData.Lability.EnvironmentName) {

                $ConfigurationName = $ConfigurationData.NonNodeData.Lability.EnvironmentName;
            }
            else {

                $ConfigurationName = (Get-Item -Path $configurationDataPath).BaseName;
            }
        }

    }
    process {

        $resourcePath = Join-Path -Path $Path -ChildPath $defaults.ResourcesPath;

        if (-not $PSBoundParameters.ContainsKey('NodeName')) {

            $NodeName = Resolve-ConfigurationDataNode -ConfigurationData $ConfigurationData;
        }

        if (-not (Test-Path -Path $resourcePath)) {

            if ($PSCmdlet.ShouldProcess($resourcePath, $localized.CreateDirectoryConfirmation)) {
                [ref] $null = New-Item -Path $resourcePath -ItemType Directory -Force -Confirm:$false;
            }
        }

        $resourceIDs = @{ };

        foreach ($vm in $NodeName) {

            ## Build hashtable of unique resource IDs
            $vmProperties = Resolve-ConfigurationDataProperty -NodeName $vm -ConfigurationData $ConfigurationData;
            foreach ($resourceID in $vmProperties.Resource) {

                $resourceIDs[$resourceID] = $resourceID;
            }
        }

        $hostDefaults = Get-ConfigurationData -Configuration Host;
        foreach ($resourceId in $resourceIDs.Keys) {

            $expandLabResourceParams = @{
                ResourceId = $resourceId;
                ConfigurationData = $ConfigurationData;
                DestinationPath = $Path;
                # ResourcePath = $hostDefaults.ResourcePath;
                Force = $Force;
            }

            Write-Verbose -Message ($localized.CopyingExpandingResources -f ($resourceId -join ':'), $expandLabResourceParams['DestinationPath'])
            if ($PSCmdlet.ShouldProcess($resourceId, $localized.CopyExpandLabResourceConfirmation)) {

                Expand-LabResource @expandLabResourceParams;
            }
        }

    } #end process
} #end function Copy-LabIsoResource
