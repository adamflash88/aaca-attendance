<#
.SYNOPSIS
    Makes each campus own its records, so campus-scoped roles (Teacher, Attendance Office: "Local" = their business
    unit) can see them: Attendance and Enrollments go to their Campus's business unit, Students to the campus of their
    latest enrollment. Owner = the campus business unit's default team. Re-runnable; only rows that need a change are
    updated.

.DESCRIPTION
    Records loaded by Import-AacaData.ps1 are created by the person running it (root business unit), which campus
    roles cannot read. Regional Center Only students (no enrollment) stay where they are: admins and finance see them.

.EXAMPLE
    ./Set-CampusOwnership.ps1 -EnvironmentUrl https://orgb7b2c7e7.crm.dynamics.com
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode

# Campus -> business unit -> default team
$campusTeam = @{}; $teamBu = @{}
foreach ($c in (Get-DvAll "$(Get-DvEntitySet 'aaca_campus')?`$select=aaca_campusid,aaca_name")) {
    $bu = (Invoke-Dv -Path "businessunits?`$select=businessunitid&`$filter=name eq '$($c.aaca_name.Replace("'", "''"))'").value | Select-Object -First 1
    if (-not $bu) { Write-Warning "No business unit for campus $($c.aaca_name) - run Deploy-Security.ps1"; continue }
    $team = (Invoke-Dv -Path "teams?`$select=teamid&`$filter=isdefault eq true and _businessunitid_value eq $($bu.businessunitid)").value | Select-Object -First 1
    $campusTeam[$c.aaca_campusid] = $team.teamid; $teamBu[$team.teamid] = $bu.businessunitid
    Write-Host "Campus $($c.aaca_name) -> team $($team.teamid)"
}

function Set-Owners([string] $table, $rows, [scriptblock] $teamFor) {
    $set = Get-DvEntitySet $table; $idCol = "${table}id"
    $targets = [System.Collections.Generic.List[object]]::new()
    foreach ($r in $rows) {
        $tid = & $teamFor $r
        if (-not $tid -or $r._owningbusinessunit_value -eq $teamBu[$tid]) { continue }
        $targets.Add([ordered]@{ '@odata.type' = "Microsoft.Dynamics.CRM.$table"; $idCol = $r.$idCol; 'ownerid@odata.bind' = "/teams($tid)" })
    }
    for ($i = 0; $i -lt $targets.Count; $i += 100) {
        $chunk = [System.Collections.Generic.List[object]]::new()
        foreach ($t in $targets[$i..([Math]::Min($i + 100, $targets.Count) - 1)]) { $chunk.Add($t) }
        for ($try = 1; ; $try++) {
            try { Invoke-Dv -Method Post -Path "$set/Microsoft.Dynamics.CRM.UpdateMultiple" -Body @{ Targets = $chunk } | Out-Null; break }
            catch { if ($try -ge 4) { throw }; Write-Warning "    retry $try after: $($_.Exception.Message)"; Start-Sleep -Seconds (10 * $try) }
        }
        Write-Host "    $table : $([Math]::Min($i + 100, $targets.Count)) / $($targets.Count)"
    }
    Write-Host "$table : $($targets.Count) of $(@($rows).Count) moved to their campus" -ForegroundColor Green
}

$enr = Get-DvAll "$(Get-DvEntitySet 'aaca_enrollment')?`$select=aaca_enrollmentid,_aaca_campus_value,_aaca_student_value,aaca_startdate,_owningbusinessunit_value"
Set-Owners 'aaca_enrollment' $enr { param($r) $campusTeam[$r._aaca_campus_value] }

$latest = @{}
foreach ($e in ($enr | Sort-Object aaca_startdate)) { if ($e._aaca_campus_value) { $latest[$e._aaca_student_value] = $e._aaca_campus_value } }
$stu = Get-DvAll "$(Get-DvEntitySet 'aaca_student')?`$select=aaca_studentid,_owningbusinessunit_value"
Set-Owners 'aaca_student' $stu { param($r) if ($latest.Contains($r.aaca_studentid)) { $campusTeam[$latest[$r.aaca_studentid]] } }

$att = Get-DvAll "$(Get-DvEntitySet 'aaca_attendance')?`$select=aaca_attendanceid,_aaca_campus_value,_owningbusinessunit_value"
Set-Owners 'aaca_attendance' $att { param($r) $campusTeam[$r._aaca_campus_value] }
