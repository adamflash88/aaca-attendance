<#
.SYNOPSIS
    Loads a CodeMetro "services rendered" export (tab-separated) into Service Deliveries (minutes per student + funder +
    service + day) and Upload Exceptions, recorded under one CodeMetro Upload row. Same rules the Billing app's upload
    will use (Phase 3); this script lets us load a file before that exists.

.DESCRIPTION
    Matching: Student ID = Student Key; CPT Code and Service Name through Service Aliases; Funding Source through Funder
    Aliases. Every row ends in exactly one place: summed onto a delivery, or an exception with a reason:
      Missing date · Unknown student · Unknown service · Code and name disagree · Unknown funder · Zero or negative minutes
    A Funding Source with no alias and Funding Source Type "Private Pay" creates a Private Pay funder (the payer's name).

    Re-upload rule: the file replaces every delivery dated between its first and last Appt Date, and earlier open
    exceptions in that range become Superseded, so loading the same or an overlapping file never double-counts.
    (Closed months arrive with the month-close phase; until then nothing is refused for being closed.)

    Tie-out (printed and stored on the upload): Rows In = Rows Matched + Rows in Exceptions.

.EXAMPLE
    ./Import-CodeMetroDeliveries.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Path '...\codemetrosample.txt'
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
function Bind([string] $t, $id) { "/$(Get-DvEntitySet $t)($id)" }
function New-DvRows([string] $table, [System.Collections.Generic.List[object]] $targets, [int] $size = 500) {
    $set = Get-DvEntitySet $table
    for ($i = 0; $i -lt $targets.Count; $i += $size) {
        $chunk = [System.Collections.Generic.List[object]]::new()
        foreach ($t in $targets[$i..([Math]::Min($i + $size, $targets.Count) - 1)]) { $t['@odata.type'] = "Microsoft.Dynamics.CRM.$table"; $chunk.Add($t) }
        Invoke-Dv -Method Post -Path "$set/Microsoft.Dynamics.CRM.CreateMultiple" -Body @{ Targets = $chunk } | Out-Null
    }
}
$FST = @{ 'DISTRICT' = 582100000; 'REGIONAL CENTER' = 582100001; 'PRIVATE PAY' = 582100002 }
$REASON = @{ 'Unknown student' = 582100000; 'Unknown service' = 582100001; 'Unknown funder' = 582100002; 'Missing date' = 582100003
             'Zero or negative minutes' = 582100004; 'Code and name disagree' = 582100005; 'Closed month' = 582100006; 'Other' = 582100007 }
$CPT, $NAME = 582100000, 582100001

# Lookups ---------------------------------------------------------------------------------
$students = @{}
foreach ($r in (Get-DvAll "$(Get-DvEntitySet 'aaca_student')?`$select=aaca_studentid,aaca_externalclientid")) { if ($r.aaca_externalclientid) { $students[$r.aaca_externalclientid.ToUpperInvariant()] = $r.aaca_studentid } }
$svcCode = @{}
foreach ($r in (Get-DvAll "$(Get-DvEntitySet 'aaca_service')?`$select=aaca_serviceid,aaca_servicecode")) { $svcCode[$r.aaca_serviceid] = $r.aaca_servicecode }
$alias = @{}
foreach ($r in (Get-DvAll "$(Get-DvEntitySet 'aaca_servicealias')?`$select=aaca_name,aaca_aliastype,_aaca_service_value")) { $alias["$($r.aaca_aliastype)|$($r.aaca_name)"] = $r._aaca_service_value }
$fSet = Get-DvEntitySet 'aaca_funder'; $faSet = Get-DvEntitySet 'aaca_funderalias'
$funderAbbr = @{}
foreach ($r in (Get-DvAll "${fSet}?`$select=aaca_funderid,aaca_name")) { $funderAbbr[$r.aaca_funderid] = $r.aaca_name }
$fAlias = @{}
foreach ($r in (Get-DvAll "${faSet}?`$select=aaca_name,_aaca_funder_value")) { $fAlias[$r.aaca_name] = $r._aaca_funder_value }
$newFunders = [System.Collections.Generic.List[string]]::new()

# Read + classify every row -----------------------------------------------------------------
$rows = @(Import-Csv -Path $Path -Delimiter "`t")
$agg = [ordered]@{}; $exceptions = [System.Collections.Generic.List[object]]::new()
$dates = [System.Collections.Generic.List[datetime]]::new()
$minutesIn = 0; $minutesMatched = 0; $line = 1
foreach ($r in $rows) {
    $line++
    $key = "$($r.'Student ID')".Trim().ToUpperInvariant()
    $mins = 0; [void][int]::TryParse("$($r.'Service Time')".Trim(), [ref]$mins); $minutesIn += $mins
    $date = $null; $d = [datetime]::MinValue
    if ([datetime]::TryParseExact("$($r.'Appt Date')".Trim(), 'M/d/yyyy', $null, 'None', [ref]$d)) { $date = $d; $dates.Add($d) }
    $why = $null; $sid = $null; $fid = $null
    if (-not $date) { $why = 'Missing date' }
    elseif (-not $students.Contains($key)) { $why = 'Unknown student' }
    else {
        $byCode = if ("$($r.'CPT Code')".Trim()) { $alias["$CPT|$(Normalize $r.'CPT Code')"] } else { $null }
        $byName = if ("$($r.'Service Name')".Trim()) { $alias["$NAME|$(Normalize $r.'Service Name')"] } else { $null }
        if ($byCode -and $byName -and $byCode -ne $byName) { $why = 'Code and name disagree' }
        else { $sid = $byCode ?? $byName; if (-not $sid) { $why = 'Unknown service' } }
    }
    if (-not $why) {
        $fn = Normalize $r.'Funding Source'
        $fid = $fAlias[$fn]
        if (-not $fid -and $fn -and (Normalize $r.'Funding Source Type') -eq 'PRIVATE PAY') {
            $abbr = ($r.'Funding Source' -replace '\s+', ' ').Trim()
            $f = New-DvRow $fSet @{ aaca_name = $abbr; aaca_fullname = $abbr; aaca_fundertype = 582100002; aaca_active = $true }
            New-DvRow $faSet @{ aaca_name = $fn; 'aaca_funder@odata.bind' = "/$fSet($($f.aaca_funderid))" } | Out-Null
            $fid = $f.aaca_funderid; $fAlias[$fn] = $fid; $funderAbbr[$fid] = $abbr; $newFunders.Add($abbr)
        }
        if (-not $fid) { $why = 'Unknown funder' }
        elseif ($mins -le 0) { $why = 'Zero or negative minutes' }
    }
    if ($why) {
        $ex = @{ aaca_name = "Line $line - $why"; aaca_line = $line; aaca_reason = $REASON[$why]; aaca_status = 582100000
                 aaca_studentkey = $key; aaca_clientname = "$($r.'Client Name')".Trim(); aaca_cptcode = "$($r.'CPT Code')".Trim()
                 aaca_servicename = "$($r.'Service Name')".Trim(); aaca_fundingsource = "$($r.'Funding Source')".Trim()
                 aaca_fundingsourcetype = "$($r.'Funding Source Type')".Trim(); aaca_minutes = $mins
                 aaca_raw = (($r.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' | ') }
        if ($date) { $ex.aaca_apptdate = $date.ToString('yyyy-MM-dd') }
        if ($students.Contains($key)) { $ex['aaca_student@odata.bind'] = Bind 'aaca_student' $students[$key] }
        $exceptions.Add($ex); continue
    }
    $dk = "$key|$($date.ToString('yyyy-MM-dd'))|$($svcCode[$sid])|$($funderAbbr[$fid])"
    if (-not $agg.Contains($dk)) { $agg[$dk] = [pscustomobject]@{ Key = $key; Date = $date; Sid = $sid; Fid = $fid; Minutes = 0; Sessions = 0; Fst = $FST[(Normalize $r.'Funding Source Type')] } }
    $agg[$dk].Minutes += $mins; $agg[$dk].Sessions++; $minutesMatched += $mins
}
if (-not $dates.Count) { throw 'No row has a readable Appt Date (expected M/D/YYYY).' }
$from = ($dates | Measure-Object -Minimum).Minimum.ToString('yyyy-MM-dd'); $to = ($dates | Measure-Object -Maximum).Maximum.ToString('yyyy-MM-dd')
$matched = [int](($agg.Values | Measure-Object Sessions -Sum).Sum)
Write-Host "File: $($rows.Count) rows, $from to $to; matched $matched rows -> $($agg.Count) daily totals; exceptions $($exceptions.Count)"

# Upload row, replace window, write -------------------------------------------------------
$upSet = Get-DvEntitySet 'aaca_codemetroupload'
$up = New-DvRow $upSet @{ aaca_name = (Split-Path $Path -Leaf); aaca_uploadedon = (Get-Date).ToUniversalTime().ToString('o'); aaca_datefrom = $from; aaca_dateto = $to
                         aaca_rowsin = $rows.Count; aaca_minutesin = $minutesIn; aaca_status = 582100000 }
$upId = $up.aaca_codemetrouploadid
$dSet = Get-DvEntitySet 'aaca_servicedelivery'
$old = Get-DvAll "${dSet}?`$select=aaca_servicedeliveryid&`$filter=aaca_date ge $from and aaca_date le $to"
if ($old.Count) { Remove-DvRows -Paths @(foreach ($o in $old) { "$dSet($($o.aaca_servicedeliveryid))" }) | Out-Null; Write-Host "Replaced $($old.Count) earlier daily totals in $from..$to" }
$eSet = Get-DvEntitySet 'aaca_uploadexception'
foreach ($e in (Get-DvAll "${eSet}?`$select=aaca_uploadexceptionid&`$filter=aaca_status eq 582100000 and aaca_apptdate ge $from and aaca_apptdate le $to")) {
    Invoke-Dv -Method Patch -Path "$eSet($($e.aaca_uploadexceptionid))" -Body @{ aaca_status = 582100003 } | Out-Null
}

# Earlier uploads wholly inside this window are replaced by this one.
foreach ($u in (Get-DvAll "${upSet}?`$select=aaca_codemetrouploadid&`$filter=aaca_codemetrouploadid ne $upId and aaca_datefrom ge $from and aaca_dateto le $to and aaca_status ne 582100003")) {
    Invoke-Dv -Method Patch -Path "$upSet($($u.aaca_codemetrouploadid))" -Body @{ aaca_status = 582100003 } | Out-Null
}

$targets = [System.Collections.Generic.List[object]]::new()
foreach ($a in $agg.Values) {
    $t = @{ aaca_name = "$($a.Key) $($a.Date.ToString('M/d')) $($svcCode[$a.Sid]) $($funderAbbr[$a.Fid])"; aaca_date = $a.Date.ToString('yyyy-MM-dd')
            aaca_minutes = $a.Minutes; aaca_sessions = $a.Sessions
            aaca_deliverykey = "$($a.Key)|$($a.Date.ToString('yyyy-MM-dd'))|$($svcCode[$a.Sid])|$($funderAbbr[$a.Fid])"
            'aaca_student@odata.bind' = Bind 'aaca_student' $students[$a.Key]; 'aaca_service@odata.bind' = Bind 'aaca_service' $a.Sid
            'aaca_funder@odata.bind' = Bind 'aaca_funder' $a.Fid; 'aaca_upload@odata.bind' = "/$upSet($upId)" }
    if ($a.Fst) { $t.aaca_fundingsourcetype = $a.Fst }
    $targets.Add($t)
}
New-DvRows 'aaca_servicedelivery' $targets
foreach ($e in $exceptions) { $e['aaca_upload@odata.bind'] = "/$upSet($upId)" }
if ($exceptions.Count) { New-DvRows 'aaca_uploadexception' $exceptions }

$tie = ($matched + $exceptions.Count) -eq $rows.Count
$note = "Tie-out: $($rows.Count) rows in = $matched matched + $($exceptions.Count) exceptions ($(if ($tie) {'OK'} else {'MISMATCH'})). Minutes in $minutesIn, matched $minutesMatched." +
        $(if ($newFunders.Count) { " New Private Pay funders: $($newFunders -join ', ')." } else { '' })
Invoke-Dv -Method Patch -Path "$upSet($upId)" -Body @{ aaca_rowsmatched = $matched; aaca_rowsexception = $exceptions.Count; aaca_minutesmatched = $minutesMatched
                                                     aaca_status = $(if ($tie) { 582100001 } else { 582100002 }); aaca_note = $note } | Out-Null
Write-Host $note -ForegroundColor $(if ($tie) { 'Green' } else { 'Red' })
foreach ($g in ($exceptions | Group-Object { $_.aaca_name -replace '^Line \d+ - ', '' })) { Write-Host "  exceptions - $($g.Name): $($g.Count)" -ForegroundColor Yellow }
