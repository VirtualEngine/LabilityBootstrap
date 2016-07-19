function Expand-ZipArchive {
<#
    .SYNOPSIS
        Extracts a GitHub Zip archive.
    .NOTES
        This is an internal function and should not be called directly.
    .LINK
        This function is derived from the VirtualEngine.Compression (https://github.com/VirtualEngine/Compression) module.
    .OUTPUTS
        A System.IO.FileInfo object for each extracted file.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param (
        # Source path to the Zip Archive.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath','FullName')]
        [System.String[]] $Path,

        # Destination file path to extract the Zip Archive item to.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath,

        # Excludes NuGet .nuspec specific files
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $ExcludeNuSpecFiles,

        # Overwrite existing files
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {

        $scriptBlock = {
            param (
                [System.String[]] $Path,
                [System.String] $DestinationPath,
                [System.Management.Automation.SwitchParameter] $ExcludeNuSpecFiles,
                [System.Management.Automation.SwitchParameter] $Force
            )
            ExpandZipArchive -Path $Path -DestinationPath $DestinationPath -ExcludeNuSpecFiles:$ExcludeNuSpecFiles -Force:$Force;
        }

        & $lability $scriptBlock  -Path $Path -DestinationPath $DestinationPath -ExcludeNuSpecFiles:$ExcludeNuSpecFiles -Force:$Force;

    }
} #end function Expand-ZipArchive
