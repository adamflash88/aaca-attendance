<#
.SYNOPSIS
    Gives a user access to the AACA Attendance app: moves them into their campus business unit,
    assigns exactly one AACA security role (+ Basic User), the matching column-security profile,
    and creates/updates their Staff row.

.DESCRIPTION
    The user must already be a user in the environment (Power Platform admin center >
    environment > Users > Add user).

    Moving a user to another business unit removes ALL their security roles (Dataverse
    behaviour); this script re-adds Basic User and the AACA role afterwards. It refuses to move a
    System Administrator unless -Force is given, so an environment admin can't lock themselves out.

.EXAMPLE
    ./Grant-AacaAccess.ps1 -EnvironmentUrl https://org.crm.dynamics.com -UserEmail jane@autismacademy.org -Role Teacher -Campus 'North Campus'
    ./Grant-AacaAccess.ps1 -EnvironmentUrl https://org.crm.dynamics.com -UserEmail boss@autismacademy.org -Role ReadOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $UserEmail,
    [Parameter(Mandatory)] [ValidateSet('Teacher', 'AttendanceOffice', 'ReadOnly', 'SystemAdmin')] [string] $Role,
    # Campus name (required for Teacher and AttendanceOffice; they live in that campus's business unit).
    [string] $Campus,
    [string] $AccessToken,
    [switch] $UseDeviceCode,
    [switch] $Force
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode

$roleNames = @{ Teacher = 'AACA Teacher'; AttendanceOffice = 'AACA Attendance Office'; ReadOnly = 'AACA Read-only'; SystemAdmin = 'AACA System Admin' }
$appRole   = @{ Teacher = 582100000; AttendanceOffice = 582100001; ReadOnly = 582100002; SystemAdmin = 582100003 }
$fsProfile   = if ($Role -in 'AttendanceOffice', 'SystemAdmin') { 'AACA Absence Classifiers' } else { 'AACA Absence Viewers' }
if ($Role -in 'Teacher', 'AttendanceOffice' -and -not $Campus) { throw "-Campus is required for $Role." }

# User
$email = $UserEmail.Replace("'", "''")
$user = (Invoke-Dv -Path "systemusers?`$select=systemuserid,fullname,firstname,lastname,_businessunitid_value&`$filter=internalemailaddress eq '$email' or domainname eq '$email'").value | Select-Object -First 1
if (-not $user) { throw "$UserEmail is not a user in this environment. Add them in the Power Platform admin center first." }
$userId = $user.systemuserid

