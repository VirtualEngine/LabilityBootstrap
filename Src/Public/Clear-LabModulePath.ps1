function Clear-LabModulePath {
<#
    .SYNOPSIS
        Removes all PowerShell modules from the specified scope.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Module installation scope
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet('AllUsers','CurrentUser')]
        [System.String] $Scope
    )
    process {

        if ($Scope -eq 'AllUsers') {
            $destinationPath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules';
        }
        elseif ($Scope -eq 'CurrentUser') {
            $userDocuments = [System.Environment]::GetFolderPath('MyDocuments');
            $destinationPath = Join-Path -Path $userDocuments -ChildPath 'WindowsPowerShell\Modules';
        }

        Remove-Item -Path $destinationPath -Recurse -Force;

    } #end process
} #end function Clear-LabModulePath
