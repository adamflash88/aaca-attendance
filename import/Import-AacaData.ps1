<#
.SYNOPSIS
    Loads a checked import plan (<workbook>.plan.json from import/aaca_import.py) into Dataverse.

.DESCRIPTION
    Order: reset (optional) -> campuses -> school years -> terms -> calendar exceptions -> staff -> students ->
    enrollments (+ Previous Enrollment links) -> attendance.

    -Reset deletes ALL rows from the AACA data tables (attendance, audit events, month locks, enrollments, students,
    terms, calendar exceptions, school years, staff, campuses) so the environment holds only the imported data.
    App Settings, Absence Reasons and Services are kept. Use it in Dev only.

    The signed-in user owns every imported row. The script refuses to run if the check report has blocking errors.

.EXAMPLE
    ./Import-AacaData.ps1 -EnvironmentUrl https://org.crm.dynamics.com -PlanPath "C:\...\AACA-Import-2026-09-29.plan.json" -Reset
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $PlanPath,
    [switch] $Reset,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')

$reportPath = [IO.Path]::ChangeExtension($PlanPath, $null).TrimEnd('.') -replace '\.plan$', ''
$reportPath = "$reportPath.report.md"
if (-not (Test-Path $reportPath)) { throw "Check report not found: $reportPath. Run import/aaca_import.py first." }
if ((Get-Content $reportPath -Raw) -notmatch 'No blocking errors') { throw 'The check report has blocking errors. Fix the workbook and re-run the check.' }
$plan = Get-Content $PlanPath -Raw | ConvertFrom-Json
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode

function Set-Of([string] $t) { Get-DvEntitySet $t }
function Bind([string] $t, $id) { "/$(Set-Of $t)($id)" }
function D($v) { if ($v -and "$v" -ne 'None') { ([datetime]"$v").ToString('yyyy-MM-dd') } }
$sw = [Diagnostics.Stopwatch]::StartNew()
function Step([string] $m) { Write-Host ("[{0:mm\:ss}] {1}" -f $sw.Elapsed, $m) -ForegroundColor Cyan }

# Bulk create; returns the new ids in input order.
function New-DvRows([string] $table, [System.Collections.Generic.List[object]] $targets, [int] $size = 500) {
    $ids = [System.Collections.Generic.List[guid]]::new()
    for ($i = 0; $i -lt $targets.Count; $i += $size) {
        $chunk = [System.Collections.Generic.List[object]]::new()
        foreach ($t in $targets[$i..([Math]::Min($i + $size, $targets.Count) - 1)]) { $t['@odata.type'] = "Microsoft.Dynamics.CRM.$table"; $chunk.Add($t) }
        $res = Invoke-Dv -Method Post -Path "$(Set-Of $table)/Microsoft.Dynamics.CRM.CreateMultiple" -Body @{ Targets = $chunk }
        foreach ($id in $res.Ids) { $ids.Add([guid]$id) }
        if ($targets.Count -gt $size) { Write-Host "    created $($ids.Count) / $($targets.Count)" }
    }
    return , $ids
}

#region Reset ---------------------------------------------------------------------------
if ($Reset) {
    Step 'Reset: deleting existing AACA data (Dev)'
    # Enrollment -> Enrollment links would block deletes (Restrict); clear them first.
    $enrSet = Set-Of 'aaca_enrollment'
    $linked = Get-DvAll "${enrSet}?`$select=aaca_enrollmentid&`$filter=_aaca_previousenrollment_value ne null"
    foreach ($e in $linked) { Invoke-Dv -Method Delete -Path "$enrSet($($e.aaca_enrollmentid))/aaca_previousenrollment/`$ref" -AllowNotFound | Out-Null }
    foreach ($t in 'aaca_attendance', 'aaca_auditevent', 'aaca_monthlock', 'aaca_enrollment', 'aaca_student', 'aaca_term',
                   'aaca_calendarexception', 'aaca_schoolyear', 'aaca_staff', 'aaca_campus') {
        $set = Set-Of $t
        $count = (Get-DvAll "${set}?`$select=$($t)id").Count
        Write-Host "  $t : $count rows"
        if ($count -gt 200) { Clear-DvTable $t }   # server-side BulkDelete job
        elseif ($count) { Remove-DvRows -Paths @((Get-DvAll "${set}?`$select=$($t)id") | ForEach-Object { "$set($($_."$($t)id"))" }) | Out-Null }
    }
}
#endregion

