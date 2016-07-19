function New-LabBootstrapVhd {
<#
    .SYNOPSIS
        Creates a new Lability Bootstrap VHD(X) disk image.
#>
    [CmdletBinding(DefaultParameterSetName = 'PSCredential', SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Target Lability bootstrap VHD(X) file path
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

        ## VHD(X) volume name (defaults to destination filename)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $VolumeName,

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

    } #end begin
    process {



    } #end process
} #end function New-LabBootstrapVhd
