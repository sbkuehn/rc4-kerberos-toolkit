# RC4 Kerberos Toolkit

Production-ready PowerShell tooling to help identify, review, and remediate Kerberos RC4 risk in Active Directory.

Author: Shannon Eldridge-Kuehn  
Date: 2026-03-13

## What this repo does

This repository gives you a practical way to:

- find managed service accounts with null or weak Kerberos encryption settings
- find traditional user-based service accounts with SPNs that may still permit RC4 or rely on defaults
- decode `msDS-SupportedEncryptionTypes` into something human-readable
- set supported encryption types explicitly to AES128 + AES256 when appropriate
- export results for remediation tracking

This repo was built to account for a few real-world gotchas:

- `Get-ADServiceAccount` uses `PasswordLastSet`, not `LastPasswordSet`
- `msDS-SupportedEncryptionTypes` contains a hyphen and must be quoted in expressions
- null encryption settings matter and should be treated as review items
- changing the attribute alone is not the whole story because password rotation, ticket refresh, and service restarts still matter

## Repository structure

```text
rc4-kerberos-toolkit/
├── module/
│   ├── KerberosRc4Toolkit.psm1
│   └── KerberosRc4Toolkit.psd1
├── scripts/
│   ├── Get-RC4RiskyManagedServiceAccounts.ps1
│   ├── Get-RC4RiskyServiceAccounts.ps1
│   ├── Get-KerberosEncryptionSummary.ps1
│   └── Set-KerberosAccountEncryptionTypes.ps1
├── examples/
│   └── example-usage.md
├── LICENSE
├── .gitignore
└── README.md
```

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Active Directory PowerShell module
- rights to query Active Directory
- rights to modify account attributes if you plan to run remediation commands

## Install and import

Clone the repo and import the module:

```powershell
Import-Module .\module\KerberosRc4Toolkit.psm1 -Force
```

## Scripts

### 1. Find risky managed service accounts

```powershell
.\scripts\Get-RC4RiskyManagedServiceAccounts.ps1
```

Export to CSV:

```powershell
.\scripts\Get-RC4RiskyManagedServiceAccounts.ps1 -ExportCsv .\managed-service-accounts.csv
```

### 2. Find risky traditional service accounts

```powershell
.\scripts\Get-RC4RiskyServiceAccounts.ps1
```

Export to CSV:

```powershell
.\scripts\Get-RC4RiskyServiceAccounts.ps1 -ExportCsv .\service-accounts.csv
```

### 3. Summarize encryption types for a specific account

Managed service account:

```powershell
.\scripts\Get-KerberosEncryptionSummary.ps1 -Identity provAgentgMSA -AccountType ServiceAccount
```

Traditional service account:

```powershell
.\scripts\Get-KerberosEncryptionSummary.ps1 -Identity svc_sqlapp -AccountType User
```

### 4. Explicitly set AES128 + AES256

Managed service account:

```powershell
.\scripts\Set-KerberosAccountEncryptionTypes.ps1 -Identity provAgentgMSA -AccountType ServiceAccount -EncryptionType AESOnly
```

Traditional service account:

```powershell
.\scripts\Set-KerberosAccountEncryptionTypes.ps1 -Identity svc_sqlapp -AccountType User -EncryptionType AESOnly
```

## What the values mean

`msDS-SupportedEncryptionTypes` is a bitmask.

- `4` = RC4
- `8` = AES128
- `16` = AES256
- `24` = AES128 + AES256

This toolkit treats these as the main operational values for service account review. If you see null, that means the attribute is not explicitly set and the account should be reviewed.

## Recommended workflow

1. Run the discovery scripts and export the results.
2. Review dependencies with application and infrastructure owners.
3. Rotate passwords where appropriate so AES keys exist.
4. Set the encryption types explicitly when the application supports AES.
5. Restart services or systems if needed so fresh Kerberos tickets are requested.
6. Monitor Kerberos ticket activity and authentication failures during rollout.

## Operational notes

- Setting `msDS-SupportedEncryptionTypes` to `24` does not magically fix stale tickets already in memory.
- Password age matters. AES keys are generated when passwords are set or rotated.
- Legacy appliances, keytabs, and older libraries may still require remediation beyond a simple AD attribute update.
- Always test critical workloads before broad rollout.

## License

MIT. See [LICENSE](LICENSE).
