# Example Usage

## Import the module

```powershell
Import-Module .\module\KerberosRc4Toolkit.psm1 -Force
```

## Find managed service accounts that should be reviewed

```powershell
Get-RC4RiskyManagedServiceAccount
```

## Find risky traditional service accounts

```powershell
Get-RC4RiskyServiceAccount
```

## Decode one account

```powershell
Get-KerberosEncryptionSummary -Identity provAgentgMSA -AccountType ServiceAccount
```

## Set AES only

```powershell
Set-KerberosAccountEncryptionTypes -Identity provAgentgMSA -AccountType ServiceAccount -EncryptionType AESOnly -Verbose
```
```
