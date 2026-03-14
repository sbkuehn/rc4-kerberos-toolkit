<#
.SYNOPSIS
Finds managed service accounts that should be reviewed for RC4-related Kerberos risk.

.DESCRIPTION
Queries Active Directory managed service accounts and returns accounts where
msDS-SupportedEncryptionTypes is not explicitly set, contains RC4, or cannot be
reliably decoded as AES-capable.

.PARAMETER ExportCsv
Optional path to export the result set to CSV.

.EXAMPLE
.\Get-RC4RiskyManagedServiceAccounts.ps1

.EXAMPLE
.\Get-RC4RiskyManagedServiceAccounts.ps1 -ExportCsv .\gmsa-review.csv

.NOTES
Author: Shannon Eldridge-Kuehn
Date: 2026-03-13
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ExportCsv
)

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\module\KerberosRc4Toolkit.psm1'
Import-Module $modulePath -Force -ErrorAction Stop

Get-RC4RiskyManagedServiceAccount -ExportCsv $ExportCsv
