function Get-ConfigurationData {
<#
    .SYNOPSIS
        Retrieves Lability host configuration data.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Host','VM','Media','CustomMedia')]
        [System.String] $Configuration
    )
    process {

        $scriptBlock = {
            param (
                [System.String] $Configuration
            )
            GetConfigurationData -Configuration $Configuration;
        }


        & $lability $scriptBlock -Configuration $Configuration;

    } #end process
} #end function Get-ConfigurationData
