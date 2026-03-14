Set-StrictMode -Version Latest

function Convert-EncryptionTypeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Nullable[int]]$Value
    )

    if ($null -eq $Value) {
        return [PSCustomObject]@{
            RawValue      = $null
            DisplayValue  = 'DEFAULT / NOT SET'
            HasRC4        = $false
            HasAES128     = $false
            HasAES256     = $false
            ReviewNeeded  = $true
        }
    }

    $types = [System.Collections.Generic.List[string]]::new()
    $hasRC4 = ($Value -band 4) -ne 0
    $hasAES128 = ($Value -band 8) -ne 0
    $hasAES256 = ($Value -band 16) -ne 0

    if ($hasRC4) { [void]$types.Add('RC4') }
    if ($hasAES128) { [void]$types.Add('AES128') }
    if ($hasAES256) { [void]$types.Add('AES256') }

    $displayValue = if ($types.Count -eq 0) { "Unknown ($Value)" } else { "$Value : $($types -join ', ')" }
    $reviewNeeded = $hasRC4 -or (-not $hasAES128 -and -not $hasAES256) -or $types.Count -eq 0

    return [PSCustomObject]@{
        RawValue      = $Value
        DisplayValue  = $displayValue
        HasRC4        = $hasRC4
        HasAES128     = $hasAES128
        HasAES256     = $hasAES256
        ReviewNeeded  = $reviewNeeded
    }
}

function Get-RC4RiskyManagedServiceAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ExportCsv
    )

    Import-Module ActiveDirectory -ErrorAction Stop

    $results = Get-ADServiceAccount -Filter * -Properties 'msDS-SupportedEncryptionTypes', 'PasswordLastSet' -ErrorAction Stop |
        ForEach-Object {
            $decoded = Convert-EncryptionTypeValue -Value $_.'msDS-SupportedEncryptionTypes'
            [PSCustomObject]@{
                Name                      = $_.Name
                DistinguishedName         = $_.DistinguishedName
                PasswordLastSet           = $_.PasswordLastSet
                EncryptionTypeRawValue    = $decoded.RawValue
                EncryptionTypes           = $decoded.DisplayValue
                HasRC4                    = $decoded.HasRC4
                HasAES128                 = $decoded.HasAES128
                HasAES256                 = $decoded.HasAES256
                ReviewNeeded              = $decoded.ReviewNeeded
                AccountType               = 'ManagedServiceAccount'
            }
        } |
        Where-Object { $_.ReviewNeeded }

    if ($ExportCsv) {
        $results | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    }

    return $results
}

function Get-RC4RiskyServiceAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ExportCsv
    )

    Import-Module ActiveDirectory -ErrorAction Stop

    $results = Get-ADUser -LDAPFilter '(servicePrincipalName=*)' -Properties 'servicePrincipalName', 'msDS-SupportedEncryptionTypes', 'PasswordLastSet' -ErrorAction Stop |
        ForEach-Object {
            $decoded = Convert-EncryptionTypeValue -Value $_.'msDS-SupportedEncryptionTypes'
            [PSCustomObject]@{
                Name                      = $_.Name
                SamAccountName            = $_.SamAccountName
                DistinguishedName         = $_.DistinguishedName
                PasswordLastSet           = $_.PasswordLastSet
                ServicePrincipalNames     = ($_.ServicePrincipalName -join '; ')
                EncryptionTypeRawValue    = $decoded.RawValue
                EncryptionTypes           = $decoded.DisplayValue
                HasRC4                    = $decoded.HasRC4
                HasAES128                 = $decoded.HasAES128
                HasAES256                 = $decoded.HasAES256
                ReviewNeeded              = $decoded.ReviewNeeded
                AccountType               = 'User'
            }
        } |
        Where-Object { $_.ReviewNeeded }

    if ($ExportCsv) {
        $results | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    }

    return $results
}

function Get-KerberosEncryptionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ServiceAccount', 'User')]
        [string]$AccountType
    )

    Import-Module ActiveDirectory -ErrorAction Stop

    $account = switch ($AccountType) {
        'ServiceAccount' {
            Get-ADServiceAccount -Identity $Identity -Properties 'msDS-SupportedEncryptionTypes', 'PasswordLastSet' -ErrorAction Stop
        }
        'User' {
            Get-ADUser -Identity $Identity -Properties 'msDS-SupportedEncryptionTypes', 'PasswordLastSet', 'servicePrincipalName' -ErrorAction Stop
        }
    }

    $decoded = Convert-EncryptionTypeValue -Value $account.'msDS-SupportedEncryptionTypes'

    [PSCustomObject]@{
        Name                   = $account.Name
        Identity               = $Identity
        AccountType            = $AccountType
        DistinguishedName      = $account.DistinguishedName
        PasswordLastSet        = $account.PasswordLastSet
        ServicePrincipalNames  = if ($AccountType -eq 'User') { ($account.ServicePrincipalName -join '; ') } else { $null }
        EncryptionTypeRawValue = $decoded.RawValue
        EncryptionTypes        = $decoded.DisplayValue
        HasRC4                 = $decoded.HasRC4
        HasAES128              = $decoded.HasAES128
        HasAES256              = $decoded.HasAES256
        ReviewNeeded           = $decoded.ReviewNeeded
    }
}

function Set-KerberosAccountEncryptionTypes {
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

    Import-Module ActiveDirectory -ErrorAction Stop

    $value = switch ($EncryptionType) {
        'AESOnly'   { 24 }
        'RC4AndAES' { 28 }
        'RC4Only'   { 4 }
    }

    if ($PSCmdlet.ShouldProcess($Identity, "Set msDS-SupportedEncryptionTypes to $value ($EncryptionType)")) {
        switch ($AccountType) {
            'ServiceAccount' {
                Set-ADServiceAccount -Identity $Identity -Replace @{ 'msDS-SupportedEncryptionTypes' = $value } -ErrorAction Stop
            }
            'User' {
                Set-ADUser -Identity $Identity -Replace @{ 'msDS-SupportedEncryptionTypes' = $value } -ErrorAction Stop
            }
        }
    }

    Get-KerberosEncryptionSummary -Identity $Identity -AccountType $AccountType
}

Export-ModuleMember -Function `
    Convert-EncryptionTypeValue, `
    Get-RC4RiskyManagedServiceAccount, `
    Get-RC4RiskyServiceAccount, `
    Get-KerberosEncryptionSummary, `
    Set-KerberosAccountEncryptionTypes
