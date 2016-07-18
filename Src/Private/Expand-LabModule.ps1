function Expand-LabModule {
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
            Expand-LabModule -Module $Module -DestinationPath $DestinationPath -Clean;
        }
        & $lability $scriptBlock -Module $Module -DestinationPath $DestinationPath;

    } #end process
} #end function Expand-LabModule
