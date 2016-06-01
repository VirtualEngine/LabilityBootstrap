function TestGit {
<#
    .SYNOPSIS
        Tests for the presence of Git.exe
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ( )
    process {
        $git = Get-Command -Name Git -ErrorAction SilentlyContinue;
        if ($git.CommandType -eq 'Application') {
            return $true;
        }
        Write-Warning -Message $localized.GitNotFoundWarning;
        return $false;
    }
} #end function TestGit

function TestGitRepository {
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
} #end function TestGitRepository


function GetGitRevision {
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
        if ((TestGit) -and (TestGitRepository -Path $Path)) {
            return (& git.exe rev-list HEAD --count) -as [System.Int32];
        }
        return 0;
    }
} #end function GetGitRevision