#region Reference data -----------------------------------------------------------------
Step 'Campuses'
$campusId = @{}
foreach ($c in $plan.campuses) {
    $r = Invoke-Dv -Method Patch -Path "$(Set-Of 'aaca_campus')(aaca_code='$($c.code)')" -Body @{ aaca_name = $c.name; aaca_active = $true } -ExtraHeaders @{ Prefer = 'return=representation' }
    $campusId[$c.code] = $r.aaca_campusid
}
$service = Invoke-Dv -Method Patch -Path "$(Set-Of 'aaca_service')(aaca_servicecode='$($plan.serviceCode)')" -Body @{ aaca_name = 'Special Education'; aaca_active = $true } -ExtraHeaders @{ Prefer = 'return=representation' }
$serviceId = $service.aaca_serviceid

Step 'Reference data (settings, absence reasons)'
# Rows every environment needs that are data, not solution components (see provisioning/reference-data.json).
$ref = Get-Content (Join-Path $PSScriptRoot '..\provisioning\reference-data.json') -Raw | ConvertFrom-Json
foreach ($st in $ref.settings) {
    Invoke-Dv -Method Patch -Path "$(Set-Of 'aaca_setting')(aaca_key='$($st.key)')" -Body @{ aaca_value = $st.value; aaca_description = $st.description } | Out-Null
}
$reasonSet = Set-Of 'aaca_absencereason'
$existingReasons = @(foreach ($r in (Get-DvAll "${reasonSet}?`$select=aaca_name")) { $r.aaca_name })
foreach ($ar in $ref.absenceReasons) {
    if ($existingReasons -notcontains $ar.name) {
        New-DvRow $reasonSet @{ aaca_name = $ar.name; aaca_active = [bool]$ar.active; aaca_sortorder = [int]$ar.sortOrder } | Out-Null
    }
}
Write-Host "  $(@($ref.settings).Count) settings, $(@($ref.absenceReasons).Count) absence reasons ensured"

Step 'School years'
$yearId = @{}
$today = [datetime]$plan.today
foreach ($y in $plan.schoolYears) {
    $status = if ([datetime]$y.end -lt $today) { 582100002 } elseif ([datetime]$y.start -gt $today) { 582100000 } else { 582100001 }
    $r = Invoke-Dv -Method Patch -Path "$(Set-Of 'aaca_schoolyear')(aaca_name='$($y.name)')" -Body @{ aaca_startdate = (D $y.start); aaca_enddate = (D $y.end); aaca_status = $status } -ExtraHeaders @{ Prefer = 'return=representation' }
    $yearId[$y.name] = $r.aaca_schoolyearid
}

Step "Terms ($($plan.terms.Count))"
$termId = @{}
$targets = [System.Collections.Generic.List[object]]::new()
foreach ($t in $plan.terms) {
    $row = @{ aaca_name = $t.name; aaca_term = [int]$t.termValue; aaca_startdate = (D $t.start); aaca_enddate = (D $t.end); 'aaca_schoolyear@odata.bind' = (Bind 'aaca_schoolyear' $yearId[$t.year]) }
    if ($t.campus) { $row['aaca_campus@odata.bind'] = Bind 'aaca_campus' $campusId[$t.campus] }
    $targets.Add($row)
}
$ids = New-DvRows 'aaca_term' $targets
for ($i = 0; $i -lt $plan.terms.Count; $i++) { $t = $plan.terms[$i]; $termId["$($t.year)|$($t.term)|$(if ($t.campus) { $t.campus } else { 'ALL' })"] = $ids[$i] }

