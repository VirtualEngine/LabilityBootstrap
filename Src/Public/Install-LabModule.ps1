function Install-LabModule {
<#
    .SYNOPSIS
        Installs Lability PowerShell and DSC resource modules.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Module type(s) to install
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Module','DscResource')]
        [System.String[]] $ModuleType,

        ## Install a specific node's modules
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $NodeName,

        ## Module installation scope
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('AllUsers','CurrentUser')]
        [System.String] $Scope = 'CurrentUser'
    )
    process {

        if ($Scope -eq 'AllUsers') {
            $DestinationPath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules';
        }
        elseif ($Scope -eq 'CurrentUser') {
            $userDocuments = [System.Environment]::GetFolderPath('MyDocuments');
            $DestinationPath = Join-Path -Path $userDocuments -ChildPath 'WindowsPowerShell\Modules';
        }

        Copy-LabModule -ConfigurationData $ConfigurationData -ModuleType $ModuleType -DestinationPath $DestinationPath;

    } #end process
} #end function Install-LabModule
