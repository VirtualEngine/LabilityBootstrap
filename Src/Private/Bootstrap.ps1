#requires -RunAsAdministrator
#requires -Version 4.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
    ## Name of the node in the PowerShell DSC configuration document (.psd1) to apply
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [System.String] $NodeName,

    ## Override the root path, i.e. when not running from an .Iso image
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [System.String] $RootPath = $PSScriptRoot,

    ## PowerShell DSC configuration (.psd1) document
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.Hashtable]
    [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
    $ConfigurationData = "$RootPath\Configurations\ConfigurationData.psd1",

    ## Override the root path, i.e. when not running from an .Iso image
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [System.String] $ResourcePath,

    ## Expected local Administrator account password
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNull()]
    [System.Security.SecureString] $Password = (ConvertTo-SecureString -String '##PASSWORDPLACEHOLDER##' -AsPlainText -Force),

    ## Prepares the local machine, but does not invoke the DSC configuration. The DSC configuration can
    ## be manually started by running `Start-DscConfiguration -Path C:\Windows\Temp -Wait -Verbose -Force`
    [Parameter(ValueFromPipelineByPropertyName)]
    [System.Management.Automation.SwitchParameter] $PrepareOnly,

    ## Skips the local administrator password checks. USE WITH CAUTION!
    [Parameter(ValueFromPipelineByPropertyName)]
    [System.Management.Automation.SwitchParameter] $SkipAdministratorPasswordCheck
)

if (-not $PSBoundParameters.ContainsKey('NodeName')) {
    ## Attempt to resolve using the local hostname
    $NodeName = $env:COMPUTERNAME;
}

if (-not ($ConfigurationData.AllNodes | Where { $_.NodeName -eq $NodeName })) {
    throw ("Cannot resolve node name '{0}'. Please specify a valid -NodeName <NodeName>" -f $NodeName);
}

if ($host.Name -eq 'ConsoleHost') {

    $consoleProfileContent = @'
# Reset colours in the current session to match the ISE
$host.PrivateData.WarningBackgroundColor = 'DarkMagenta';
$host.PrivateData.WarningForegroundColor = 'Yellow';
$host.PrivateData.VerboseBackgroundColor = 'DarkMagenta';
$host.PrivateData.VerboseForegroundColor = 'Cyan';
'@

    # Reset colours in the current session to match the ISE
    $host.PrivateData.WarningBackgroundColor = 'DarkMagenta';
    $host.PrivateData.WarningForegroundColor = 'Yellow';
    $host.PrivateData.VerboseBackgroundColor = 'DarkMagenta';
    $host.PrivateData.VerboseForegroundColor = 'Cyan';

    $defaultUserProfileFolder = Join-Path -Path $env:PUBLIC -ChildPath '\Documents\WindowsPowerShell';
    $defaultUserProfilePath = Join-Path -Path $defaultUserProfileFolder -ChildPath (Split-Path -Path $profile -Leaf);
    $profilePaths = $defaultUserProfilePath, $profile;

    ## Update the local PowerShell profile and the default user PowerSHell profile
    foreach ($profilePath in $profilePaths) {

        # Reset the colours in the current user's console PowerShell profile
        if (-not (Test-Path -Path (Split-Path -Path $profilePath -Parent) -PathType Container)) {

            # Create the profile folder
            [ref] $null = New-Item -Path (Split-Path -Path $profilePath -Parent) -ItemType Directory -Force;
        }

        if (-not (Test-Path -Path $profilePath -PathType Leaf)) {

            # Create the profile file
            Set-Content -Path $profilePath -Value $consoleProfileContent -Force;
        }
        elseif ((Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue) -notmatch '\$host\.PrivateData\.') {

            # Update the existing profile file
            Add-Content -Path $profilePath -Value $consoleProfileContent -Force;
        }
    }
}

Write-Host ("Successfully located node '{0}'." -f $NodeName) -ForegroundColor Green;

