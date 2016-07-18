function Copy-LabModule {
<#
    .SYNOPSIS
        Copies the Lability PowerShell modules.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        ## Lability bootstrap path
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $DestinationPath
    )
    begin {
        [System.Collections.Hashtable] $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {

        $scriptBlock = {
            param (
                [System.Collections.Hashtable[]] $Module,
                [System.String] $DestinationPath
            )
            ExpandModuleCache -Module $Module -DestinationPath $DestinationPath;
        }

        if ($null -ne $ConfigurationData.NonNodeData.Lability.Module) {

            $modulesPath = Join-Path -Path $DestinationPath -ChildPath $defaults.ModulesPath;
            Write-Verbose -Message ($localized.CopyingPowerShellModules -f $modulesPath);

            if ($PSCmdlet.ShouldProcess($modulesPath, $localized.CopyPowerShellModulesConfirmation)) {
                & $lability $scriptBlock -Module $ConfigurationData.NonNodeData.Lability.Module -DestinationPath $modulesPath;
            }

        }

    } #end process
} #end function Copy-LabModule


function Install-LabModule {
<#
    .SYNOPSIS

#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Scope')]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $ConfigurationData,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $NodeName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Scope')]
        [ValidateSet('AllUsers','CurrentUser')]
        [System.String] $Scope = 'CurrentUser',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath
    )
    begin {

        [System.Collections.Hashtable] $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;

    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'Scope') {

            if ($Scope -eq 'AllUsers') {
                $DestinationPath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules';
            }
            elseif ($Scope -eq 'CurrentUser') {
                $userDocuments = [System.Environment]::GetFolderPath('MyDocuments');
                $DestinationPath = Join-Path -Path $userDocuments -ChildPath 'WindowsPowerShell\Modules';
            }
        }

        ## Install PowerShell modules
        if ($PSBoundParameters.ContainsKey('NodeName')) {
            $resolveLabModuleParams = @{
                NodeName = $NodeName;
                ConfigurationData = $ConfigurationData;
                ModuleType = 'Module';
            }
            $powerShellModules = ResolveLabModule @resolveLabModuleParams;
        }
        else {
            $powerShellModules = $ConfigurationData.NonNodeData.Lability.Module;
        }

        if ($null -ne $powerShellModules) {
            if ($PSCmdlet.ShouldProcess($DestinationPath, $localized.InstallModulesConfirmation)) {
                ExpandModuleCache -Module $powerShellModules -DestinationPath $DestinationPath;
            }
        }

        ## Install DSC resource modules
        if ($PSBoundParameters.ContainsKey('NodeName')) {
            $resolveLabModuleParams = @{
                NodeName = $NodeName;
                ConfigurationData = $ConfigurationData;
                ModuleType = 'DscResource';
            }
            $dscResourceModules = ResolveLabModule @resolveLabModuleParams;
        }
        else {
            $dscResourceModules = $ConfigurationData.NonNodeData.Lability.DSCResource;
        }

        if ($null -ne $dscResourceModules) {
            if ($PSCmdlet.ShouldProcess($DestinationPath, $localized.InstallDscResourcesConfirmation)) {
                ExpandModuleCache -Module $dscResourceModules -DestinationPath $DestinationPath;
            }
        }

    } #end process
} #end function Install-LabModule
