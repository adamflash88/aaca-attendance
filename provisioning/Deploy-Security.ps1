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
# Billing tables (schema "billing": true) belong to the AACA Finance role only: no other AACA role can read them.
$billingTables = @($schema.tables | Where-Object { $_.PSObject.Properties['billing'] -and $_.billing } | ForEach-Object logicalName)
$allTables = @($schema.tables.logicalName | Where-Object { $_ -notin $billingTables })
# An environment can be a solution version behind the schema (e.g. Test): only grant on tables it actually has.
$present = @{}
foreach ($p in (Invoke-Dv -Path "privileges?`$select=name&`$filter=startswith(name,'prvReadaaca_')").value) { $present[$p.name.Substring(7).ToLowerInvariant()] = $true }
$missing = @($schema.tables.logicalName | Where-Object { -not $present.Contains($_) })
if ($missing) { Write-Warning "Not in this environment yet (skipped): $($missing -join ', ')" }
$billingTables = @($billingTables | Where-Object { $present.Contains($_) })
$allTables = @($allTables | Where-Object { $present.Contains($_) })
$allAccess = 'Create', 'Read', 'Write', 'Delete', 'Append', 'AppendTo', 'Assign', 'Share'

function Grant([hashtable] $m, [string[]] $tables, [string[]] $access, [string] $depth) {
    foreach ($t in $tables) { if (-not $m.Contains($t)) { $m[$t] = @{} }; foreach ($a in $access) { $m[$t][$a] = $depth } }
}

$roles = [ordered]@{}

# Teacher (build 5 rules): READ their campus's students, enrollments and attendance (other teachers' grids are
# view-only); CREATE/WRITE only attendance rows they own (their 1s and undo). Absences (0) are created by office
# staff on approval and owned by them, so a teacher's Basic write cannot change them. No delete anywhere.
$m = @{}
Grant $m $reference 'Read', 'AppendTo' 'Global'
Grant $m 'aaca_student', 'aaca_enrollment' 'Read', 'AppendTo' 'Local'
Grant $m 'aaca_attendance' 'Read' 'Local'
Grant $m 'aaca_attendance' 'Create', 'Write', 'Append' 'Basic'
# Student profile: teachers see emergency contacts and medications for their campus (safety).
Grant $m 'aaca_emergencycontact', 'aaca_studentmedication' 'Read' 'Local'
Grant $m 'aaca_auditevent' 'Create', 'Read' 'Basic'
$roles['AACA Teacher'] = @{ Description = 'Marks students present (1) and undoes own marks; views campus attendance.'; Matrix = $m }

# Attendance Office: their campus; manages students; approves parent absence reports (creates/classifies absences,
# with the Classifiers column profile). Does not edit the grid in the app (enforced by the app; the attendance Write
# privilege is needed to create and classify absences on approval).
$m = @{}
Grant $m $reference 'Read', 'AppendTo' 'Global'
Grant $m 'aaca_student', 'aaca_enrollment' 'Create', 'Read', 'Write', 'Append', 'AppendTo', 'Assign' 'Local'
Grant $m 'aaca_attendance' 'Create', 'Read', 'Write', 'Append', 'Assign' 'Local'
Grant $m 'aaca_calendarexception', 'aaca_monthlock' 'Create', 'Write', 'Append' 'Local'
Grant $m 'aaca_absencereason' 'Create', 'Write' 'Global'
Grant $m 'aaca_reportdecision' 'Create', 'Read', 'Append' 'Local'
# Family portal: process their campus's absence notices (parents create them through the portal) and see who the
# guardians are. Guardian onboarding (creating links) is a later phase.
Grant $m 'aaca_absencenotice' 'Read', 'Write', 'Append' 'Local'
Grant $m 'aaca_guardianlink' 'Read' 'Local'
# Student profile (AACA Student Records app): office maintains emergency contacts and medications.
Grant $m 'aaca_emergencycontact', 'aaca_studentmedication' 'Create', 'Read', 'Write', 'Delete', 'Append', 'Assign' 'Local'
Grant $m 'aaca_auditevent' 'Create', 'Read' 'Local'
$roles['AACA Attendance Office'] = @{ Description = 'Campus office: students, assignments, ratios, parent-report approval and absence classification, month locks.'; Matrix = $m }

# Read-only / billing / executive.
$m = @{}
Grant $m $allTables 'Read' 'Global'
$roles['AACA Read-only'] = @{ Description = 'Read-only across all campuses for reporting and exports.'; Matrix = $m }

# App system admin (reference data, settings, overrides). Environment admins already have System Administrator.
$m = @{}
Grant $m $allTables $allAccess 'Global'
$roles['AACA System Admin'] = @{ Description = 'Full access to AACA tables, including reference data and settings (not billing).'; Matrix = $m }

