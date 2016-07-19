function Expand-LabIsoResource {
<#
    .SYNOPSIS
        Expands a Lability ISO disk image resource.
#>
    param (
        ## Source ISO file path
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $Path,

        ## Destination folder path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath
    )
    process {

        $scriptBlock = {
            param (
                [System.String] $Path,
                [System.String] $DestinationPath
            )
            ExpandIso -Path $Path -DestinationPath $DestinationPath;
        }
        & $lability $scriptBlock -Path $Path -DestinationPath $DestinationPath;

    } #end process
} #end function Expand-LabIsoResource
