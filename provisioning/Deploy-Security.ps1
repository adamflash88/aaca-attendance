<#
.SYNOPSIS
    Creates AACA security: a business unit per campus, the four AACA security roles with their
    exact privileges, and the column-security profiles for absence classification. Re-runnable:
    role privileges are replaced with the matrix below on every run.

.DESCRIPTION
    Run after Deploy-Schema.ps1. Business units are created for each active Campus row, so re-run
    after adding a campus. Depth: Basic = records the user owns, Local = the user's business unit
    (campus), Global = everything.

    Users also need the built-in "Basic User" role (core tables used by any app). Assign users
    with Grant-AacaAccess.ps1.

.EXAMPLE
    ./Deploy-Security.ps1 -EnvironmentUrl https://org12345.crm.dynamics.com
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
$schema = Get-Content (Join-Path $PSScriptRoot '..\schema\tables.json') -Raw | ConvertFrom-Json
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode -SolutionUniqueName $schema.solution.uniqueName

#region Role matrix ---------------------------------------------------------------------
$reference = 'aaca_campus', 'aaca_staff', 'aaca_service', 'aaca_schoolyear', 'aaca_term',
             'aaca_calendarexception', 'aaca_absencereason', 'aaca_monthlock', 'aaca_setting'
$allTables = @($schema.tables.logicalName)
$allAccess = 'Create', 'Read', 'Write', 'Delete', 'Append', 'AppendTo', 'Assign', 'Share'

function Grant([hashtable] $m, [string[]] $tables, [string[]] $access, [string] $depth) {
    foreach ($t in $tables) { if (-not $m.Contains($t)) { $m[$t] = @{} }; foreach ($a in $access) { $m[$t][$a] = $depth } }
}

$roles = [ordered]@{}

# Teacher: own students/enrollments/attendance only. No delete anywhere (soft delete only).
$m = @{}
Grant $m $reference 'Read', 'AppendTo' 'Global'
Grant $m 'aaca_student', 'aaca_enrollment' 'Read', 'AppendTo' 'Basic'
Grant $m 'aaca_attendance' 'Create', 'Read', 'Write', 'Append' 'Basic'
Grant $m 'aaca_auditevent' 'Create', 'Read' 'Basic'
$roles['AACA Teacher'] = @{ Description = 'Records attendance for own students only.'; Matrix = $m }

# Attendance Office: everything for their campus; classifies absences (with the Classifiers profile).
$m = @{}
Grant $m $reference 'Read', 'AppendTo' 'Global'
Grant $m 'aaca_student', 'aaca_enrollment' 'Create', 'Read', 'Write', 'Append', 'AppendTo', 'Assign' 'Local'
Grant $m 'aaca_attendance' 'Create', 'Read', 'Write', 'Append', 'Assign' 'Local'
Grant $m 'aaca_calendarexception', 'aaca_monthlock' 'Create', 'Write', 'Append' 'Local'
Grant $m 'aaca_absencereason' 'Create', 'Write' 'Global'
Grant $m 'aaca_auditevent' 'Create', 'Read' 'Local'
$roles['AACA Attendance Office'] = @{ Description = 'Campus office: students, assignments, ratios, absence classification, month locks.'; Matrix = $m }

# Read-only / billing / executive.
$m = @{}
Grant $m $allTables 'Read' 'Global'
$roles['AACA Read-only'] = @{ Description = 'Read-only across all campuses for reporting and exports.'; Matrix = $m }

# App system admin (reference data, settings, overrides). Environment admins already have System Administrator.
$m = @{}
Grant $m $allTables $allAccess 'Global'
$roles['AACA System Admin'] = @{ Description = 'Full access to AACA tables, including reference data and settings.'; Matrix = $m }
#endregion

#region Business units ------------------------------------------------------------------
$rootBu = (Invoke-Dv -Path 'businessunits?$select=businessunitid,name&$filter=_parentbusinessunitid_value eq null').value[0]
Write-Host "Root business unit: $($rootBu.name)"

$campuses = (Invoke-Dv -Path "$(Get-DvEntitySet 'aaca_campus')?`$select=aaca_name&`$filter=aaca_active eq true").value
if (-not $campuses) { Write-Warning 'No active Campus rows yet: business units will be created when you re-run after adding campuses.' }
foreach ($c in $campuses) {
    $name = $c.aaca_name
    $escaped = $name.Replace("'", "''")
    $bu = (Invoke-Dv -Path "businessunits?`$select=businessunitid&`$filter=name eq '$escaped'").value | Select-Object -First 1
    if (-not $bu) {
        Invoke-Dv -Method Post -Path 'businessunits' -Body @{ name = $name; 'parentbusinessunitid@odata.bind' = "/businessunits($($rootBu.businessunitid))" } | Out-Null
        Write-Host "Created business unit $name" -ForegroundColor Green
    }
}
#endregion

