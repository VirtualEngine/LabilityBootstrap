function Resolve-ConfigurationDataProperty {
<#
     .SYNOPSIS
         Resolves a node's defined propertes in a DSC configuration data document.
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

        ## Do not enumerate the AllNodes.'*' node
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $NoEnumerateWildcardNode
    )
    process {
        $scriptBlock = {
            param (
                [System.String] $NodeName,
                [System.Collections.Hashtable] $ConfigurationData,
                [System.Management.Automation.SwitchParameter] $NoEnumerateWildcardNode
            )
            ResolveLabVMProperties -NodeName $NodeName -ConfigurationData $ConfigurationData -NoEnumerateWildcardNode:$NoEnumerateWildcardNode;
        }
        & $lability $scriptBlock -NodeName $NodeName -ConfigurationData $ConfigurationData -NoEnumerateWildcardNode:$NoEnumerateWildcardNode;
    } #end process
} #end function Resolve-ConfigurationDataProperty