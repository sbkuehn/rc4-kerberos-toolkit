<#
.SYNOPSIS
Summarizes Kerberos encryption settings for one Active Directory account.

.DESCRIPTION
Looks up a managed service account or traditional AD user account and returns a
human-readable summary of msDS-SupportedEncryptionTypes.

.PARAMETER Identity
The account identity to query.

.PARAMETER AccountType
The account type. Valid values are ServiceAccount and User.

.EXAMPLE
.\Get-KerberosEncryptionSummary.ps1 -Identity provAgentgMSA -AccountType ServiceAccount

.EXAMPLE
.\Get-KerberosEncryptionSummary.ps1 -Identity svc_sqlapp -AccountType User

.NOTES
Author: Shannon Eldridge-Kuehn
Date: 2026-03-13
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Identity,

    [Parameter(Mandatory = $true)]
    [ValidateSet('ServiceAccount', 'User')]
    [string]$AccountType
)

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\module\KerberosRc4Toolkit.psm1'
Import-Module $modulePath -Force -ErrorAction Stop

Get-KerberosEncryptionSummary -Identity $Identity -AccountType $AccountType
