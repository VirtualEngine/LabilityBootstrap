#requires -RunAsAdministrator
#requires -Version 4.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
    ## Name of the node in the PowerShell DSC configuration document (.psd1) to apply
    [Parameter()] [ValidateNotNullOrEmpty()]
    [System.String] $NodeName,

    ## Override the root path, i.e. when not running from an .Iso image
    [Parameter()] [ValidateNotNullOrEmpty()]
    [System.String] $RootPath = $PSScriptRoot,
    
    ## PowerShell DSC configuration (.psd1) document
    [Parameter()] [ValidateNotNullOrEmpty()]
    [System.Collections.Hashtable]
    [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
    $ConfigurationData = "$RootPath\Configurations\ConfigurationData.psd1",
        
    ## Expected local Administrator account password
    [Parameter()] [ValidateNotNull()]
    [System.Security.SecureString] $Password = (ConvertTo-SecureString -String '##PASSWORDPLACEHOLDER##' -AsPlainText -Force)
)

if (-not $PSBoundParameters.ContainsKey('NodeName')) {
    ## Attempt to resolve using the local hostname
    $NodeName = $env:COMPUTERNAME;
}

if (-not ($ConfigurationData.AllNodes | Where { $_.NodeName -eq $NodeName })) {
    throw ("Cannot resolve node name '{0}'. Please specify a valid -NodeName <NodeName>" -f $NodeName);
}

Write-Host ("Successfully located node '{0}'." -f $NodeName) -ForegroundColor Green;

#region private functions

    function ConvertToString {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)] [ValidateNotNull()]
            [System.Security.SecureString] $Password
        )
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Password);
        $unsecuredString = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr);
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr);
        return $unsecuredString;
    }

    function ResolveConfigurationDataProperties {
        [CmdletBinding()]
        [OutputType([System.Collections.Hashtable])]
        param (
            [Parameter(Mandatory, ValueFromPipeline)] [System.String] $NodeName,
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)] [System.Collections.Hashtable]
                [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()] $ConfigurationData,
            [Parameter(ValueFromPipelineByPropertyName)] [System.Management.Automation.SwitchParameter] $NoEnumerateWildcardNode
        )
        process {
            $node = @{ };

            ## Retrieve the AllNodes.$NodeName properties
            $ConfigurationData.AllNodes.Where({ $_.NodeName -eq $NodeName }) | ForEach-Object {
                foreach ($key in $_.Keys) {
                    $node[$key] = $_.$key;
                }
            }

            ## Rename/overwrite existing parameter values where $moduleName-specific parameters exist
            foreach ($key in @($node.Keys)) {
                if ($key.StartsWith('Lability_')) {
                    $node[($key.Replace('Lability_',''))] = $node.$key;
                    $node.Remove($key);
                }
            }

            return $node;
        } #end process
    } #end function ResolveConfigurationDataProperties

#endregion private functions

$nodeData = ResolveConfigurationDataProperties -NodeName $NodeName -ConfigurationData $ConfigurationData;
if ($nodeData.RequiredWMFVersion -or $nodeData.MinimumWMFVersion) {
    
    Write-Host "Checking Windows Management Framework version... " -ForegroundColor Cyan -NoNewline;
    if ($nodeData.RequiredWMFVersion -and ($PSVersionTable.PSVersion.Major -ne $nodeData.RequiredWMFVersion)) {
        Write-Host 'Failed :(' -ForegroundColor Red;
        throw ("Invalid Windows Management Framework version '{0}'. Required version '{1}'." -f $PSVersionTable.PSVersion.Major, $nodeData.RequiredWMFVersion);
    }
    elseif ($nodeData.MinimumWMFVersion -and ($PSVersionTable.PSVersion.Major -lt $nodeData.MinimumWMFVersion)) {
        Write-Host 'Failed :(' -ForegroundColor Red;
        throw ("Invalid Windows Management Framework version '{0}'. Minimum version '{1}'." -f $PSVersionTable.PSVersion.Major, $nodeData.MinimumWMFVersion);
    }
    Write-Host 'OK!' -ForegroundColor Green;

} #end WMF check

## Test local Administrator password..
Write-Host "Testing local Administrator password... " -ForegroundColor Cyan -NoNewline;
Add-Type -AssemblyName System.DirectoryServices.AccountManagement;
$unsecuredString = ConvertToString -Password $Password;
$prinipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
if (-not ($prinipalContext.ValidateCredentials('Administrator', $unsecuredString))) {
    Write-Host 'Failed :(' -ForegroundColor Red;
    throw ("Incorrect local Administrator password. Please change the local Administrator password to '{0}'." -f $unsecuredString);
}
Write-Host 'OK!' -ForegroundColor Green;

## Test PowerShell remoting to be able to "push" DSC configuration..
Write-Host "Testing PSRemoting... " -ForegroundColor Cyan -NoNewline;
if (-not (Test-WSMan -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue)) {
    Enable-PSRemoting -SkipNetworkProfileCheck -Force -ErrorAction Stop | Write-Verbose;
}
Write-Host 'OK!' -ForegroundColor Green;

