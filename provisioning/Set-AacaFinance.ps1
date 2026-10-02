<#
.SYNOPSIS
    Gives (or with -Remove, takes away) Finance access: the AACA Finance security role, which alone can read billing
    tables, plus the Staff "Finance Access" flag that shows the Billing app. It is an add-on to the person's app role
    (Grant-AacaAccess.ps1), so run that first: the person needs a Staff row.

.EXAMPLE
    ./Set-AacaFinance.ps1 -EnvironmentUrl https://org.crm.dynamics.com -UserEmail cpalmieri@autismacademy.org
    ./Set-AacaFinance.ps1 -EnvironmentUrl https://org.crm.dynamics.com -UserEmail someone@autismacademy.org -Remove
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $UserEmail,
    [switch] $Remove,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode

$email = $UserEmail.Replace("'", "''")
$user = (Invoke-Dv -Path "systemusers?`$select=systemuserid,fullname,_businessunitid_value&`$filter=internalemailaddress eq '$email' or domainname eq '$email'").value | Select-Object -First 1
if (-not $user) { throw "$UserEmail is not a user in this environment." }
$userId = $user.systemuserid
$staffSet = Get-DvEntitySet 'aaca_staff'
$staff = (Invoke-Dv -Path "${staffSet}?`$select=aaca_staffid&`$filter=_aaca_user_value eq $userId").value | Select-Object -First 1
if (-not $staff) { throw "$($user.fullname) has no Staff row. Run Grant-AacaAccess.ps1 first." }

# Role copies exist per business unit: use the one in the user's business unit.
$role = (Invoke-Dv -Path "roles?`$select=roleid&`$filter=name eq 'AACA Finance' and _businessunitid_value eq $($user._businessunitid_value)").value | Select-Object -First 1
if (-not $role) { throw "Role 'AACA Finance' not found. Run Deploy-Security.ps1." }
$has = @((Invoke-Dv -Path "systemusers($userId)/systemuserroles_association?`$select=roleid&`$filter=roleid eq $($role.roleid)").value).Count -gt 0

if ($Remove) {
    if ($has) { Invoke-Dv -Method Delete -Path "systemusers($userId)/systemuserroles_association($($role.roleid))/`$ref" | Out-Null }
    Invoke-Dv -Method Patch -Path "$staffSet($($staff.aaca_staffid))" -Body @{ aaca_financeaccess = $false } | Out-Null
    Write-Host "$($user.fullname): Finance access removed." -ForegroundColor Green
} else {
    if (-not $has) { Invoke-Dv -Method Post -Path "systemusers($userId)/systemuserroles_association/`$ref" -Body @{ '@odata.id' = "$script:DvApi/roles($($role.roleid))" } | Out-Null }
    Invoke-Dv -Method Patch -Path "$staffSet($($staff.aaca_staffid))" -Body @{ aaca_financeaccess = $true } | Out-Null
    Write-Host "$($user.fullname): Finance access granted." -ForegroundColor Green
}