#region Roles ---------------------------------------------------------------------------
$privs = @{}
$page = Invoke-Dv -Path "privileges?`$select=privilegeid,name&`$filter=contains(name,'aaca_')"
foreach ($p in $page.value) { $privs[$p.name.ToLowerInvariant()] = $p.privilegeid }
if (-not $privs.Count) { throw 'No aaca_ privileges found. Run Deploy-Schema.ps1 first.' }

foreach ($roleName in $roles.Keys) {
    $def = $roles[$roleName]
    $role = (Invoke-Dv -Path "roles?`$select=roleid&`$filter=name eq '$roleName' and _businessunitid_value eq $($rootBu.businessunitid)").value | Select-Object -First 1
    if (-not $role) {
        $role = New-DvRow 'roles' @{ name = $roleName; description = $def.Description; 'businessunitid@odata.bind' = "/businessunits($($rootBu.businessunitid))" }
        Add-DvSolutionComponent $role.roleid 20
        Write-Host "Created role $roleName" -ForegroundColor Green
    }

    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($table in $def.Matrix.Keys) {
        foreach ($access in $def.Matrix[$table].Keys) {
            $privName = "prv$access$table".ToLowerInvariant()
            if (-not $privs.Contains($privName)) { throw "Privilege $privName not found (is $table deployed?)" }
            $list.Add(@{ PrivilegeId = $privs[$privName]; Depth = $def.Matrix[$table][$access]; BusinessUnitId = $rootBu.businessunitid })
        }
    }
    Invoke-Dv -Method Post -Path "roles($($role.roleid))/Microsoft.Dynamics.CRM.ReplacePrivilegesRole" -Body @{ Privileges = $list } | Out-Null
    Write-Host "  $roleName : $($list.Count) privileges set"
}
#endregion

#region Column security -----------------------------------------------------------------
$secured = @()
foreach ($t in $schema.tables) {
    foreach ($c in $t.columns) { if ($c.PSObject.Properties['secured'] -and $c.secured) { $secured += [pscustomobject]@{ table = $t.logicalName; column = $c.logicalName } } }
}
foreach ($l in $schema.lookups) { if ($l.PSObject.Properties['secured'] -and $l.secured) { $secured += [pscustomobject]@{ table = $l.table; column = $l.logicalName } } }

# 4 = Allowed, 0 = Not allowed
$profiles = [ordered]@{
    'AACA Absence Classifiers' = @{ Description = 'Office staff and admins: read and set absence classification and reason.'; Read = 4; Create = 4; Update = 4 }
    'AACA Absence Viewers'     = @{ Description = 'Teachers and read-only users: see classification, cannot change it.'; Read = 4; Create = 0; Update = 0 }
}
foreach ($pName in $profiles.Keys) {
    $p = $profiles[$pName]
    $fsp = (Invoke-Dv -Path "fieldsecurityprofiles?`$select=fieldsecurityprofileid&`$filter=name eq '$pName'").value | Select-Object -First 1
    if (-not $fsp) {
        $fsp = New-DvRow 'fieldsecurityprofiles' @{ name = $pName; description = $p.Description }
        Add-DvSolutionComponent $fsp.fieldsecurityprofileid 70
        Write-Host "Created column security profile $pName" -ForegroundColor Green
    }
    $existing = (Invoke-Dv -Path "fieldpermissions?`$select=fieldpermissionid,entityname,attributelogicalname&`$filter=_fieldsecurityprofileid_value eq $($fsp.fieldsecurityprofileid)").value
    foreach ($s in $secured) {
        $body = @{ canread = $p.Read; cancreate = $p.Create; canupdate = $p.Update }
        $match = $existing | Where-Object { $_.entityname -eq $s.table -and $_.attributelogicalname -eq $s.column } | Select-Object -First 1
        if ($match) {
            Invoke-Dv -Method Patch -Path "fieldpermissions($($match.fieldpermissionid))" -Body $body | Out-Null
        } else {
            $body.entityname = $s.table; $body.attributelogicalname = $s.column
            $body['fieldsecurityprofileid@odata.bind'] = "/fieldsecurityprofiles($($fsp.fieldsecurityprofileid))"
            Invoke-Dv -Method Post -Path 'fieldpermissions' -Body $body | Out-Null
        }
    }
    Write-Host "  $pName : $($secured.Count) secured columns"
}
#endregion

Write-Host "`nSecurity deployed. Next: Grant-AacaAccess.ps1 to put users in a campus and role." -ForegroundColor Green
