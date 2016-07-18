function Copy-LabCertificate {
<#
    .SYNOPSIS
        Copies the Lability client certificates.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Lability bootstrap path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath,

        ## Lab VM/Node name
        [Parameter(ValueFromPipeline)]
        [System.String[]] $NodeName
    )
    begin {
        [System.Collections.Hashtable] $ConfigurationData = ConvertTo-ConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('NodeName')) {
            $NodeName = Resolve-ConfigurationDataNode -ConfigurationData $ConfigurationData;
        }

        $certificates = @{};
        foreach ($vm in $NodeName) {
            ## Create a hashtable of unique certificates
            $vmProperties = Resolve-ConfigurationDataProperty -NodeName $vm -ConfigurationData $ConfigurationData;
            $rootCertificate = Get-Item -Path $vmProperties.RootCertificatePath;
            $certificates[($rootCertificate.Name)] = $rootCertificate;
            $clientCertificate = Get-Item -Path $vmProperties.ClientCertificatePath;
            $certificates[($clientCertificate.Name)] = $clientCertificate;
        }

        $certificatePath = Join-Path -Path $DestinationPath -ChildPath $defaults.CertificatesPath;
        if (-not (Test-Path -Path $certificatePath)) {
            if ($PSCmdlet.ShouldProcess($certificatePath, $localized.CreateDirectoryConfirmation)) {
                [ref] $null = New-Item -Path $certificatePath -ItemType Directory -Force -Confirm:$false;
            }
        }

        foreach ($certificate in $Certificates.Values) {
            $certificateDestinationPath = Join-Path -Path $certificatePath -ChildPath $certificate.Name;
            if ($PSCmdlet.ShouldProcess($certificateDestinationPath, $localized.CopyFileConfirmation)) {
                Write-Verbose -Message ($localized.CopyingCertificate -f $certificate.Name, $certificatePath);
                $certificate | Copy-Item -Destination $certificatePath -Confirm:$false;
            }
        }

    } #end process
} #end function Copy-LabCertificate