#region private functions

    function Unprotect-SecureString {
        [CmdletBinding()]
        [OutputType([System.String])]
        param (
            [Parameter(Mandatory)]
            [ValidateNotNull()]
            [System.Security.SecureString] $Password
        )
        process {

            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Password);
            $unsecuredString = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr);
            [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr);
            return $unsecuredString;

        } #end process
    } #end function Unprotect-SecureString

    function Resolve-ConfigurationDataProperty {
        [CmdletBinding()]
        [OutputType([System.Collections.Hashtable])]
        param (
            [Parameter(Mandatory, ValueFromPipeline)]
            [System.String] $NodeName,

            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [System.Collections.Hashtable]
            [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
            $ConfigurationData,

            [Parameter(ValueFromPipelineByPropertyName)]
            [System.Management.Automation.SwitchParameter] $NoEnumerateWildcardNode
        )
        process {

            $node = @{ };

            ## Retrieve the AllNodes.$NodeName properties
            $ConfigurationData.AllNodes.Where({ $_.NodeName -eq $NodeName }) |
                ForEach-Object {

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
    } #end function Resolve-ConfigurationDataProperty

#endregion private functions

$nodeData = Resolve-ConfigurationDataProperty -NodeName $NodeName -ConfigurationData $ConfigurationData;
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

if ($nodeData.ContainsKey('SecureBoot')) {

    Write-Host "Checking Secure Boot... " -ForegroundColor Cyan -NoNewline;
    $windowsVersion = (Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Version) -as [System.Version];
    ## Confirm-SecureBootUEFI only available on Windows 8/2012 and later
    if ($windowsVersion -ge (New-Object -TypeName 'System.Version' -ArgumentList 6,2)) {

        try {

            if ($nodeData.SecureBoot -ne (Confirm-SecureBootUEFI -ErrorAction SilentlyContinue)) {

                $expectedSecureBootString = if ($nodeData.SecureBoot) { 'Enabled' } else { 'Disabled' };
                throw ("Incorrect Secure Boot setting. Expected Secure Boot to be '{0}'." -f $expectedSecureBootString);
            }
            else {

                Write-Host 'OK!' -ForegroundColor Green;
            }
        }
        catch [System.NotSupportedException] {
            ## Swallow the exception as it's probably a Generation 1 VM
        }
    }
    else {

        Write-Host 'Skipped.' -ForegroundColor Yellow;
    }

} #end Secure Boot check

Write-Host "Testing local Administrator password... " -ForegroundColor Cyan -NoNewline;
if (-not $SkipAdministratorPasswordCheck) {

    ## Test local Administrator password..
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement;
    $unsecuredString = Unprotect-SecureString -Password $Password;
    $prinipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
    if (-not ($prinipalContext.ValidateCredentials('Administrator', $unsecuredString))) {

        Write-Host 'Failed :(' -ForegroundColor Red;
        throw ("Incorrect local Administrator password. Please change the local Administrator password to '{0}'." -f $unsecuredString);
    }

    Write-Host 'OK!' -ForegroundColor Green;
}
else {

        Write-Host 'Skipped.' -ForegroundColor Yellow;
    }

## Test network profile type (required for Set-WSManInstance)
Write-Host "Testing Network Profile(s)... " -ForegroundColor Cyan -NoNewline;
$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([System.Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}'));
$networkProfileTypes = $networkListManager.GetNetworkConnections() | ForEach-Object {
    $_.GetNetwork().GetCategory();
}
if ($networkProfileTypes -contains 0) {

    try {

        ## Public profile(s)
        $networkListManager.GetNetworkConnections() | ForEach-Object {
            $_.GetNetwork().SetCategory(1);
        }
        Write-Host 'Updated' -ForegroundColor Yellow;
    }
    catch {

        Write-Host 'Failed' -ForegroundColor Red;
    }
}
else {

    Write-Host 'OK!' -ForegroundColor Green;
}

## Test PowerShell remoting to be able to "push" DSC configuration..
Write-Host "Testing PSRemoting... " -ForegroundColor Cyan -NoNewline;
if (-not (Test-WSMan -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue)) {

    Enable-PSRemoting -SkipNetworkProfileCheck -Force -ErrorAction Stop | Write-Verbose;
    Write-Host 'Enabled' -ForegroundColor Yellow;
}
else {

    Write-Host 'OK!' -ForegroundColor Green;
}

## Test WSMan\MaxEnvelopeSizeKb..
Write-Host "Testing WSMan... " -ForegroundColor Cyan -NoNewline;
$maxEnvelopeSizeKb = (Get-WSManInstance -ResourceURI winrm/config).MaxEnvelopeSizekb -as [System.Int32];
if ($maxEnvelopeSizeKb -lt 1024) {

    [ref] $null = Set-WSManInstance -ResourceURI winrm/config -ValueSet @{ MaxEnvelopeSizekb = '1024'; }
    Write-Host 'Updated' -ForegroundColor Yellow;
}
else {

    Write-Host 'OK!' -ForegroundColor Green;
}

Write-Host ("Installing certificates") -ForegroundColor Cyan;
Get-ChildItem -Path "$RootPath\Certificates" | ForEach-Object {

    Write-Host (" Installing certificate $($_.BaseName)... ") -ForegroundColor Gray -NoNewline;
    if ($PSCmdlet.ShouldProcess($_.Name, 'Install Certificate')) {

        if ($_.Extension -eq '.cer') {

            certutil.exe -addstore -f "Root" $_.FullName | Write-Verbose;
        }
        elseif ($_.Extension -eq '.pfx') {

            "" | certutil.exe -f -importpfx $_.FullName | Write-Verbose;
        }
    }
    Write-Host 'OK!' -ForegroundColor Green;

} #end certificates

Write-Host ("Deploying modules... ") -ForegroundColor Cyan;
Get-ChildItem -Path "$RootPath\Modules" | ForEach-Object {

    try {

        Write-Host (" Copying module '$($_.BaseName)'... ") -ForegroundColor Gray -NoNewline;
        if ($PSCmdlet.ShouldProcess($_.Name, 'Install Module')) {


            Copy-Item -Path $_.FullName -Destination "$env:ProgramFiles\WindowsPowerShell\Modules" -Recurse -Force -Verbose:$false -PassThru |
            Where-Object { $_ -is [System.IO.FileInfo] } |  ForEach-Object {
                    Set-ItemProperty -Path $_.FullName -Name IsReadOnly -Value $false -Verbose:$false;
                }
            Write-Host 'OK!' -ForegroundColor Green;
        }

    }
    catch {

        Write-Host 'Failed' -ForegroundColor Red;
    }
} #end modules

if (-not $PSBoundParameters.ContainsKey('ResourcePath')) {

    ## TODO: Need resource root (could be something other than \Resources\)!
    $ResourcePath = Join-Path -Path (Split-Path -Path $RootPath -Qualifier) -ChildPath 'Resources';
}

Write-Host ("Deploying resources..") -ForegroundColor Cyan;
foreach ($resourceId in $nodeData.Resource) {

    $resource = $ConfigurationData.NonNodeData.Lability.Resource | Where-Object Id -eq $ResourceId;
    if ($resource.DestinationPath) {
        Write-Host " Copying '$resourceId'... " -ForegroundColor Gray -NoNewline;

        $destinationPath = Join-Path -Path $env:SystemDrive -ChildPath $resource.DestinationPath;
        $sourcePath = Join-Path -Path $resourcePath -ChildPath $resourceId;
        if ($resource.IsLocal) {

            $sourcePath = Join-Path -Path $ResourcePath -ChildPath ($resource.Filename).TrimStart('.');
        }

        if ($PSCmdlet.ShouldProcess("$destinationPath\$resourceId", 'Copy Resource')) {

            if ($resource.DestinationPath -and ($resource.DestinationPath -ne '\')) {
                ## We can't create a drive rooted path
                [ref] $null = New-Item -Path $destinationPath -ItemType Directory -Force -Confirm:$false;
            }

            ## Copy files
            if ($resource.Expand) {

                Get-ChildItem -Path $sourcePath |
                    Copy-Item -Destination $destinationPath -Recurse -Force -Verbose:$false -Confirm:$false;

                ## Remove read-only flags
                Get-ChildItem -Path "$destinationPath" -Recurse |
                    Where-Object { $_ -is [System.IO.FileInfo] } |
                        ForEach-Object {
                            Set-ItemProperty -Path $_.FullName -Name IsReadOnly -Value $false -Verbose:$false;
                        }
            }
            else {

                Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force -Confirm:$false;

                ## Remove read-only flags
                Get-ChildItem -Path "$destinationPath\$resourceId" -Recurse |
                    Where-Object { $_ -is [System.IO.FileInfo] } |
                        ForEach-Object {
                            Set-ItemProperty -Path $_.FullName -Name IsReadOnly -Value $false -Verbose:$false;
                        }
            }
        } #end if should process

        Write-Host 'OK!' -ForegroundColor Green;
    } #end if destination path

} #end resources

Write-Host ("Configurating LCM.. ") -ForegroundColor Cyan -NoNewline;
$sourceMetaMofPath = Join-Path -Path $RootPath -ChildPath "Configurations\$NodeName.meta.mof";
if ($PSCmdlet.ShouldProcess($sourceMetaMofPath, 'Configure LCM')) {

    $tempPath = Join-Path -Path $env:SystemRoot -ChildPath 'Temp';
    $localhostMetaMofPath = Join-Path -Path $tempPath -ChildPath 'localhost.meta.mof';
    Copy-Item -Path $sourceMetaMofPath -Destination $localhostMetaMofPath -Confirm:$false -Verbose:$false -Force;
    Set-DscLocalConfigurationManager -Path $tempPath -ErrorAction Stop;
    Write-Host 'OK!' -ForegroundColor Green;

} #end LCM

## Copy .mof into C:\Windows\Temp to permit updating/massaging
$sourceMofPath = Join-Path -Path $RootPath -ChildPath "Configurations\$NodeName.mof";
$tempPath = Join-Path -Path $env:SystemRoot -ChildPath 'Temp';
$localhostMofPath = Join-Path -Path $tempPath -ChildPath 'localhost.mof';

$mofContent = Get-Content -Path $sourceMofPath;
if ($PSVersionTable.PSVersion.Major -eq 4) {

    ## Convert the .mof to v4 compatible - credit to Mike Robbins
    ## http://mikefrobbins.com/2014/10/30/powershell-desired-state-configuration-error-undefined-property-configurationname/
    $mofContent = $mofContent -replace '^\sName=.*;$|^\sConfigurationName\s=.*;$';
}

## Locate the first enabled NIC interface alias
$interfaceAlias = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter 'NetConnectionStatus = "2"' |
    Select-Object -First 1 -ExpandProperty NetConnectionId;
$mofContent = $mofContent -replace 'Ethernet', $interfaceAlias;
$mofContent = $mofContent -replace 'Local Area Connection', $interfaceAlias;

## Replace 'Path = "C:\\Resources\\" references with "BootstrapDrive:\\Resources" reference
$resourceReplacement = ('{0}\' -f $ResourcePath).Replace('\','\\');
$mofContent = $mofContent -replace 'C:\\\\Resources\\\\', $resourceReplacement;

## Replace '$ResourcePath = 'C:\\Resources'' references with "BootstrapDrive:\\Resources" reference
$resourceReplacement = ('{0}' -f $ResourcePath).Replace('\','\\');
$mofContent = $mofContent -replace "\`$ResourcePath\s?=\s?'C:\\\\Resources'", "`$ResourcePath ='$resourceReplacement'";

## Write the %TEMP%\localhost.mof file
$mofContent | Set-Content -Path $localhostMofPath -Encoding Unicode -Force -Confirm:$false;

if (-not $PrepareOnly) {

    Write-Host ("Starting Configuration...") -ForegroundColor Green;
    if ($PSCmdlet.ShouldProcess($sourceMofPath, 'Start Configuration')) {

        Start-DscConfiguration -Path $tempPath -Wait -Verbose -Force -ErrorAction Stop;

    } #end configuration
} #end if not prepare only
