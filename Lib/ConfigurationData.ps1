function ConvertToConfigurationData {
<#
     .SYNOPSIS
         Converts a file path string to a hashtable. This mimics the -ConfigurationData parameter of the
         Start-DscConfiguration cmdlet.
 #>
     [CmdletBinding()]
     [OutputType([System.Collections.Hashtable])]
     param (
         [Parameter(Mandatory, ValueFromPipeline)]
         [System.String] $ConfigurationData
     )
     process {
        $configurationDataPath = Resolve-Path -Path $ConfigurationData -ErrorAction Stop;
        if (-not (Test-Path -Path $configurationDataPath -PathType Leaf)) {
            throw ($localized.InvalidConfigurationDataFileError -f $ConfigurationData);
        }
        elseif ([System.IO.Path]::GetExtension($configurationDataPath) -ne '.psd1') {
            throw ($localized.InvalidConfigurationDataFileError -f $ConfigurationData);
        }
        $configurationDataContent = Get-Content -Path $configurationDataPath -Raw;
        $configData = Invoke-Command -ScriptBlock ([System.Management.Automation.ScriptBlock]::Create($configurationDataContent));
        if ($configData -isnot [System.Collections.Hashtable]) {
            throw ($localized.InvalidConfigurationDataType -f $configData.GetType());
        }
        return $configData;
    }
} #end function ConvertToConfigurationData

function ResolveConfigurationDataNodes {
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
} #end function ResolveConfigurationDataNodes    

function ResolveConfigurationDataProperties {
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
} #end function ResolveConfigurationDataProperties

function GetConfigurationData {
<#
    .SYNOPSIS
        Retrieves Lability host configuration data.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory)] [ValidateSet('Host','VM','Media','CustomMedia')]
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
} #end function GetConfigurationData
