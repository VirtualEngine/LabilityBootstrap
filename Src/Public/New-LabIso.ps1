function New-LabIso {
<#
    .SYNOPSIS
        Creates a new prestaged lab ISO folder structure.
#>
    [CmdletBinding()]
    param (
        ## Root ISO scratch path
        [Parameter(Mandatory)]
        [System.String] $Path
    )
    process {

        if (Test-Path -Path $Path) {

            $pathItem = Get-Item -Path $Path;
            if ($pathItem -is [System.IO.FileInfo]) {
                throw ($localized.PathIsNotDirectoryError -f $Path);
            }
        }
        else {

            Write-Verbose -Message ($localized.CreatingIsoRootDirectory -f $Path);
            [ref] $null = New-Item -Path $Path -ItemType Directory -Force;
        }

        ## Clean out any existing \Configurations directory
        $configurationsPath = Join-Path -Path $Path -ChildPath 'Configurations';
        if (Test-Path -Path $configurationsPath) {
            Write-Verbose -Message ($localized.RemovingConfigurationDirectory -f $configurationsPath);
            Remove-Item -Path $configurationsPath -Recurse -Force -Confirm:$false;
        }
        Write-Verbose -Message ($localized.CreatingConfigurationDirectory -f $configurationsPath);
        [ref] $null = New-Item -Path $configurationsPath -ItemType Directory -Force;

        ## Ensure we have a resources folder
        $resourcesPath = Join-Path -Path $Path -ChildPath 'Resources';
        if (-not (Test-Path -Path $resourcesPath)) {
            Write-Verbose -Message ($localized.CreatingResourceDirectory -f $resourcesPath);
            [ref] $null = New-Item -Path $resourcesPath -ItemType Directory -Force;
        }

    } #end process
} #end function New-LabIso