Step "Calendar exceptions ($($plan.exceptions.Count))"
$targets = [System.Collections.Generic.List[object]]::new()
foreach ($e in $plan.exceptions) {
    $row = @{ aaca_name = $e.name; aaca_date = (D $e.date); aaca_type = [int]$e.type }
    if ($e.campus) { $row['aaca_campus@odata.bind'] = Bind 'aaca_campus' $campusId[$e.campus] }
    $targets.Add($row)
}
New-DvRows 'aaca_calendarexception' $targets | Out-Null
#endregion

#region People -------------------------------------------------------------------------
Step "Staff ($($plan.staff.Count))"
$staffId = @{}
$me = (Invoke-Dv -Path 'WhoAmI').UserId
$myEmail = (Invoke-Dv -Path "systemusers($me)?`$select=internalemailaddress").internalemailaddress.ToLower()
$linkedCount = 0
foreach ($s in $plan.staff) {
    $row = @{ aaca_name = $s.name; aaca_approle = [int]$s.role; aaca_active = $true }
    if ($s.campus) { $row['aaca_campus@odata.bind'] = Bind 'aaca_campus' $campusId[$s.campus] }
    if ($s.email) {
        $u = (Invoke-Dv -Path "systemusers?`$select=systemuserid&`$filter=internalemailaddress eq '$($s.email.Replace("'", "''"))' and isdisabled eq false").value | Select-Object -First 1
        if ($u) { $row['aaca_user@odata.bind'] = "/systemusers($($u.systemuserid))"; $linkedCount++ }
    }
    $staffId[$s.name] = (New-DvRow (Set-Of 'aaca_staff') $row).aaca_staffid
}
if (-not ($plan.staff | Where-Object { $_.email -eq $myEmail })) {
    # Keep the person running the import able to use the app.
    $u = Invoke-Dv -Path "systemusers($me)?`$select=fullname"
    New-DvRow (Set-Of 'aaca_staff') @{ aaca_name = $u.fullname; aaca_approle = 582100003; aaca_active = $true; 'aaca_user@odata.bind' = "/systemusers($me)" } | Out-Null
    Write-Host "  added $($u.fullname) as System Admin (not on the Staff sheet)"
}
Write-Host "  linked to user accounts: $linkedCount of $($plan.staff.Count) (others link when they are added to the environment)"

Step "Students ($($plan.students.Count))"
$targets = [System.Collections.Generic.List[object]]::new()
foreach ($s in $plan.students) {
    $row = @{ aaca_displayname = $s.display; aaca_firstname = $s.first; aaca_lastname = $s.last; aaca_externalclientid = $s.key; aaca_status = [int]$s.status }
    if ($s.PSObject.Properties['type']) { $row.aaca_studenttype = [int]$s.type }
    if ($s.dob -and "$($s.dob)" -ne 'None') { $row.aaca_dateofbirth = D $s.dob }
    if ($s.grade) { $row.aaca_grade = [int]$s.grade }
    if ($s.status -eq 582100002) { $row.aaca_archivedon = $today.ToString('yyyy-MM-dd'); $row['aaca_archivedby@odata.bind'] = "/systemusers($me)" }
    $targets.Add($row)
}
$ids = New-DvRows 'aaca_student' $targets
$studentId = @{}; $studentNumber = @{}
for ($i = 0; $i -lt $plan.students.Count; $i++) { $studentId[$plan.students[$i].key] = $ids[$i] }
foreach ($r in (Get-DvAll "$(Set-Of 'aaca_student')?`$select=aaca_studentid,aaca_studentnumber,aaca_externalclientid")) { $studentNumber[$r.aaca_externalclientid] = $r.aaca_studentnumber }
#endregion

#region Enrollments --------------------------------------------------------------------
Step "Enrollments ($($plan.enrollments.Count))"
$targets = [System.Collections.Generic.List[object]]::new()
foreach ($e in $plan.enrollments) {
    $row = @{
        aaca_name = "$($studentNumber[$e.key]) · $($plan.students | Where-Object key -eq $e.key | ForEach-Object last) · $($e.teacher)"
        aaca_program = [int]$e.program; aaca_iepratio = [int]$e.ratio; aaca_startdate = (D $e.start); aaca_status = [int]$e.status
        'aaca_student@odata.bind' = Bind 'aaca_student' $studentId[$e.key]; 'aaca_campus@odata.bind' = Bind 'aaca_campus' $campusId[$e.campus]
        'aaca_teacher@odata.bind' = Bind 'aaca_staff' $staffId[$e.teacher]; 'aaca_service@odata.bind' = Bind 'aaca_service' $serviceId
        'aaca_schoolyear@odata.bind' = Bind 'aaca_schoolyear' $yearId[$e.year]
    }
    if ($e.end -and "$($e.end)" -ne 'None') { $row.aaca_enddate = D $e.end }
    if ($null -ne $e.endReason) { $row.aaca_endreason = [int]$e.endReason }
    $targets.Add($row)
}
$enrIds = New-DvRows 'aaca_enrollment' $targets
$enrSet = Set-Of 'aaca_enrollment'
foreach ($e in $plan.enrollments | Where-Object { $null -ne $_.prev }) {
    Invoke-Dv -Method Patch -Path "$enrSet($($enrIds[[int]$e.id]))" -Body @{ 'aaca_previousenrollment@odata.bind' = "/$enrSet($($enrIds[[int]$e.prev]))" } | Out-Null
}
#endregion

#region Attendance ---------------------------------------------------------------------
Step "Attendance ($($plan.attendance.Count))"
$targets = [System.Collections.Generic.List[object]]::new()
foreach ($a in $plan.attendance) {
    $date = D $a.date
    $row = @{
        aaca_recordkey = "$(([datetime]$a.date).ToString('yyyyMMdd'))|$($studentNumber[$a.key])|$($plan.serviceCode)"
        aaca_date = $date; aaca_present = [bool]$a.present; aaca_isdeleted = $false
        'aaca_student@odata.bind' = Bind 'aaca_student' $studentId[$a.key]; 'aaca_service@odata.bind' = Bind 'aaca_service' $serviceId
        'aaca_teacher@odata.bind' = Bind 'aaca_staff' $staffId[$a.teacher]
    }
    if ($a.campus) { $row['aaca_campus@odata.bind'] = Bind 'aaca_campus' $campusId[$a.campus] }
    if ($a.year) { $row['aaca_schoolyear@odata.bind'] = Bind 'aaca_schoolyear' $yearId[$a.year] }
    if ($a.term -and $termId.Contains($a.term)) { $row['aaca_term@odata.bind'] = Bind 'aaca_term' $termId[$a.term] }
    if ($null -ne $a.segment) { $row['aaca_enrollment@odata.bind'] = Bind 'aaca_enrollment' $enrIds[[int]$a.segment] }
    if ($null -ne $a.ratio) { $row.aaca_iepratio = [int]$a.ratio }
    if ($null -ne $a.classification) { $row.aaca_classification = [int]$a.classification }
    if ($a.notes) { $row.aaca_notes = $a.notes }
    $targets.Add($row)
}
New-DvRows 'aaca_attendance' $targets | Out-Null
#endregion

#region Student Key counter -----------------------------------------------------------
# New students get "<campus code>-<Key Sequence>" from the app; the autonumber seed is per environment and does
# not travel with the solution, so set it just above the highest imported key number.
$maxKey = ($plan.students | ForEach-Object { if ($_.key -match '^[A-Z]{2,3}-(\d+)$') { [int]$Matches[1] } } | Measure-Object -Maximum).Maximum
if ($maxKey) {
    Invoke-Dv -Method Post -Path 'SetAutoNumberSeed' -Body @{ EntityName = 'aaca_student'; AttributeName = 'aaca_keysequence'; Value = [int]$maxKey + 1 } | Out-Null
    Write-Host "  Student Key counter set to start at $([int]$maxKey + 1)"
}
#endregion

Step 'Done'
$check = foreach ($t in 'aaca_campus', 'aaca_staff', 'aaca_student', 'aaca_enrollment', 'aaca_schoolyear', 'aaca_term', 'aaca_calendarexception', 'aaca_attendance') {
    [pscustomobject]@{ Table = $t; Rows = (Get-DvAll "$(Set-Of $t)?`$select=createdon").Count }
}
$check | Format-Table -AutoSize | Out-String | Write-Host
