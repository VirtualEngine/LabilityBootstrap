function Copy-LabModule {
<#
    .SYNOPSIS
        Copies the Lability PowerShell modules.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Lability bootstrap path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath
    )
    begin {
        [System.Collections.Hashtable] $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {

        $scriptBlock = {
            param (
                [System.Collections.Hashtable[]] $Module,
                [System.String] $DestinationPath
            )
            ExpandModuleCache -Module $Module -DestinationPath $DestinationPath;
        }

        if ($null -ne $ConfigurationData.NonNodeData.Lability.Module) {

            $modulesPath = Join-Path -Path $DestinationPath -ChildPath $defaults.ModulesPath;
            Write-Verbose -Message ($localized.CopyingPowerShellModules -f $modulesPath);

            if ($PSCmdlet.ShouldProcess($modulesPath, $localized.CopyPowerShellModulesConfirmation)) {
                & $lability $scriptBlock -Module $ConfigurationData.NonNodeData.Lability.Module -DestinationPath $modulesPath;
            }

        }

    } #end process
} #end function Copy-LabModule
