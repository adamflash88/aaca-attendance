<#
.SYNOPSIS
    Fills Staff.Email (build 10) from the linked user account's primary email, for Staff rows that have a User but no
    Email. Rows without a linked user are listed so the office can type the email on the Staff screen. Re-runnable.

.EXAMPLE
    ./Set-StaffEmails.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [switch] $WhatIf
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl

$set = Get-DvEntitySet 'aaca_staff'
$rows = Get-DvAll "${set}?`$select=aaca_staffid,aaca_name,aaca_email,_aaca_user_value&`$expand=aaca_user(`$select=internalemailaddress)"
$filled = 0; $noUser = [System.Collections.Generic.List[string]]::new()
foreach ($r in $rows) {
    if ($r.aaca_email) { continue }
    $mail = if ($r.aaca_user) { "$($r.aaca_user.internalemailaddress)".Trim().ToLowerInvariant() } else { '' }
    if (-not $mail) { $noUser.Add($r.aaca_name); continue }
    if ($WhatIf) { Write-Host "would set $($r.aaca_name) -> $mail" }
    else { Invoke-Dv -Method Patch -Path "$set($($r.aaca_staffid))" -Body @{ aaca_email = $mail } | Out-Null }
    $filled++
}
Write-Host "Staff emails $(if ($WhatIf) { 'to fill' } else { 'filled' }): $filled of $(@($rows).Count)" -ForegroundColor Green
foreach ($n in $noUser) { Write-Host "  no linked account (add the email on the Staff screen): $n" -ForegroundColor Yellow }
