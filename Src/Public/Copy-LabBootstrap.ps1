function Copy-LabBootstrap {
<#
    .SYNOPSIS
        Copies the Lability Bootstrap.ps1 file to the path specified.
#>
    [CmdletBinding(DefaultParameterSetName = 'PSCredential', SupportsShouldProcess)]
    param (
        ## Local administrator password of the VM. The username is NOT used.
        [Parameter(ParameterSetName = 'PSCredential', ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = (& $credentialCheckScriptBlock),

        ## Local administrator password of the VM.
        [Parameter(Mandatory, ParameterSetName = 'Password', ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $Password,

        ## Lability bootstrap path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath
    )
    begin {
        ## If we have only a secure string, create a PSCredential
        if ($PSCmdlet.ParameterSetName -eq 'Password') {
            $Credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'LocalAdministrator', $Password;
        }
        if (-not $Credential) { throw ($localized.CannotProcessCommandError -f 'Credential'); }
        elseif ($Credential.Password.Length -eq 0) { throw ($localized.CannotBindArgumentError -f 'Password'); }
    }
    process {

        $bootstrapPath = Join-Path -Path $defaults.ModuleRoot -ChildPath 'Lib\Bootstrap.ps1';
        $unsecuredPassword = ConvertTo-InsecureString -Password $Credential.Password;
        $bootstrapContent = Get-Content -Path $bootstrapPath | ForEach-Object {
            $_ -replace '##PASSWORDPLACEHOLDER##', $unsecuredPassword;
        }

        if ($PSCmdlet.ShouldProcess($DestinationPath)) {
            $bootstrapContent | Set-Content -Path $DestinationPath -Encoding UTF8 -Force -Confirm:$false;
            return (Get-Item -Path $DestinationPath);
        }

    } #end process
} #end function Copy-LabBootstrap
