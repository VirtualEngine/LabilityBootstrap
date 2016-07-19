function Test-Git {
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
} #end function Test-Git
