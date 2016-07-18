function Copy-LabResource {
<#
    .SYNOPSIS
        Copies the Lability custom resource files.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Lability bootstrap path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath,

        ## Lab VM/Node name
        [Parameter(ValueFromPipeline)]
        [System.String[]] $NodeName,

        ## Overwrite any existing resource files, e.g. expanded Iso/Zip archives
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    begin {
        [System.Collections.Hashtable] $ConfigurationData = ConvertTo-ConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('NodeName')) {
            $NodeName = Resolve-ConfigurationDataNode -ConfigurationData $ConfigurationData;
        }

        $resourcePath = Join-Path -Path $DestinationPath -ChildPath $defaults.ResourcesPath;
        if (-not (Test-Path -Path $resourcePath)) {
            if ($PSCmdlet.ShouldProcess($resourcePath, $localized.CreateDirectoryConfirmation)) {
                [ref] $null = New-Item -Path $resourcePath -ItemType Directory -Force -Confirm:$false;
            }
        }

        $resourceIDs = @{};
        foreach ($vm in $NodeName) {
            ## Build hashtable of unique resource IDs
            $vmProperties = Resolve-ConfigurationDataProperty -NodeName $vm -ConfigurationData $ConfigurationData;
            foreach ($resourceID in $vmProperties.Resource) {
                $resourceIDs[$resourceID] = $resourceID;
            }
        }

        $hostDefaults = Get-ConfigurationData -Configuration Host;
        foreach ($resourceId in $resourceIDs.Keys) {
            Write-Verbose -Message ($localized.CopyingExpandingResources -f $resourceId, $resourcePath)
            $expandLabResourceParams = @{
                ResourceId = $resourceId;
                ConfigurationData = $ConfigurationData;
                DestinationPath = $resourcePath;
                ResourcePath = $hostDefaults.ResourcePath;
                Force = $Force;
            }
            if ($PSCmdlet.ShouldProcess($resourceId, $localized.CopyExpandLabResourceConfirmation)) {
                Expand-LabResource @expandLabResourceParams;
            }
        }
    } #end process
} #end function Copy-LabResource
