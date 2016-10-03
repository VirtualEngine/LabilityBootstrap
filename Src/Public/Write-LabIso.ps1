function Write-LabIso {
<#
    .SYNOPSIS
        Creates an ISO file from a prestaged lab folder structure.
#>
    [CmdletBinding()]
    param (
        ## Root ISO scratch path
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.String] $Path,

        ## Target ISO file path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath,

        ## ISO volume name
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $VolumeName
    )
    begin  {

        if (-not $PSBoundParameters.ContainsKey('VolumeName')) {

            $VolumeName = 'LabilityBootstrap {0}' -f (Get-Date).ToString('yyMM');
        }
    }
    process {

        $destinationDirectoryPath = Split-Path -Path $DestinationPath -Parent;
        if ([System.IO.Path]::GetExtension($DestinationPath) -ne '.iso') {

            throw ($localized.InvalidFileExtensionError -f $DestinationPath, 'ISO');
        }
        elseif (-not (Test-Path -Path $destinationDirectoryPath -PathType Container)) {

            Write-Verbose -Message ($localized.CreatingDestinationDirectory -f $destinationDirectoryPath);
            [ref] $null = New-Item -Path $destinationDirectoryPath -ItemType Directory -Force;
        }

        Write-Verbose -Message ($localized.UsingOutputPath -f $DestinationPath);
        Write-Verbose -Message ($localized.UsingVolumeName -f $VolumeName);
        $stopWatch = [System.Diagnostics.Stopwatch]::StartNew();
        New-IsoImage -Path $Path -DestinationPath $DestinationPath -VolumeName $VolumeName;
        Write-Verbose -Message ($localized.IsoFileCreatedIn -f $DestinationPath, $stopWatch.Elapsed.ToString());
        $stopWatch.Stop();

    } #end process
} #end function Write-LabIso
