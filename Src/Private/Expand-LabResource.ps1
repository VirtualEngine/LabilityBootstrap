function Expand-LabResource {
<#
    .SYNOPSIS
        Expands Lability custom resources.
#>
    [CmdletBinding()]
    param (
        ## Destination path
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $ResourceId,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData,

        ## Destination path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath,

        ## Overwrite any existing resource files
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {

        $hostDefaults = Get-ConfigurationData -Configuration Host;
        $resourcePath = $hostDefaults.ResourcePath;
        $resource = Resolve-LabResource -ResourceId $ResourceId -ConfigurationData $ConfigurationData;
        $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Id;

        if ($resource.Filename) {

            $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Filename;
            if ($resource.IsLocal) {

                $resourceSourcePath = Resolve-Path -Path $resource.Filename;
            }
        }
        $resourceItem = Get-Item -Path $resourceSourcePath;

        $resourceRootDestinationPath = Join-Path -Path $DestinationPath -ChildPath $hostDefaults.ResourceShareName;
        $resourceDestinationPath = Join-Path -Path $resourceRootDestinationPath -ChildPath $resource.Id;

        if (($resource.Expand) -and ($resource.Expand -eq $true)) {

            switch ([System.IO.Path]::GetExtension($resourceSourcePath)) {

                '.iso' {

                    if (-not (Test-Path -Path $resourceDestinationPath)) {

                        [ref] $null = New-Item -Path $resourceDestinationPath -ItemType Directory -Force;
                    }
                    if (((Get-ChildItem -Path $resourceDestinationPath).Count -eq 0) -or $Force) {

                        ## Only expand resource if there's nothing there or we're forcing it
                        Write-Verbose ($localized.ExpandingIsoResource -f $resourceItem.FullName);
                        Expand-LabIsoResource -Path $resourceItem.FullName -DestinationPath $resourceDestinationPath;
                    }
                    else {

                        Write-Verbose ($localized.SkippingIsoResource -f $resourceItem.FullName);
                    }
                }

                '.zip' {

                    if (-not (Test-Path -Path $resourceDestinationPath)) {

                        [ref] $null = New-Item -Path $resourceDestinationPath -ItemType Directory -Force;
                    }
                    if (((Get-ChildItem -Path $resourceDestinationPath).Count -eq 0) -or $Force) {

                        Write-Verbose ($localized.ExpandingZipArchive -f $resourceItem.FullName);
                        [ref] $null = Expand-ZipArchive -Path $resourceItem.FullName -DestinationPath $resourceDestinationPath -Verbose:$false;
                    }
                    else {

                        Write-Verbose ($localized.SkippingZipArchive -f $resourceItem.FullName);
                    }
                }
                Default {

                    throw ($localized.ExpandNotSupportedError -f $resourceItem.Extension);
                }

            } #end switch
        }
        elseif ($resource.Filename) {

            $resourceDestinationPath = Join-Path -Path $resourceRootDestinationPath -ChildPath $resource.Filename;
            if ($resource.IsLocal) {

                $resourceRelativePath = ($resource.Filename).TrimStart('.');
                $resourceDestinationPath = Join-Path -Path $resourceRootDestinationPath -ChildPath $resourceRelativePath;

                ## Always replace local resources..
                if (Test-Path -Path $resourceDestinationPath) {
                    Write-Verbose -Message ($localized.RemovingStaleResource -f $resourceDestinationPath);
                    Remove-Item -Path $resourceDestinationPath -Force -Recurse -Verbose:$false;
                }
            }

            if ((-not (Test-Path -Path $resourceDestinationPath)) -or $Force) {

                Write-Verbose ($localized.CopyingFileResource -f $resourceItem.FullName);
                Copy-Item -Path $resourceItem.FullName -Destination $resourceDestinationPath -Force -Recurse -Verbose:$false;
            }
            else {

                Write-Verbose ($localized.SkippingFileResource -f $ResourceItem.FullName);
            }
        }
        else {

            throw ($localized.NoFilenameDefinedError -f $resource.Id);
        }

    } #end process
} #end function Expand-LabResource