## Test WSMan\MaxEnvelopeSizeKb..
Write-Host "Testing WSMan... " -ForegroundColor Cyan -NoNewline;
$maxEnvelopeSizeKb = (Get-WSManInstance -ResourceURI winrm/config).MaxEnvelopeSizekb -as [System.Int32];
if ($maxEnvelopeSizeKb -lt 1024) {
    [ref] $null = Set-WSManInstance -ResourceURI winrm/config -ValueSet @{ MaxEnvelopeSizekb = '1024'; }
}
Write-Host 'OK!' -ForegroundColor Green;

Write-Host ("Installing certificates..") -ForegroundColor Cyan;
Get-ChildItem -Path "$RootPath\Certificates" | ForEach-Object {
    
    if ($PSCmdlet.ShouldProcess($_.Name, 'Install Certificate')) {
        if ($_.Extension -eq '.cer') {
            certutil.exe -addstore -f "Root" $_.FullName | Write-Verbose;
        }
        elseif ($_.Extension -eq '.pfx') {
            "" | certutil.exe -f -importpfx $_.FullName | Write-Verbose;
        }
    }

} #end certificates

Write-Host ("Copying modules..") -ForegroundColor Cyan;
Get-ChildItem -Path "$RootPath\Modules" | ForEach-Object {

    if ($PSCmdlet.ShouldProcess($_.Name, 'Install Module')) {
        Copy-Item -Path $_.FullName -Destination "$env:ProgramFiles\WindowsPowerShell\Modules" -Recurse -Force -Verbose:$false;
    }

} #end modules

Write-Host ("Deploying resources..") -ForegroundColor Cyan;
$resourcePath = Join-Path -Path $RootPath -ChildPath Resources;
foreach ($resourceId in $nodeData.Resource) {

    $resource = $ConfigurationData.NonNodeData.Lability.Resource | Where-Object Id -eq $ResourceId;
    if ($resource.DestinationPath) {
        $sourcePath = Join-Path $resourcePath -ChildPath $resourceId;
        $destinationPath = Join-Path -Path $env:SystemDrive -ChildPath $resource.DestinationPath;
        if ($PSCmdlet.ShouldProcess("$destinationPath\$resourceId", 'Copy Resource')) {
            [ref] $null = New-Item -Path $destinationPath -ItemType Directory -Force -Confirm:$false;
            Get-ChildItem -Path $sourcePath | Copy-Item -Destination $destinationPath -Recurse -Force -Verbose:$false -Confirm:$false;
        }
    }

} #end resources

Write-Host ("Configurating LCM..") -ForegroundColor Cyan;
$sourceMetaMofPath = Join-Path -Path $RootPath -ChildPath "Configurations\$NodeName.meta.mof";
if ($PSCmdlet.ShouldProcess($sourceMetaMofPath, 'Configure LCM')) {
    
    $tempPath = Join-Path -Path $env:SystemRoot -ChildPath 'Temp';
    $localhostMetaMofPath = Join-Path -Path $tempPath -ChildPath 'localhost.meta.mof';    
    Copy-Item -Path $sourceMetaMofPath -Destination $localhostMetaMofPath -Confirm:$false -Verbose:$false -Force;
    Set-DscLocalConfigurationManager -Path $tempPath -ErrorAction Stop;

} #end LCM

Write-Host ("Starting Configuration...") -ForegroundColor Green;
$sourceMofPath = Join-Path -Path $RootPath -ChildPath "Configurations\$NodeName.mof";
if ($PSCmdlet.ShouldProcess($sourceMofPath, 'Start Configuration')) {
    
    $tempPath = Join-Path -Path $env:SystemRoot -ChildPath 'Temp';
    $localhostMofPath = Join-Path -Path $tempPath -ChildPath 'localhost.mof';
    
    $mofContent = Get-Content -Path $sourceMofPath;
    if ($PSVersionTable.PSVersion.Major -eq 4) {
        ## Convert the .mof to v4 compatible - credit to Mike Robbins
        ## http://mikefrobbins.com/2014/10/30/powershell-desired-state-configuration-error-undefined-property-configurationname/
        $mofContent = $mofContent -replace '^\sName=.*;$|^\sConfigurationName\s=.*;$';
    }
    
    ## Locate the first enabled NIC interface alias
    $interfaceAlias = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter 'NetConnectionStatus = "2"' | Select -First 1 -ExpandProperty NetConnectionId;
    $mofContent = $mofContent -replace 'Ethernet', $interfaceAlias;
    $mofContent = $mofContent -replace 'Local Area Connection', $interfaceAlias;

    ## Replace 'Path = "C:\\Resources\\" references with "BootstrapDrive:\\Resources" reference
    $resourceReplacement = ('{0}\' -f (Join-Path -Path $RootPath -ChildPath 'Resources')).Replace('\','\\');
    $mofContent = $mofContent -replace 'C:\\\\Resources\\\\', $resourceReplacement;

    $mofContent | Set-Content -Path $localhostMofPath -Encoding Unicode -Force -Confirm:$false;
    Start-DscConfiguration -Path $tempPath -Wait -Verbose -Force -ErrorAction Stop;

} #end configuration
