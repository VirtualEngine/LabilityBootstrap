function Resolve-Resource {
<#
    .SYNOPSIS
        Resolves a Lability custom resource from configuration data.
#>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Lab VM/Node name
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $ResourceId,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {

        $scriptBlock = {
            param (
                [System.String] $ResourceId,
                [System.Collections.Hashtable] $ConfigurationData
            )
            ResolveLabResource -ResourceId $ResourceId -ConfigurationData $ConfigurationData;
        }

        & $lability $scriptBlock -ResourceId $ResourceId -ConfigurationData $ConfigurationData;

    } #end process
} #end function Resolve-Resource
