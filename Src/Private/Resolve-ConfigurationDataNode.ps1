function Resolve-ConfigurationDataNode {
<#
     .SYNOPSIS
         Resolves all nodes defined in a DSC configuration data document.
 #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {

        return $ConfigurationData.AllNodes.Where({ $_.NodeName -ne '*'}).NodeName;

    }
} #end function Resolve-ConfigurationDataNode
