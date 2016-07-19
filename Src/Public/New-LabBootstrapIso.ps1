function New-LabBootstrapIso {
<#
    .SYNOPSIS
        Creates a new Lability Bootstrap ISO image.
#>
    [CmdletBinding(DefaultParameterSetName = 'PSCredential', SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Target Lability bootstrap ISO file path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath,

        ## Local administrator password of the VM. The username is NOT used.
        [Parameter(ParameterSetName = 'PSCredential', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = (& $credentialCheckScriptBlock),

        ## Local administrator password of the VM.
        [Parameter(Mandatory, ParameterSetName = 'Password', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $Password,

        ## Source configurations/mofs path
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path = (Get-Item -Path $ConfigurationData).DirectoryName,

        ## ISO volume name (defaults to destination filename)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $VolumeName,

        ## Temporary directory path
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ScratchPath,

        ## Overwrite any existing resource files, e.g. expanded Iso/Zip archives
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    begin {

        ## If we have only a secure string, create a PSCredential
        if ($PSCmdlet.ParameterSetName -eq 'Password') {
            $Credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'LocalAdministrator', $Password;
        }
        if (-not $Credential) {
            throw ($localized.CannotProcessCommandError -f 'Credential');
        }
        elseif ($Credential.Password.Length -eq 0) {
            throw ($localized.CannotBindArgumentError -f 'Password');
        }

    }
    process {

        ## Test destination path is an existing folder
        if (-not (Test-Path -Path $DestinationPath -PathType Container)) {
            throw ($localized.InvalidDirectoryPathError -f $DestinationPath);
        }

        ## Store the configuration file path for copying later
        $ConfigurationDataPath =  $ConfigurationData;
        [System.Collections.Hashtable] $ConfigurationData = ConvertTo-ConfigurationData -ConfigurationData $ConfigurationData;

        if (-not $PSBoundParameters.ContainsKey('VolumeName')) {
            $EnvironmentName = $ConfigurationData.NonNodeData.Lability.EnvironmentName;
            if (-not $EnvironmentName) {
                $EnvironmentName = 'Lability';
            }
            $gitRevision = Get-GitRevision -Path $Path;
            $VolumeName = '{0} {1}.{2}' -f $EnvironmentName, (Get-Date).ToString('yyMM'), $gitRevision;
        }
        Write-Verbose -Message ($localized.UsingVolumeName -f $VolumeName);

        if (-not $PSBoundParameters.ContainsKey('ScratchPath')) {
            $ScratchPath = Join-Path -Path $env:Temp -ChildPath ($VolumeName.Replace(' ',''));
        }
        Write-Verbose -Message ($localized.UsingScratchPath -f $ScratchPath);
        [ref] $null = New-Item -Path $ScratchPath -ItemType Directory -Force;

        $bootstrapPath = Join-Path -Path $ScratchPath -ChildPath 'Bootstrap.ps1';
        [ref] $null = Copy-LabBootstrap -Credential $Credential -DestinationPath $bootstrapPath;

        Copy-LabCertificate -ConfigurationData $configurationDataPath -DestinationPath $ScratchPath;

        Copy-LabConfiguration -ConfigurationData $configurationDataPath -DestinationPath $ScratchPath -Path $Path;

        $modulesPath = Join-Path -Path $ScratchPath -ChildPath $defaults.ModulesPath;
        [ref] $null = Copy-LabModule -ConfigurationData $configurationDataPath -DestinationPath $modulesPath -ModuleType 'Module','DscResource';

        Copy-LabResource -ConfigurationData $configurationDataPath -DestinationPath $ScratchPath -Force:$Force;

        Get-ChildItem -Path $Path -Filter ReadMe* |
            ForEach-Object {
                Write-Verbose -Message ($localized.CopyingReadMeFile -f $_.Name);
                Copy-Item -Path $_.FullName -Destination $ScratchPath
            }

        $filename = '{0}.iso' -f $VolumeName.Replace(' ','');
        Write-Verbose -Message ($localized.UsingFilename -f $filename);

        $isoPath = Join-Path -Path $DestinationPath -ChildPath $filename;
        Write-Verbose -Message ($localized.UsingOutputPath -f $isoPath);

        New-IsoImage -Path $ScratchPath -DestinationPath $isoPath -VolumeName $VolumeName;

    }

} #end function New-LabBootstrapIso
