#Requires -RunAsAdministrator

## Import localisation strings
Import-LocalizedData -BindingVariable localized -FileName Resources.psd1;
$lability = Get-Module -Name 'Lability';

$defaults = @{
    ModuleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
    ModulesPath = 'Modules';
    ResourcesPath = 'Resources';
    ConfigurationsPath = 'Configurations';
    CertificatesPath = 'Certificates';
}

## Import the \Lib files. This permits loading of the module's functions for unit testing, without having to unload/load the module.
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$moduleLibPath = Join-Path -Path $moduleRoot -ChildPath 'Lib';
$moduleSrcPath = Join-Path -Path $moduleRoot -ChildPath 'Src';
Get-ChildItem -Path $moduleLibPath,$moduleSrcPath -Include *.ps1 -Exclude 'Bootstrap.ps1' -Recurse |
    ForEach-Object {
        Write-Verbose -Message ('Importing library\source file ''{0}''.' -f $_.FullName);
        . $_.FullName;
    }

## Create the credential check scriptblock
$credentialCheckScriptBlock = {
    ## Only prompt if -Password is not specified. This works around the credential pop-up regardless of the ParameterSet!
    if ($PSCmdlet.ParameterSetName -eq 'PSCredential') {
        Get-Credential -Message $localized.EnterLocalAdministratorPassword -UserName 'LocalAdministrator';
    }
}
