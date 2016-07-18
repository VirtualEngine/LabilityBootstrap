function Get-GitRevision {
<#
    .SYNOPSIS
        Returns the number of commits to the Git repository
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.String] $Path = (Get-Location -PSProvider FileSystem).Path
    )
    process {
        if ((Test-Git) -and (Test-GitRepository -Path $Path)) {
            return (& git.exe rev-list HEAD --count) -as [System.Int32];
        }
        return 0;
    }
} #end function Get-GitRevision
