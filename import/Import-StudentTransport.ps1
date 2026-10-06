<#
.SYNOPSIS
    Initial load of Student Transportation from the CodeMetro "student services" export (tab-separated): every student
    with TA or BII TA rows gets one Student Transportation row covering the span of those rows, usual pattern
    Round trip, Source = CodeMetro, owned by the campus of the student's latest enrollment. Re-runnable: students that
    already have a Student Transportation row are left alone (from now on the office manages transportation in the app).

.EXAMPLE
    ./Import-StudentTransport.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Path '...\codemetrostudentservices.txt'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $Path,
    [string[]] $ServiceCodes = @('TA', 'BII TA'),
    [switch] $WhatIf
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl
if ((Resolve-Path $Path).Path -like "$((Resolve-Path (Join-Path $PSScriptRoot '..')).Path)*") { throw 'Keep CodeMetro exports outside the repo.' }

$ROUND_TRIP, $SRC_CODEMETRO = 582100000, 582100000
function D([string] $s) { [datetime]::ParseExact($s.Trim(), 'M/d/yyyy', $null) }

$stuSet = Get-DvEntitySet 'aaca_student'; $cSet = Get-DvEntitySet 'aaca_campus'; $tSet = Get-DvEntitySet 'aaca_studenttransport'
$students = @{}
foreach ($r in (Get-DvAll "${stuSet}?`$select=aaca_studentid,aaca_externalclientid")) { if ($r.aaca_externalclientid) { $students[$r.aaca_externalclientid.ToUpperInvariant()] = $r.aaca_studentid } }
$campusTeam = @{}
foreach ($c in (Get-DvAll "${cSet}?`$select=aaca_campusid,aaca_ownerteamid")) { $campusTeam[$c.aaca_campusid] = $c.aaca_ownerteamid }
$latestCampus = @{}
foreach ($e in (Get-DvAll "$(Get-DvEntitySet 'aaca_enrollment')?`$select=_aaca_student_value,_aaca_campus_value,aaca_startdate&`$orderby=aaca_startdate asc")) {
    if ($e._aaca_campus_value) { $latestCampus[$e._aaca_student_value] = $e._aaca_campus_value }
}
$already = @{}
foreach ($r in (Get-DvAll "${tSet}?`$select=_aaca_student_value")) { $already[$r._aaca_student_value] = $true }

$rows = @(Import-Csv -Path $Path -Delimiter "`t" | Where-Object { $_.'Service Code'.Trim() -in $ServiceCodes })
$made = 0; $skipped = [System.Collections.Generic.List[string]]::new()
foreach ($g in ($rows | Group-Object { $_.'Student ID'.Trim().ToUpperInvariant() })) {
    $key = $g.Name; $sid = $students[$key]
    if (-not $sid) { $skipped.Add("$key (not in the app)"); continue }
    if ($already.Contains($sid)) { $skipped.Add("$key (already has transportation)"); continue }
    $start = @($g.Group | ForEach-Object { D $_.'Service Start' } | Sort-Object)[0]
    $ends = @($g.Group | ForEach-Object { if ($_.'Service End'.Trim()) { D $_.'Service End' } })
    $end = if ($ends.Count -eq $g.Count) { @($ends | Sort-Object)[-1] } else { $null }   # any open-ended row = ongoing
    $campus = $latestCampus[$sid]
    $body = @{ aaca_name = "$key - transportation"; aaca_startdate = $start.ToString('yyyy-MM-dd'); aaca_pattern = $ROUND_TRIP
               aaca_source = $SRC_CODEMETRO; aaca_note = "Initial load from CodeMetro ($(($g.Group.'Service Code' | Sort-Object -Unique) -join ', '))"
               'aaca_student@odata.bind' = "/$stuSet($sid)" }
    if ($end) { $body.aaca_enddate = $end.ToString('yyyy-MM-dd') }
    if ($campus) {
        $body['aaca_campus@odata.bind'] = "/$cSet($campus)"
        if ($campusTeam[$campus]) { $body['ownerid@odata.bind'] = "/teams($($campusTeam[$campus]))" }
    }
    if ($WhatIf) { Write-Host "would create: $key $($body.aaca_startdate) to $(if ($end) { $body.aaca_enddate } else { 'ongoing' })" }
    else { New-DvRow $tSet $body | Out-Null }
    $made++
}
Write-Host "Student Transportation: $made $(if ($WhatIf) { 'to create' } else { 'created' }); skipped $($skipped.Count)" -ForegroundColor Green
foreach ($s in $skipped) { Write-Host "  skipped $s" -ForegroundColor Yellow }
