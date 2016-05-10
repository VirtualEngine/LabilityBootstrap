function ResolveResource {
<#
    .SYNOPSIS
        Resolves a Lability custom resource from configuration data.
#>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Lab VM/Node name
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $ResourceId,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {
        $scriptBlock = {
            param (
                [System.String] $ResourceId,
                [System.Collections.Hashtable] $ConfigurationData
            )
            ResolveLabResource -ResourceId $ResourceId -ConfigurationData $ConfigurationData;    
        }
        & $lability $scriptBlock -ResourceId $ResourceId -ConfigurationData $ConfigurationData;
    } #end process
} #end function ResolveResource

function ExpandIsoResource {
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
            ExpandIsoResource -Path $Path -DestinationPath $DestinationPath;
        }
        & $lability $scriptBlock -Path $Path -DestinationPath $DestinationPath;
    } #end process
} #end function ExpandIsoResource

function ExpandResource {
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
        
        ## Source resource path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ResourcePath,

        ## Overwrite any existing resource files
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {
        $resource = ResolveResource -ResourceId $ResourceId -ConfigurationData $ConfigurationData;
        $resourceItemPath = Join-Path -Path $ResourcePath -ChildPath $resource.Id;
        if ($resource.Filename) {
            $resourceItemPath = Join-Path -Path $ResourcePath -ChildPath $resource.Filename;
        }

        if (-not (Test-Path -Path $resourceItemPath)) {
            throw ($localized.ResourceNotFoundError -f $resourceItemPath);
        }
        else {
            $resourceItem = Get-Item -Path $resourceItemPath;
        }
        
        if ($resource.DestinationPath -and (-not [System.String]::IsNullOrEmpty($resource.DestinationPath))) {
            ## We can't account for custom destination paths here - they'll need to be accounted for on
            ## the target node before invoking the configuration. Ensure they're not expanded here.
        }
        
        $destinationRootPath = $DestinationPath;
        $destinationResourcePath = Join-Path -Path $DestinationPath -ChildPath $resourceId;
        
        if (($resource.Expand) -and ($resource.Expand -eq $true)) {
            switch ([System.IO.Path]::GetExtension($resourceItemPath)) {
                '.iso' {
                    if (-not (Test-Path -Path $destinationResourcePath)) {
                        [ref] $null = New-Item -Path $destinationResourcePath -ItemType Directory -Force;
                    }
                    if (((Get-ChildItem -Path $destinationResourcePath).Count -eq 0) -or $Force) {
                        ## Only expand resource if there's nothing there or we're forcing it
                        Write-Verbose ($localized.ExpandingIsoResource -f $ResourceItem.FullName);
                        ExpandIsoResource -Path $resourceItem.FullName -DestinationPath $destinationResourcePath;
                    }
                    else {
                        Write-Verbose ($localized.SkippingIsoResource -f $ResourceItem.FullName);
                    }
                }
                '.zip' {
                    if (-not (Test-Path -Path $destinationResourcePath)) {
                        [ref] $null = New-Item -Path $destinationResourcePath -ItemType Directory -Force;
                    }
                    if (((Get-ChildItem -Path $destinationResourcePath).Count -eq 0) -or $Force) {
                        Write-Verbose ($localized.ExpandingZipArchive -f $ResourceItem.FullName);
                        [ref] $null = ExpandZipArchive -Path $resourceItem.FullName -DestinationPath $destinationResourcePath -Verbose:$false;
                    }
                    else {
                        Write-Verbose ($localized.SkipingZipArchive -f $ResourceItem.FullName);
                    }
                }
                Default {
                    throw ($localized.ExpandNotSupportedError -f $resourceItem.Extension);
                }
            } #end switch
        }
        else {
            $targetPath = Join-Path -Path $destinationRootPath -ChildPath $resourceItem.Name;
            if ((-not (Test-Path -Path $targetPath)) -or $Force) {
                Write-Verbose ($localized.CopyingFileResource -f $resourceItem.FullName);
                Copy-Item -Path $resourceItem.FullName -Destination $destinationRootPath -Force -Verbose:$false;
            }
            else {
                Write-Verbose ($localized.SkippingFileResource -f $ResourceItem.FullName);
            }
        }
    } #end process
} #end function ExpandResource