# Target business unit and campus row
$rootBu = (Invoke-Dv -Path 'businessunits?$select=businessunitid&$filter=_parentbusinessunitid_value eq null').value[0].businessunitid
$campusRow = $null
if ($Campus) {
    $cn = $Campus.Replace("'", "''")
    $campusRow = (Invoke-Dv -Path "$(Get-DvEntitySet 'aaca_campus')?`$select=aaca_campusid&`$filter=aaca_name eq '$cn'").value | Select-Object -First 1
    if (-not $campusRow) { throw "No Campus row named '$Campus'." }
}
$targetBu = if ($Role -in 'Teacher', 'AttendanceOffice') {
    $bu = (Invoke-Dv -Path "businessunits?`$select=businessunitid&`$filter=name eq '$($Campus.Replace("'", "''"))'").value | Select-Object -First 1
    if (-not $bu) { throw "No business unit for campus '$Campus'. Re-run Deploy-Security.ps1." }
    $bu.businessunitid
} else { $rootBu }

function Get-UserRoles { @((Invoke-Dv -Path "systemusers($userId)/systemuserroles_association?`$select=roleid,name").value) }
function Names($rows) { @(foreach ($r in $rows) { $r.name }) }

if ($user._businessunitid_value -ne $targetBu) {
    if ((Names (Get-UserRoles)) -contains 'System Administrator' -and -not $Force) {
        throw "$UserEmail is a System Administrator; moving business units would remove that role. Use -Force if intended."
    }
    Invoke-Dv -Method Patch -Path "systemusers($userId)" -Body @{ 'businessunitid@odata.bind' = "/businessunits($targetBu)" } | Out-Null
    Write-Host "Moved $($user.fullname) to business unit $(if ($Campus) { $Campus } else { '(root)' })" -ForegroundColor Green
}

# Roles: exactly one AACA role, plus Basic User (role copies exist per business unit)
$current = Get-UserRoles
foreach ($r in $current | Where-Object { $_.name -like 'AACA *' -and $_.name -ne $roleNames[$Role] }) {
    Invoke-Dv -Method Delete -Path "systemusers($userId)/systemuserroles_association($($r.roleid))/`$ref" | Out-Null
    Write-Host "Removed role $($r.name)"
}
foreach ($rn in $roleNames[$Role], 'Basic User') {
    if ((Names $current) -contains $rn) { continue }
    $r = (Invoke-Dv -Path "roles?`$select=roleid&`$filter=name eq '$rn' and _businessunitid_value eq $targetBu").value | Select-Object -First 1
    if (-not $r) { throw "Role '$rn' not found in the target business unit. Run Deploy-Security.ps1." }
    Invoke-Dv -Method Post -Path "systemusers($userId)/systemuserroles_association/`$ref" -Body @{ '@odata.id' = "$script:DvApi/roles($($r.roleid))" } | Out-Null
    Write-Host "Assigned role $rn" -ForegroundColor Green
}

# Column-security profile: exactly one of the two AACA profiles
$profiles = (Invoke-Dv -Path "fieldsecurityprofiles?`$select=fieldsecurityprofileid,name&`$filter=startswith(name,'AACA ')").value
$userProfiles = @((Invoke-Dv -Path "systemusers($userId)/systemuserprofiles_association?`$select=fieldsecurityprofileid,name").value)
foreach ($p in $profiles) {
    $has = @(foreach ($up in $userProfiles) { $up.fieldsecurityprofileid }) -contains $p.fieldsecurityprofileid
    if ($p.name -eq $fsProfile -and -not $has) {
        Invoke-Dv -Method Post -Path "systemusers($userId)/systemuserprofiles_association/`$ref" -Body @{ '@odata.id' = "$script:DvApi/fieldsecurityprofiles($($p.fieldsecurityprofileid))" } | Out-Null
        Write-Host "Added column-security profile $($p.name)" -ForegroundColor Green
    } elseif ($p.name -ne $fsProfile -and $has) {
        Invoke-Dv -Method Delete -Path "systemusers($userId)/systemuserprofiles_association($($p.fieldsecurityprofileid))/`$ref" | Out-Null
        Write-Host "Removed column-security profile $($p.name)"
    }
}

# Staff row (drives the app UI)
$staffSet = Get-DvEntitySet 'aaca_staff'
$staff = (Invoke-Dv -Path "${staffSet}?`$select=aaca_staffid&`$filter=_aaca_user_value eq $userId").value | Select-Object -First 1
if (-not $staff) {
    # Imported Staff rows (which own the teacher's enrollments) are named "Last, First" and their sheet email may
    # differ from the account's; link the unlinked row with this person's name instead of creating a duplicate.
    $names = @($user.fullname, "$($user.lastname), $($user.firstname)") | Where-Object { $_ -and $_ -ne ', ' } |
        ForEach-Object { "aaca_name eq '$($_.Replace("'", "''"))'" }
    $found = @((Invoke-Dv -Path "${staffSet}?`$select=aaca_staffid,aaca_name&`$filter=_aaca_user_value eq null and ($($names -join ' or '))").value)
    if ($found.Count -gt 1) { throw "More than one unlinked Staff row named $($user.fullname); link the right one manually." }
    $staff = $found | Select-Object -First 1
    if ($staff) { Write-Host "Linking existing Staff row '$($staff.aaca_name)'" }
}
$body = @{ aaca_approle = $appRole[$Role]; aaca_active = $true; 'aaca_user@odata.bind' = "/systemusers($userId)" }
if (-not $staff) { $body.aaca_name = $user.fullname }
if ($campusRow) { $body['aaca_campus@odata.bind'] = "/$(Get-DvEntitySet 'aaca_campus')($($campusRow.aaca_campusid))" }
if ($staff) {
    Invoke-Dv -Method Patch -Path "$staffSet($($staff.aaca_staffid))" -Body $body | Out-Null
    if (-not $campusRow) { Invoke-Dv -Method Delete -Path "$staffSet($($staff.aaca_staffid))/aaca_campus/`$ref" -AllowNotFound | Out-Null }
    Write-Host "Updated Staff row for $($user.fullname)"
} else {
    Invoke-Dv -Method Post -Path $staffSet -Body $body | Out-Null
    Write-Host "Created Staff row for $($user.fullname)" -ForegroundColor Green
}
Write-Host "`n$($user.fullname): $($roleNames[$Role])$(if ($Campus) { " at $Campus" }) - done." -ForegroundColor Green
