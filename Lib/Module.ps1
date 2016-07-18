function ResolveLabModule {
<#
    .SYNOPSIS

#>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Lab VM/Node name
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $NodeName,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData,

        ## Module type to enumerate
        [Parameter(Mandatory)]
        [ValidateSet('Module','DscResource')]
        [System.String] $ModuleType
    )
    process {

        $scriptBlock = {
            param (
                [System.String] $NodeName,
                [System.Collections.Hashtable] $ConfigurationData,
                [System.String] $ModuleType
            )
            ResolveLabModule -NodeName $NodeName -ConfigurationData $ConfigurationData -ModuleType $ModuleType;
        }
        & $lability $scriptBlock -NodeName $NodeName -ConfigurationData $ConfigurationData -ModuleType $ModuleType;

    } #end process
} #end function ResolveLabModule


function ExpandModuleCache {
<#
    .SYNOPSIS

#>
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param (
        ## PowerShell module hashtable
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]] $Module,

        ## Destination directory path to download the PowerShell module/DSC resource module to
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath
    )
    process {

        $scriptBlock = {
            param (
                [System.Collections.Hashtable[]] $Module,
                [System.String] $DestinationPath
            )
            ExpandModuleCache -Module $Module -DestinationPath $DestinationPath;
        }
        & $lability $scriptBlock -Module $Module -DestinationPath $DestinationPath;

    } #end process
} #end function ExpandModuleCache
