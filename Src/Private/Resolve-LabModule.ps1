function Resolve-LabModule {
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
            Resolve-LabModule -NodeName $NodeName -ConfigurationData $ConfigurationData -ModuleType $ModuleType;
        }
        & $lability $scriptBlock -NodeName $NodeName -ConfigurationData $ConfigurationData -ModuleType $ModuleType;

    } #end process
} #end function Resolve-LabModule
