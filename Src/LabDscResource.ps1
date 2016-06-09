function Copy-LabDscResource {
<#
    .SYNOPSIS
        Copies the Lability PowerShell DSC resource modules.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath
    )
    process {
        $scriptBlock = {
            param (
                [System.String] $DestinationPath
            )
            SetLabVMDiskDscResource -DestinationPath $DestinationPath;    
        }
        
        $modulesPath = Join-Path -Path $DestinationPath -ChildPath $defaults.ModulesPath;
        Write-Verbose -Message ($localized.CopyingDscResourceModules -f $modulesPath);
        if ($PSCmdlet.ShouldProcess($modulesPath, $localized.CopyDscModulesConfirmation)) {
             & $lability $scriptBlock -DestinationPath $modulesPath;
        }
    } #end process
} #end function Copy-LabDscResource
