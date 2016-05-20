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
        [Parameter(ParameterSetName = 'PSCredential', ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = (& $credentialCheckScriptBlock),

        ## Local administrator password of the VM.
        [Parameter(Mandatory, ParameterSetName = 'Password', ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $Password,
        
        ## Source configurations/mofs path 
        [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.String] $Path = (Get-Item -Path $ConfigurationData).DirectoryName,
        
        ## ISO volume name (defaults to destination filename)
        [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.String] $VolumeName,
        
        ## Temporary directory path
        [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
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
        [System.Collections.Hashtable] $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
    
        if (-not $PSBoundParameters.ContainsKey('VolumeName')) {
            $EnvironmentName = $ConfigurationData.NonNodeData.Lability.EnvironmentName;
            if (-not $EnvironmentName) {
                $EnvironmentName = 'Lability';
            }
            $VolumeName = '{0} {1}' -f $EnvironmentName, (Get-Date).ToString('yyMM');
        }
        Write-Verbose ("Using volume name '{0}'." -f $VolumeName);
        
        if (-not $PSBoundParameters.ContainsKey('ScratchPath')) {
            $ScratchPath = Join-Path -Path $env:Temp -ChildPath ($VolumeName.Replace(' ',''));
        }
        Write-Verbose ("Using scratch path '{0}'." -f $ScratchPath);
        [ref] $null = New-Item -Path $ScratchPath -ItemType Directory -Force;
        
        $bootstrapPath = Join-Path -Path $ScratchPath -ChildPath 'Bootstrap.ps1';
        [ref] $null = Copy-LabBootstrap -Credential $Credential -DestinationPath $bootstrapPath;
        Copy-LabCertificate -ConfigurationData $configurationDataPath -DestinationPath $ScratchPath;
        Copy-LabConfiguration -ConfigurationData $configurationDataPath -DestinationPath $ScratchPath -Path $Path;
        Copy-LabDscResource -DestinationPath $ScratchPath;
        Copy-LabResource -ConfigurationData $configurationDataPath -DestinationPath $ScratchPath -Force:$Force;
        
        $filename = '{0}.iso' -f $VolumeName.Replace(' ','');
        Write-Verbose ("Using filename '{0}'." -f $filename);
        
        $isoPath = Join-Path -Path $DestinationPath -ChildPath $filename;
        Write-Verbose ("Using output path '{0}'." -f $isoPath);
        
        NewIsoImage -Path $ScratchPath -DestinationPath $isoPath -VolumeName $VolumeName;
        
    }
    
} #end function New-LabIso
