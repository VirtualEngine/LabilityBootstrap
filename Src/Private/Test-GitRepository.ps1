function Test-GitRepository {
<#
    .SYNOPSIS
        Tests whether the supplied path is a Git repository
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.String] $Path = (Get-Location -PSProvider FileSystem).Path
    )
    process {
        $gitPath = Join-Path -Path $Path -ChildPath '.git';
        $isGitRepository = Test-Path -Path $gitPath -PathType Container;
        if (-not $isGitRepository) {
            Write-Warning -Message ($localized.InvalidGitRepositoryWarning -f $Path);
        }
        return $isGitRepository;
    }
} #end function Test-GitRepository
