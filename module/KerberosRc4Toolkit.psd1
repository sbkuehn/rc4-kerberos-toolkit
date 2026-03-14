@{
    RootModule           = 'KerberosRc4Toolkit.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '98a8d359-0fd9-4a58-a5e0-a1431f245d8f'
    Author               = 'Shannon Eldridge-Kuehn'
    CompanyName          = 'Personal / Community'
    Copyright            = '(c) 2026 Shannon Eldridge-Kuehn. All rights reserved.'
    Description          = 'PowerShell toolkit for discovering and remediating RC4-related Kerberos encryption risk in Active Directory service accounts.'
    PowerShellVersion    = '5.1'
    FunctionsToExport    = @(
        'Convert-EncryptionTypeValue',
        'Get-RC4RiskyManagedServiceAccount',
        'Get-RC4RiskyServiceAccount',
        'Get-KerberosEncryptionSummary',
        'Set-KerberosAccountEncryptionTypes'
    )
    CmdletsToExport      = @()
    VariablesToExport    = '*'
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('ActiveDirectory', 'Kerberos', 'RC4', 'Security', 'PowerShell')
            ProjectUri   = 'https://github.com/'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = 'Initial release.'
        }
    }
}
