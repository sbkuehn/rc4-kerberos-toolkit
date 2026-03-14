<#
.SYNOPSIS
Sets supported Kerberos encryption types for a managed service account or user account.

.DESCRIPTION
Updates msDS-SupportedEncryptionTypes for an Active Directory account and returns a
verification summary. Intended for controlled remediation of RC4 exposure.

.PARAMETER Identity
The account identity to update.

.PARAMETER AccountType
The account type. Valid values are ServiceAccount and User.

.PARAMETER EncryptionType
The desired encryption profile. Valid values are AESOnly, RC4AndAES, and RC4Only.

.EXAMPLE
.\Set-KerberosAccountEncryptionTypes.ps1 -Identity provAgentgMSA -AccountType ServiceAccount -EncryptionType AESOnly

.EXAMPLE
.\Set-KerberosAccountEncryptionTypes.ps1 -Identity svc_sqlapp -AccountType User -EncryptionType AESOnly -WhatIf

.NOTES
Author: Shannon Eldridge-Kuehn
Date: 2026-03-13
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Identity,

    [Parameter(Mandatory = $true)]
    [ValidateSet('ServiceAccount', 'User')]
    [string]$AccountType,

    [Parameter(Mandatory = $true)]
    [ValidateSet('AESOnly', 'RC4AndAES', 'RC4Only')]
    [string]$EncryptionType
)

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\module\KerberosRc4Toolkit.psm1'
Import-Module $modulePath -Force -ErrorAction Stop

$invokeParams = @{
    Identity       = $Identity
    AccountType    = $AccountType
    EncryptionType = $EncryptionType
}

if ($WhatIfPreference) {
    $invokeParams['WhatIf'] = $true
}

Set-KerberosAccountEncryptionTypes @invokeParams
