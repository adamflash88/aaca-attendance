<#
.SYNOPSIS
    Loads the CodeMetro "student services" export (tab-separated) into Student Services (one RDS day-service row per
    CodeMetro row: aide, BII, transportation, HNS) and Districts of Record (who pays SAI school days). Re-runnable.

.DESCRIPTION
    Matching: Student ID = Student Key; Service Code (else Service Name) through Service Aliases; Funding Source
    through Funder Aliases (run provisioning/Seed-BillingReference.ps1 first). A funding source with no alias is created
    as a Private Pay funder (CodeMetro writes the payer's name there) and listed in the report for finance to check.

    Student Services: only School Day services other than SPED (SAI comes from attendance). Identical simultaneous rows
    are kept as separate grid rows (a 2:1 aide = two rows); each gets a Source Key (student|code|funder|start|end|n), so
    a re-import updates instead of duplicating. CodeMetro rows that are no longer in the file are reported, not deleted.

    District of Record: the funder of the student's Spec. Ed rows; when a student has none (e.g. Antelope Valley), the
    District-type funder of their other services. Two different districts with overlapping dates = not created, listed.

    The report (.md) is written next to the export, never into the repo (it names students).

.EXAMPLE
    ./Import-CodeMetroServices.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Path '...\codemetrostudentservices.txt'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $Path,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode
if ((Resolve-Path $Path).Path -like "$((Resolve-Path (Join-Path $PSScriptRoot '..')).Path)*") { throw 'Keep CodeMetro exports outside the repo.' }

function Normalize([string] $s) { ($s -replace '\s+', ' ').Trim().ToUpperInvariant() }
function D([string] $s) { if ($s.Trim()) { ([datetime]::ParseExact($s.Trim(), 'M/d/yyyy', $null)).ToString('yyyy-MM-dd') } }
$rows = @(Import-Csv -Path $Path -Delimiter "`t")
$report = [System.Collections.Generic.List[string]]::new()
function Note([string] $section, [string] $line) { $report.Add("$section`t$line") }

# Lookups ---------------------------------------------------------------------------------
$stuSet = Get-DvEntitySet 'aaca_student'; $svcSet = Get-DvEntitySet 'aaca_service'; $fSet = Get-DvEntitySet 'aaca_funder'
$students = @{}
foreach ($r in (Get-DvAll "${stuSet}?`$select=aaca_studentid,aaca_externalclientid,aaca_studenttype")) { if ($r.aaca_externalclientid) { $students[$r.aaca_externalclientid.ToUpperInvariant()] = $r } }
$services = @{}
foreach ($r in (Get-DvAll "${svcSet}?`$select=aaca_serviceid,aaca_servicecode,aaca_servicekind")) { $services[$r.aaca_serviceid] = $r }
$alias = @{}
foreach ($r in (Get-DvAll "$(Get-DvEntitySet 'aaca_servicealias')?`$select=aaca_name,aaca_aliastype,_aaca_service_value")) { $alias["$($r.aaca_aliastype)|$($r.aaca_name)"] = $r._aaca_service_value }
$funders = @{}
foreach ($r in (Get-DvAll "${fSet}?`$select=aaca_funderid,aaca_name,aaca_fundertype")) { $funders[$r.aaca_funderid] = $r }
$faSet = Get-DvEntitySet 'aaca_funderalias'
$fAlias = @{}
foreach ($r in (Get-DvAll "${faSet}?`$select=aaca_name,_aaca_funder_value")) { $fAlias[$r.aaca_name] = $r._aaca_funder_value }

$DISTRICT, $PRIVATE = 582100000, 582100002
$SCHOOLDAY, $RCONLY = 582100000, 582100001
function Get-Funder([string] $name) {
    $n = Normalize $name
    if (-not $n) { return $null }
    if ($fAlias.Contains($n)) { return $fAlias[$n] }
    # Unknown payer: CodeMetro writes a private payer's name here. Create it for finance to confirm.
    $abbr = ($name -replace '\s+', ' ').Trim()
    $f = New-DvRow $fSet @{ aaca_name = $abbr; aaca_fullname = $abbr; aaca_fundertype = $PRIVATE; aaca_active = $true }
    New-DvRow $faSet @{ aaca_name = $n; 'aaca_funder@odata.bind' = "/$fSet($($f.aaca_funderid))" } | Out-Null
    $funders[$f.aaca_funderid] = [pscustomobject]@{ aaca_funderid = $f.aaca_funderid; aaca_name = $abbr; aaca_fundertype = $PRIVATE }
    $fAlias[$n] = $f.aaca_funderid
    Note 'New funders created as Private Pay (check type and QuickBooks customer)' $abbr
    $f.aaca_funderid
}

# Resolve every row -------------------------------------------------------------------------
$resolved = [System.Collections.Generic.List[object]]::new()
$line = 1
foreach ($r in $rows) {
    $line++
    $key = "$($r.'Student ID')".Trim().ToUpperInvariant()
    $stu = $students[$key]
    if (-not $stu) { Note 'Rows skipped: Student ID not in the app' "line ${line}: '$key'"; continue }
    $sid = $alias["582100000|$(Normalize $r.'Service Code')"]
    if (-not $sid) { $sid = $alias["582100001|$(Normalize $r.'Service Name')"] }
    if (-not $sid) { Note 'Rows skipped: unknown service code/name (add a Service Alias)' "line ${line}: $key code '$($r.'Service Code')' name '$($r.'Service Name')'"; continue }
    $fid = Get-Funder $r.'Funding Source'
    if (-not $fid) { Note 'Rows skipped: no Funding Source' "line ${line}: $key $($r.'Service Code')"; continue }
    $start = D $r.'Service Start'; $end = D $r.'Service End'
    if (-not $start) { Note 'Rows skipped: no Service Start' "line ${line}: $key $($r.'Service Code')"; continue }
    $resolved.Add([pscustomobject]@{ Line = $line; Key = $key; Student = $stu; ServiceId = $sid; Code = $services[$sid].aaca_servicecode
        Kind = $services[$sid].aaca_servicekind; FunderId = $fid; Start = $start; End = $end
        Frequency = "$($r.Frequency)".Trim(); Minutes = "$($r.'Mins/Freq')".Trim(); Esy = ("$($r.ESY)".Trim() -eq 'Yes') })
}

# Student Services ------------------------------------------------------------------------
$ssSet = Get-DvEntitySet 'aaca_studentservice'
$existingSs = @{}
foreach ($r in (Get-DvAll "${ssSet}?`$select=aaca_studentserviceid,aaca_sourcekey&`$filter=aaca_source eq 582100000")) { if ($r.aaca_sourcekey) { $existingSs[$r.aaca_sourcekey] = $r } }
$seen = @{}; $made = 0; $kept = 0
$day = $resolved | Where-Object { $_.Kind -eq $SCHOOLDAY -and $_.Code -ne 'SPED' }
foreach ($g in ($day | Group-Object { "$($_.Key)|$($_.Code)|$($_.FunderId)|$($_.Start)|$($_.End)" })) {
    $n = 0
    foreach ($x in $g.Group) {
        $n++
        $srcKey = "$($g.Name)|$n"; $seen[$srcKey] = $true
        $label = "$($x.Key) - $($x.Code)$(if ($g.Count -gt 1) { " #$n" }) - $($funders[$x.FunderId].aaca_name)"
        $body = @{ aaca_name = $label; aaca_startdate = $x.Start; aaca_frequency = $x.Frequency; aaca_esy = $x.Esy; aaca_source = 582100000; aaca_sourcekey = $srcKey
                   'aaca_student@odata.bind' = "/$stuSet($($x.Student.aaca_studentid))"; 'aaca_service@odata.bind' = "/$svcSet($($x.ServiceId))"; 'aaca_funder@odata.bind' = "/$fSet($($x.FunderId))" }
        if ($x.End) { $body.aaca_enddate = $x.End }
        if ($x.Minutes -match '^\d+$') { $body.aaca_minutesperfrequency = [int]$x.Minutes }
        if ($existingSs.Contains($srcKey)) { $kept++ } else { New-DvRow $ssSet $body | Out-Null; $made++ }
    }
}
foreach ($k in $existingSs.Keys) { if (-not $seen.Contains($k)) { Note 'Student Services from an earlier import not in this file (left as they are)' $k } }
Write-Host "Student Services: $made created, $kept already present" -ForegroundColor Green

# Districts of Record ---------------------------------------------------------------------
$dSet = Get-DvEntitySet 'aaca_studentfunder'
$existingD = @{}
foreach ($r in (Get-DvAll "${dSet}?`$select=aaca_studentfunderid,_aaca_student_value,_aaca_funder_value&`$filter=aaca_source eq 582100000")) { $existingD["$($r._aaca_student_value)|$($r._aaca_funder_value)"] = $r }
$dMade = 0; $dUpd = 0
foreach ($g in ($resolved | Group-Object Key)) {
    $stu = $g.Group[0].Student
    if ($stu.aaca_studenttype -eq $RCONLY) { continue }
    $src = @($g.Group | Where-Object Code -eq 'SPED'); $how = 'Spec. Ed row'
    if (-not $src) { $src = @($g.Group | Where-Object { $funders[$_.FunderId].aaca_fundertype -eq $DISTRICT }); $how = 'inferred from district-funded services' }
    if (-not $src) { Note 'Students with no district of record (no Spec. Ed row and no district-funded service)' $g.Name; continue }
    $spans = @(foreach ($f in ($src | Group-Object FunderId)) {
        [pscustomobject]@{ FunderId = $f.Name; Start = @($f.Group.Start | Sort-Object)[0]; End = $(if ($f.Group | Where-Object { -not $_.End }) { $null } else { @($f.Group.End | Sort-Object)[-1] }) }
    })
    $overlap = $false
    foreach ($a in $spans) { foreach ($b in $spans) { if ($a.FunderId -ne $b.FunderId -and $a.Start -le ($b.End ?? '9999-12-31') -and $b.Start -le ($a.End ?? '9999-12-31')) { $overlap = $true } } }
    if ($overlap) { Note 'Students with two districts at the same time (set the district of record by hand)' "$($g.Name): $(($spans | ForEach-Object { $funders[$_.FunderId].aaca_name }) -join ', ') ($how)"; continue }
    if ($how -ne 'Spec. Ed row') { Note 'District of record inferred (no Spec. Ed row in CodeMetro)' "$($g.Name): $(($spans | ForEach-Object { $funders[$_.FunderId].aaca_name }) -join ', ')" }
    foreach ($s in $spans) {
        $body = @{ aaca_name = "$($g.Name) - $($funders[$s.FunderId].aaca_name)"; aaca_startdate = $s.Start; aaca_enddate = $s.End; aaca_source = 582100000; aaca_note = "From CodeMetro: $how" }
        $cur = $existingD["$($stu.aaca_studentid)|$($s.FunderId)"]
        if ($cur) { Invoke-Dv -Method Patch -Path "$dSet($($cur.aaca_studentfunderid))" -Body $body | Out-Null; $dUpd++ }
        else {
            $body['aaca_student@odata.bind'] = "/$stuSet($($stu.aaca_studentid))"; $body['aaca_funder@odata.bind'] = "/$fSet($($s.FunderId))"
            New-DvRow $dSet $body | Out-Null; $dMade++
        }
    }
}
Write-Host "Districts of Record: $dMade created, $dUpd updated" -ForegroundColor Green

# Report ------------------------------------------------------------------------------------
$out = [System.IO.Path]::ChangeExtension($Path, '.import-report.md')
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# CodeMetro student services import - $(Split-Path $Path -Leaf)"); $md.Add(''); $md.Add("Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm')"); $md.Add('')
$md.Add("- File rows: $($rows.Count); matched: $($resolved.Count); skipped: $($rows.Count - $resolved.Count)")
$md.Add("- Student Services created: $made (already present: $kept); Districts of Record created: $dMade, updated: $dUpd"); $md.Add('')
foreach ($sec in ($report | Group-Object { $_.Split("`t")[0] })) {
    $md.Add("## $($sec.Name) ($($sec.Count))"); $md.Add('')
    foreach ($l in ($sec.Group | Select-Object -Unique)) { $md.Add("- $($l.Split("`t", 2)[1])") }
    $md.Add('')
}
Set-Content -Path $out -Value $md -Encoding utf8
Write-Host "Report: $out"
foreach ($sec in ($report | Group-Object { $_.Split("`t")[0] })) { Write-Host "  $($sec.Name): $(@($sec.Group | Select-Object -Unique).Count)" -ForegroundColor Yellow }
