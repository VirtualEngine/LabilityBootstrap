@{
    RootModule = 'LabilityBootstrap.psm1';
    ModuleVersion = '0.9.4';
    GUID = 'fbb5ce64-f09b-48e6-88d5-e668d82ca3ec';
    Author = 'Iain Brighton';
    CompanyName = 'Virtual Engine';
    Copyright = '(c) 2016 Virtual Engine Limited. All rights reserved.';
    Description = 'The LabilityBootstrap module contains cmdlets for manually bootstrapping Lability configurations on (virtual) machines.';
    PowerShellVersion = '4.0';
    RequiredModules = @('Lability');
    FunctionsToExport = @('Copy-LabBootstrap','Copy-LabCertificate','Copy-LabConfiguration','Copy-LabDscResource',
                            'New-LabBootstrapIso','New-LabIso','Copy-LabResource','Copy-LabModule','Install-LabModule',
                            'Add-LabIsoConfiguration','Write-LabIso');
    PrivateData = @{
        PSData = @{  # Private data to pass to the module specified in RootModule/ModuleToProcess
            Tags = @('VirtualEngine','Lability','Bootstrap','Powershell','Development','HyperV','Hyper-V','Test','Lab','TestLab');
            LicenseUri = 'https://github.com/VirtualEngine/LabilityBootstrap/blob/master/LICENSE';
            ProjectUri = 'https://github.com/VirtualEngine/LabilityBootstrap';
            IconUri = 'https://raw.githubusercontent.com/VirtualEngine/LabilityBootstrap/master/Lability.png';
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
