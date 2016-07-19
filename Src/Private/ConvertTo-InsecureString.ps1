function ConvertTo-InsecureString {
<#
    .SYNOPSIS
        Converts a secure string to an unsecured string.
#>
    [CmdletBinding()]
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
} #end function ConvertTo-InsecureString