# Finance (billing): an ADD-ON role given alongside a person's app role (Set-AacaFinance.ps1). Full access to billing
# tables; maintains service billing fields (QuickBooks item, unit); reads students, attendance and calendars org-wide.
$m = @{}
Grant $m $billingTables $allAccess 'Global'
Grant $m ($allTables | Where-Object { $_ -ne 'aaca_auditevent' }) 'Read', 'AppendTo' 'Global'
Grant $m 'aaca_service' 'Write' 'Global'
Grant $m 'aaca_auditevent' 'Create', 'Read' 'Global'
$roles['AACA Finance'] = @{ Description = 'Billing: CodeMetro uploads, mappings, RDS grids, month close, QuickBooks export and RDS PDFs.'; Matrix = $m }

# Campus record owner: given only to each campus business unit's default team, which owns that campus's students,
# enrollments and attendance (Set-CampusOwnership.ps1). Dataverse requires an owning team to be able to read what it
# owns; Basic depth = only the team's own records, which campus staff can already read at Local depth.
$m = @{}
Grant $m 'aaca_student', 'aaca_enrollment', 'aaca_attendance' 'Read', 'AppendTo' 'Basic'
Grant $m 'aaca_student', 'aaca_enrollment', 'aaca_attendance' 'Append' 'Basic'
# Absence report intake flow gives each processed/error report record to the campus team.
Grant $m 'aaca_reportdecision' 'Read', 'Append' 'Basic'
Grant $m 'aaca_guardianlink', 'aaca_absencenotice', 'aaca_emergencycontact', 'aaca_studentmedication' 'Read', 'Append' 'Basic'
Grant $m $reference 'Read', 'AppendTo' 'Global'
$roles['AACA Campus Records'] = @{ Description = 'For campus default teams only: lets a campus team own its students, enrollments, attendance and family-portal records.'; Matrix = $m }
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
        # Not added to the solution: every environment gets its roles from this script (shipping them duplicates them).
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

#region Campus teams --------------------------------------------------------------------
foreach ($c in $campuses) {
    $bu = (Invoke-Dv -Path "businessunits?`$select=businessunitid&`$filter=name eq '$($c.aaca_name.Replace("'", "''"))'").value | Select-Object -First 1
    if (-not $bu) { continue }
    $team = (Invoke-Dv -Path "teams?`$select=teamid&`$filter=isdefault eq true and _businessunitid_value eq $($bu.businessunitid)").value | Select-Object -First 1
    $r = (Invoke-Dv -Path "roles?`$select=roleid&`$filter=name eq 'AACA Campus Records' and _businessunitid_value eq $($bu.businessunitid)").value | Select-Object -First 1
    $has = @((Invoke-Dv -Path "teams($($team.teamid))/teamroles_association?`$select=roleid&`$filter=roleid eq $($r.roleid)").value).Count -gt 0
    if (-not $has) {
        Invoke-Dv -Method Post -Path "teams($($team.teamid))/teamroles_association/`$ref" -Body @{ '@odata.id' = "$script:DvApi/roles($($r.roleid))" } | Out-Null
        Write-Host "Campus team $($c.aaca_name): AACA Campus Records assigned" -ForegroundColor Green
    }
    # Flows (e.g. absence report intake) read this to give new campus records to the campus team.
    $cr = Invoke-Dv -Path "$(Get-DvEntitySet 'aaca_campus')($($c.aaca_campusid))?`$select=aaca_ownerteamid" -AllowNotFound
    if ($cr -and $cr.PSObject.Properties['aaca_ownerteamid'] -and $cr.aaca_ownerteamid -ne "$($team.teamid)") {
        Invoke-Dv -Method Patch -Path "$(Get-DvEntitySet 'aaca_campus')($($c.aaca_campusid))" -Body @{ aaca_ownerteamid = "$($team.teamid)" } | Out-Null
    }
}
#endregion

#region Column security -----------------------------------------------------------------
$secured = @()
foreach ($t in $schema.tables) {
    foreach ($c in $t.columns) { if ($c.PSObject.Properties['secured'] -and $c.secured) { $secured += [pscustomobject]@{ table = $t.logicalName; column = $c.logicalName } } }
}
foreach ($l in $schema.lookups) { if ($l.PSObject.Properties['secured'] -and $l.secured) { $secured += [pscustomobject]@{ table = $l.table; column = $l.logicalName } } }
# Only columns the environment actually secures can take permissions (the schema marks two lookups secured that
# Deploy-Schema never secured). Skip those with a warning rather than failing.
$secured = @(foreach ($s in $secured) {
    $isSec = (Invoke-Dv -Path "EntityDefinitions(LogicalName='$($s.table)')/Attributes(LogicalName='$($s.column)')?`$select=IsSecured").IsSecured
    if ($isSec) { $s } else { Write-Warning "$($s.table).$($s.column) is not column-secured in this environment; skipped." }
})

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
        # Not added to the solution (see roles above).
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
