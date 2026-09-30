<#
.SYNOPSIS
    Generates FAKE development data for AACA Attendance: 3 campuses, teachers, students, the
    2025-2026 school year (Q1-Q4 + 29-day summer program) and 2026-2027 to date, with
    holidays, transfers, ratio changes, discharges, new admissions, absences (classified and
    unclassified), soft deletes and month locks.

.DESCRIPTION
    Never uses real data: names are drawn from generic lists; every seeded student has an
    External Client ID starting with SEED- and every seeded teacher's name starts with "Seed ".
    Deterministic for a given -RandomSeed. Refuses to run if seeded students already exist;
    use -Remove to delete all seed rows first (Dev environments only).

    Reference data (campuses, service, school years, terms, calendar, absence reasons, settings)
    is upserted, so it is safe to re-run.

.EXAMPLE
    ./New-SeedData.ps1 -EnvironmentUrl https://org12345.crm.dynamics.com
    ./New-SeedData.ps1 -EnvironmentUrl https://org12345.crm.dynamics.com -Remove
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [int] $RandomSeed = 20260928,
    [int] $TeachersPerCampus = 4,
    [int] $StudentsPerTeacher = 8,
    # Attendance is generated up to the day before this date (the matrix for "today" stays empty).
    [datetime] $AsOf = (Get-Date).Date,
    [switch] $Remove,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode

$rng = [Random]::new($RandomSeed)
function Chance([double] $p) { $rng.NextDouble() -lt $p }
function Pick($items) { $items[$rng.Next($items.Count)] }
function D([datetime] $d) { $d.ToString('yyyy-MM-dd') }
function Set-Of([string] $t) { Get-DvEntitySet $t }
function Bind([string] $t, $id) { "/$(Set-Of $t)($id)" }
$me = (Invoke-Dv -Path 'WhoAmI').UserId

# Choice values (see schema/tables.json)
$C = @{
    TermQ1 = 582100000; TermQ2 = 582100001; TermQ3 = 582100002; TermQ4 = 582100003; TermSummer = 582100004
    Holiday = 582100000; Break = 582100001; StaffDev = 582100002; Closure = 582100003
    ProgramRegular = 582100000; ProgramSummer = 582100001
    EnrPlanned = 582100000; EnrActive = 582100001; EnrEnded = 582100002
    EndTransfer = 582100000; EndRatio = 582100001; EndDischarge = 582100002; EndYear = 582100003
    StuActive = 582100000; StuInactive = 582100001
    Excused = 582100000; Unexcused = 582100001
    YearCurrent = 582100001; YearClosed = 582100002
    Locked = 582100000; AuditTransfer = 582100004; AuditSoftDelete = 582100002
    Teacher = 582100000
}
$ratios = @(@{ v = 582100000; w = 30 }, @{ v = 582100001; w = 40 }, @{ v = 582100002; w = 20 }, @{ v = 582100003; w = 7 }, @{ v = 582100004; w = 3 })
function Pick-Ratio { $r = $rng.Next(100); $acc = 0; foreach ($x in $ratios) { $acc += $x.w; if ($r -lt $acc) { return $x.v } } }

#region Remove ---------------------------------------------------------------------------
function Remove-SeedData {
    $stuSet = Set-Of 'aaca_student'
    $students = @((Invoke-Dv -Path "${stuSet}?`$select=aaca_studentid&`$filter=startswith(aaca_externalclientid,'SEED-')").value)
    Write-Host "Removing seed data for $($students.Count) students..."
    foreach ($table in 'aaca_attendance', 'aaca_enrollment') {
        $set = Set-Of $table
        foreach ($s in $students) {
            do {
                $rows = @((Invoke-Dv -Path "${set}?`$select=$($table)id&`$filter=_aaca_student_value eq $($s.aaca_studentid)&`$top=1000").value)
                # Enrollments reference each other (Previous Enrollment); clear the link before deleting.
                if ($table -eq 'aaca_enrollment') { foreach ($r in $rows) { Invoke-Dv -Method Delete -Path "$set($($r."$($table)id"))/aaca_previousenrollment/`$ref" -AllowNotFound | Out-Null } }
                foreach ($r in $rows) { Invoke-Dv -Method Delete -Path "$set($($r."$($table)id"))" | Out-Null }
            } while ($rows.Count -eq 1000)
        }
    }
    foreach ($s in $students) { Invoke-Dv -Method Delete -Path "$stuSet($($s.aaca_studentid))" | Out-Null }
    $audit = Set-Of 'aaca_auditevent'
    foreach ($a in (Invoke-Dv -Path "${audit}?`$select=aaca_auditeventid&`$filter=startswith(aaca_reason,'[seed]')").value) { Invoke-Dv -Method Delete -Path "$audit($($a.aaca_auditeventid))" | Out-Null }
    $staff = Set-Of 'aaca_staff'
    foreach ($t in (Invoke-Dv -Path "${staff}?`$select=aaca_staffid&`$filter=startswith(aaca_name,'Seed ')").value) { Invoke-Dv -Method Delete -Path "$staff($($t.aaca_staffid))" | Out-Null }
    Write-Host 'Seed students, enrollments, attendance, audit events and teachers removed. Reference data kept.' -ForegroundColor Green
}
if ($Remove) { Remove-SeedData; return }

$existing = (Invoke-Dv -Path "$(Set-Of 'aaca_student')?`$select=aaca_studentid&`$top=1&`$filter=startswith(aaca_externalclientid,'SEED-')").value
if ($existing) { throw 'Seed students already exist. Run with -Remove first to regenerate.' }
#endregion

#region Reference data (upsert) --------------------------------------------------------
function Upsert([string] $table, [string] $keyExpr, [hashtable] $body) {
    # PATCH on an alternate key creates the row if it doesn't exist.
    Invoke-Dv -Method Patch -Path "$(Set-Of $table)($keyExpr)" -Body $body -ExtraHeaders @{ Prefer = 'return=representation' }
}
function Find-Or-Create([string] $table, [string] $filter, [hashtable] $body) {
    $set = Set-Of $table
    $row = (Invoke-Dv -Path "${set}?`$filter=$filter").value | Select-Object -First 1
    if ($row) { return $row }
    New-DvRow $set $body
}

Write-Host 'Reference data...' -ForegroundColor Cyan
$campusDefs = @(@{ Code = 'ALP'; Name = 'Seed Campus Alpha' }, @{ Code = 'BET'; Name = 'Seed Campus Beta' }, @{ Code = 'GAM'; Name = 'Seed Campus Gamma' })
$campuses = foreach ($cd in $campusDefs) {
    $r = Upsert 'aaca_campus' "aaca_code='$($cd.Code)'" @{ aaca_name = $cd.Name; aaca_active = $true }
    [pscustomobject]@{ Id = $r.aaca_campusid; Code = $cd.Code; Name = $cd.Name }
}
$service = Upsert 'aaca_service' "aaca_servicecode='SPED'" @{ aaca_name = 'Special Education Attendance'; aaca_active = $true }
$serviceId = $service.aaca_serviceid

$settings = @{
    AllowFutureDates        = @('false', 'Allow attendance on future dates (true/false).')
    AbsenceAlertPerTerm     = @('5', 'Alert office staff when a student reaches this many absences in a term.')
    ConsecutiveAbsenceAlert = @('3', 'Alert office staff after this many consecutive absences.')
    UnclassifiedAgingDays   = @('5', 'Flag absences still unclassified after this many days.')
}
foreach ($k in $settings.Keys) { Upsert 'aaca_setting' "aaca_key='$k'" @{ aaca_value = $settings[$k][0]; aaca_description = $settings[$k][1] } | Out-Null }

$reasonIds = @{}
$order = 10
foreach ($rn in 'Illness', 'Medical/Therapy Appointment', 'Family Emergency', 'Religious Observance', 'Bereavement', 'Other') {
    $r = Find-Or-Create 'aaca_absencereason' "aaca_name eq '$($rn.Replace("'", "''"))'" @{ aaca_name = $rn; aaca_active = $true; aaca_sortorder = $order }
    $reasonIds[$rn] = $r.aaca_absencereasonid; $order += 10
}

# School years: regular year Aug-May + 29-day summer program (Mon-Fri) in Jun-Jul.
$yearDefs = @(
    @{ Name = '2025-2026'; Start = '2025-08-13'; End = '2026-07-31'; Status = $C.YearClosed
       Terms = @(@($C.TermQ1, 'Q1', '2025-08-13', '2025-10-10'), @($C.TermQ2, 'Q2', '2025-10-13', '2025-12-19'),
                 @($C.TermQ3, 'Q3', '2026-01-05', '2026-03-13'), @($C.TermQ4, 'Q4', '2026-03-16', '2026-05-22'),
                 @($C.TermSummer, 'Summer', '2026-06-15', '2026-07-27'))
       Holidays = @(@('2025-09-01', 'Labor Day', $C.Holiday), @('2025-11-11', 'Veterans Day', $C.Holiday),
                    @('2025-11-24', 'Thanksgiving Break', $C.Break), @('2025-11-25', 'Thanksgiving Break', $C.Break), @('2025-11-26', 'Thanksgiving Break', $C.Break),
                    @('2025-11-27', 'Thanksgiving', $C.Holiday), @('2025-11-28', 'Thanksgiving Break', $C.Break),
                    @('2026-01-19', 'Martin Luther King Jr. Day', $C.Holiday), @('2026-02-16', "Presidents' Day", $C.Holiday),
                    @('2026-03-30', 'Spring Break', $C.Break), @('2026-03-31', 'Spring Break', $C.Break), @('2026-04-01', 'Spring Break', $C.Break),
                    @('2026-04-02', 'Spring Break', $C.Break), @('2026-04-03', 'Spring Break', $C.Break),
                    @('2026-06-19', 'Juneteenth', $C.Holiday), @('2026-07-03', 'Independence Day (observed)', $C.Holiday))
       CampusDays = @(@('BET', '2026-01-26', 'Weather closure', $C.Closure), @('GAM', '2026-02-13', 'Staff development day', $C.StaffDev)) }
    @{ Name = '2026-2027'; Start = '2026-08-12'; End = '2027-07-30'; Status = $C.YearCurrent
       Terms = @(@($C.TermQ1, 'Q1', '2026-08-12', '2026-10-09'), @($C.TermQ2, 'Q2', '2026-10-12', '2026-12-18'),
                 @($C.TermQ3, 'Q3', '2027-01-04', '2027-03-12'), @($C.TermQ4, 'Q4', '2027-03-15', '2027-05-21'),
                 @($C.TermSummer, 'Summer', '2027-06-14', '2027-07-26'))
       Holidays = @(@('2026-09-07', 'Labor Day', $C.Holiday), @('2026-11-11', 'Veterans Day', $C.Holiday),
                    @('2026-11-23', 'Thanksgiving Break', $C.Break), @('2026-11-24', 'Thanksgiving Break', $C.Break), @('2026-11-25', 'Thanksgiving Break', $C.Break),
                    @('2026-11-26', 'Thanksgiving', $C.Holiday), @('2026-11-27', 'Thanksgiving Break', $C.Break),
                    @('2027-01-18', 'Martin Luther King Jr. Day', $C.Holiday), @('2027-02-15', "Presidents' Day", $C.Holiday),
                    @('2027-03-29', 'Spring Break', $C.Break), @('2027-03-30', 'Spring Break', $C.Break), @('2027-03-31', 'Spring Break', $C.Break),
                    @('2027-04-01', 'Spring Break', $C.Break), @('2027-04-02', 'Spring Break', $C.Break),
                    @('2027-06-18', 'Juneteenth (observed)', $C.Holiday), @('2027-07-05', 'Independence Day (observed)', $C.Holiday))
       # Leading comma keeps a one-item list of lists from being flattened by PowerShell.
       CampusDays = @(, @('ALP', '2026-09-18', 'Staff development day', $C.StaffDev)) }
)

$years = @{}
$exceptions = @{}   # campusCode|yyyy-MM-dd -> non-school; 'ALL|date' applies everywhere
foreach ($yd in $yearDefs) {
    $y = Upsert 'aaca_schoolyear' "aaca_name='$($yd.Name)'" @{ aaca_startdate = $yd.Start; aaca_enddate = $yd.End; aaca_status = $yd.Status }
    $termSet = Set-Of 'aaca_term'
    $terms = foreach ($t in $yd.Terms) {
        $row = Find-Or-Create 'aaca_term' "_aaca_schoolyear_value eq $($y.aaca_schoolyearid) and aaca_term eq $($t[0]) and _aaca_campus_value eq null" @{
            aaca_name = "$($yd.Name) $($t[1])"; aaca_term = $t[0]; aaca_startdate = $t[2]; aaca_enddate = $t[3]
            'aaca_schoolyear@odata.bind' = Bind 'aaca_schoolyear' $y.aaca_schoolyearid }
        [pscustomobject]@{ Id = $row.aaca_termid; Kind = $t[0]; Start = [datetime]$t[2]; End = [datetime]$t[3] }
    }
    foreach ($h in $yd.Holidays) {
        Find-Or-Create 'aaca_calendarexception' "aaca_date eq $($h[0]) and _aaca_campus_value eq null" @{ aaca_name = $h[1]; aaca_date = $h[0]; aaca_type = $h[2] } | Out-Null
        $exceptions["ALL|$($h[0])"] = $true
    }
    foreach ($cdy in $yd.CampusDays) {
        $camp = $campuses | Where-Object Code -eq $cdy[0]
        Find-Or-Create 'aaca_calendarexception' "aaca_date eq $($cdy[1]) and _aaca_campus_value eq $($camp.Id)" @{
            aaca_name = $cdy[2]; aaca_date = $cdy[1]; aaca_type = $cdy[3]; 'aaca_campus@odata.bind' = Bind 'aaca_campus' $camp.Id } | Out-Null
        $exceptions["$($cdy[0])|$($cdy[1])"] = $true
    }
    $years[$yd.Name] = [pscustomobject]@{ Id = $y.aaca_schoolyearid; Name = $yd.Name; Terms = @($terms) }
}

function Get-Term($year, [datetime] $d) { $year.Terms | Where-Object { $d -ge $_.Start -and $d -le $_.End } | Select-Object -First 1 }
function Test-SchoolDay($year, [string] $campusCode, [datetime] $d) {
    if ($d.DayOfWeek -in 'Saturday', 'Sunday') { return $false }
    if (-not (Get-Term $year $d)) { return $false }
    $k = D $d
    return -not ($exceptions["ALL|$k"] -or $exceptions["$campusCode|$k"])
}
$y1 = $years['2025-2026']; $y2 = $years['2026-2027']
$summerDays = @(for ($d = [datetime]'2026-06-15'; $d -le [datetime]'2026-07-27'; $d = $d.AddDays(1)) { if (Test-SchoolDay $y1 'ALP' $d) { $d } }).Count
Write-Host "  Summer 2026 program: $summerDays school days (target 29)"
#endregion

#region Teachers + students ------------------------------------------------------------
Write-Host 'Teachers and students...' -ForegroundColor Cyan
$teacherNames = 'Avery', 'Blake', 'Casey', 'Devon', 'Emerson', 'Finley', 'Harper', 'Jordan', 'Kendall', 'Logan', 'Morgan', 'Parker', 'Quinn', 'Reese', 'Sawyer'
$teachers = @()
$i = 0
foreach ($camp in $campuses) {
    for ($t = 0; $t -lt $TeachersPerCampus; $t++) {
        $name = "Seed $($teacherNames[$i % $teacherNames.Count]) $([char](65 + $i))"
        $row = Find-Or-Create 'aaca_staff' "aaca_name eq '$name'" @{
            aaca_name = $name; aaca_approle = $C.Teacher; aaca_active = $true; 'aaca_campus@odata.bind' = Bind 'aaca_campus' $camp.Id }
        $teachers += [pscustomobject]@{ Id = $row.aaca_staffid; Name = $name; Campus = $camp }
        $i++
    }
}

$first = 'Alex', 'Bailey', 'Cameron', 'Dakota', 'Eli', 'Frankie', 'Gray', 'Hayden', 'Indy', 'Jamie', 'Kai', 'Lane', 'Micah', 'Noel', 'Oakley',
         'Peyton', 'Remy', 'Riley', 'Rowan', 'Sage', 'Shay', 'Skyler', 'Tatum', 'Teagan', 'Val', 'Wren', 'Ari', 'Bryn', 'Charlie', 'Drew'
$last = 'Ashford', 'Brookline', 'Carver', 'Dalton', 'Easton', 'Fairbanks', 'Garnett', 'Holloway', 'Irving', 'Jessup', 'Kingsley', 'Lockhart',
        'Merrick', 'Northam', 'Oakes', 'Prescott', 'Quill', 'Radley', 'Stroud', 'Thorne', 'Upton', 'Vance', 'Whitlock', 'Yarrow'

$studentCount = $campuses.Count * $TeachersPerCampus * $StudentsPerTeacher
$newAdmits = [math]::Round($studentCount * 0.08)
$stuSet = Set-Of 'aaca_student'
$students = @()
$usedNames = @{}
for ($n = 0; $n -lt $studentCount + $newAdmits * 2; $n++) {
    do { $fn = Pick $first; $ln = Pick $last } while ($usedNames["$ln|$fn"])
    $usedNames["$ln|$fn"] = $true
    $grade = $rng.Next(14)   # 0 = K ... 12 = 12, 13 = 12+
    $age = 5 + $grade + $rng.Next(2)
    $dob = ([datetime]'2025-09-01').AddYears(-$age).AddDays(-$rng.Next(365))
    $students += [pscustomobject]@{ First = $fn; Last = $ln; Dob = $dob; Grade = $grade; Ext = ('SEED-{0:D4}' -f ($n + 1)); Id = $null; Number = $null }
}
# CreateMultiple in one call for students
$targets = [System.Collections.Generic.List[object]]::new()
foreach ($s in $students) {
    $targets.Add(@{ '@odata.type' = 'Microsoft.Dynamics.CRM.aaca_student'; aaca_displayname = "$($s.Last), $($s.First)"; aaca_firstname = $s.First
                    aaca_lastname = $s.Last; aaca_dateofbirth = (D $s.Dob); aaca_grade = 582100000 + [math]::Min($s.Grade, 13)
                    aaca_externalclientid = $s.Ext; aaca_status = $C.StuActive })
}
Invoke-Dv -Method Post -Path "$stuSet/Microsoft.Dynamics.CRM.CreateMultiple" -Body @{ Targets = $targets } | Out-Null
$created = (Invoke-Dv -Path "${stuSet}?`$select=aaca_studentid,aaca_studentnumber,aaca_externalclientid&`$filter=startswith(aaca_externalclientid,'SEED-')").value
$byExt = @{}; foreach ($r in $created) { $byExt[$r.aaca_externalclientid] = $r }
foreach ($s in $students) { $s.Id = $byExt[$s.Ext].aaca_studentid; $s.Number = $byExt[$s.Ext].aaca_studentnumber }
Write-Host "  $($teachers.Count) teachers, $($students.Count) students"
#endregion

#region Enrollment history -------------------------------------------------------------
# Each segment = one Enrollment row. Transfers/ratio changes close a segment and open the next.
Write-Host 'Enrollments...' -ForegroundColor Cyan
$segments = [System.Collections.Generic.List[object]]::new()
function Add-Segment($stu, $teacher, [int] $ratio, $year, [int] $program, [datetime] $start, $end, $endReason, $prev) {
    $seg = [pscustomobject]@{ Student = $stu; Teacher = $teacher; Ratio = $ratio; Year = $year; Program = $program; Start = $start
                              End = $end; EndReason = $endReason; Prev = $prev; Id = $null; Key = [guid]::NewGuid().ToString('N') }
    $segments.Add($seg); return $seg
}
function Next-SchoolDay($year, $code, [datetime] $d) { while (-not (Test-SchoolDay $year $code $d)) { $d = $d.AddDays(1) }; $d }

$y1Q4End = [datetime]'2026-05-22'; $y1Start = [datetime]'2025-08-13'
$pool = [System.Collections.Generic.Queue[object]]::new(); foreach ($s in $students) { $pool.Enqueue($s) }
$endOfYear1 = @{}   # student -> last regular segment (to continue into summer / next year)
$events = @()

foreach ($teacher in $teachers) {
    for ($k = 0; $k -lt $StudentsPerTeacher; $k++) {
        $stu = $pool.Dequeue()
        $seg = Add-Segment $stu $teacher (Pick-Ratio) $y1 $C.ProgramRegular $y1Start $null $null $null
        $roll = $rng.NextDouble()
        if ($roll -lt 0.08) {
            # Mid-year transfer: another teacher (30% of transfers go to another campus)
            $sameCampus = -not (Chance 0.3)
            $candidates = @($teachers | Where-Object { $_.Id -ne $teacher.Id -and (($_.Campus.Id -eq $teacher.Campus.Id) -eq $sameCampus) })
            $eff = Next-SchoolDay $y1 $teacher.Campus.Code ([datetime]'2025-09-15').AddDays($rng.Next(200))
            if ($eff -gt $y1Q4End.AddDays(-10)) { $eff = [datetime]'2026-02-02' }
            $seg.End = $eff.AddDays(-1); $seg.EndReason = $C.EndTransfer
            $to = Pick $candidates
            $seg = Add-Segment $stu $to $seg.Ratio $y1 $C.ProgramRegular $eff $null $null $seg
            $events += [pscustomobject]@{ Student = $stu; From = $teacher; To = $to; Date = $eff }
        } elseif ($roll -lt 0.13) {
            # IEP ratio change, same teacher
            $eff = Next-SchoolDay $y1 $teacher.Campus.Code ([datetime]'2025-10-01').AddDays($rng.Next(180))
            $seg.End = $eff.AddDays(-1); $seg.EndReason = $C.EndRatio
            do { $nr = Pick-Ratio } while ($nr -eq $seg.Ratio)
            $seg = Add-Segment $stu $teacher $nr $y1 $C.ProgramRegular $eff $null $null $seg
        } elseif ($roll -lt 0.16) {
            # Discharged mid-year
            $seg.End = Next-SchoolDay $y1 $teacher.Campus.Code ([datetime]'2025-11-01').AddDays($rng.Next(150)); $seg.EndReason = $C.EndDischarge
            $stu | Add-Member -NotePropertyName Discharged -NotePropertyValue $true
            continue
        }
        $seg.End = $y1Q4End; $seg.EndReason = $C.EndYear
        $endOfYear1[$stu.Ext] = $seg
    }
}
# Mid-year new admissions
for ($k = 0; $k -lt $newAdmits; $k++) {
    $stu = $pool.Dequeue(); $teacher = Pick $teachers
    $start = Next-SchoolDay $y1 $teacher.Campus.Code ([datetime]'2025-10-06').AddDays($rng.Next(150))
    $seg = Add-Segment $stu $teacher (Pick-Ratio) $y1 $C.ProgramRegular $start $y1Q4End $C.EndYear $null
    $endOfYear1[$stu.Ext] = $seg
}
# Summer 2026: ~85% of students active at the end of Q4 (own enrollment rows)
foreach ($seg in @($endOfYear1.Values)) {
    if (Chance 0.85) { Add-Segment $seg.Student $seg.Teacher $seg.Ratio $y1 $C.ProgramSummer ([datetime]'2026-06-15') ([datetime]'2026-07-27') $C.EndYear $null | Out-Null }
}
# 2026-2027 rollover: ~92% continue (grade +1), a few new students; current enrollments are open-ended
$y2Start = [datetime]'2026-08-12'
foreach ($seg in @($endOfYear1.Values)) {
    if (-not (Chance 0.92)) { continue }
    $teacher = if (Chance 0.2) { Pick @($teachers | Where-Object { $_.Campus.Id -eq $seg.Teacher.Campus.Id }) } else { $seg.Teacher }
    Add-Segment $seg.Student $teacher $seg.Ratio $y2 $C.ProgramRegular $y2Start $null $null $null | Out-Null
}
while ($pool.Count) {
    $stu = $pool.Dequeue(); $teacher = Pick $teachers
    Add-Segment $stu $teacher (Pick-Ratio) $y2 $C.ProgramRegular (Next-SchoolDay $y2 $teacher.Campus.Code ([datetime]'2026-08-24').AddDays($rng.Next(20))) $null $null $null | Out-Null
}
# One future-dated (Planned) transfer to exercise the transfer-activation flow
$futureSeg = $segments | Where-Object { $_.Year -eq $y2 -and -not $_.End } | Select-Object -First 1
if ($futureSeg) {
    $eff = Next-SchoolDay $y2 $futureSeg.Teacher.Campus.Code $AsOf.AddDays(14)
    $to = Pick @($teachers | Where-Object { $_.Campus.Id -eq $futureSeg.Teacher.Campus.Id -and $_.Id -ne $futureSeg.Teacher.Id })
    $futureSeg.End = $eff.AddDays(-1); $futureSeg.EndReason = $C.EndTransfer
    Add-Segment $futureSeg.Student $to $futureSeg.Ratio $y2 $C.ProgramRegular $eff $null $null $futureSeg | Out-Null
}

# Create enrollments year by year so Previous Enrollment can be bound to an existing id.
$enrSet = Set-Of 'aaca_enrollment'
$ordered = @($segments | Sort-Object { $_.Start })
$batch = [System.Collections.Generic.List[object]]::new()
function Flush-Enrollments {
    if (-not $batch.Count) { return }
    $res = Invoke-Dv -Method Post -Path "$enrSet/Microsoft.Dynamics.CRM.CreateMultiple" -Body @{ Targets = $batch }
    for ($j = 0; $j -lt $batch.Count; $j++) { $script:pending[$j].Id = $res.Ids[$j] }
    $batch.Clear(); $script:pending = @()
}
$script:pending = @()
foreach ($seg in $ordered) {
    if ($seg.Prev -and -not $seg.Prev.Id) { Flush-Enrollments }
    $status = if ($seg.Start -gt $AsOf) { $C.EnrPlanned } elseif ($seg.End -and $seg.End -lt $AsOf) { $C.EnrEnded } else { $C.EnrActive }
    $t = @{
        '@odata.type' = 'Microsoft.Dynamics.CRM.aaca_enrollment'
        aaca_name = "$($seg.Student.Number) · $($seg.Year.Name)$(if ($seg.Program -eq $C.ProgramSummer) { ' Summer' }) · $($seg.Student.Last)"
        aaca_program = $seg.Program; aaca_iepratio = $seg.Ratio; aaca_startdate = (D $seg.Start); aaca_status = $status
        'aaca_student@odata.bind' = Bind 'aaca_student' $seg.Student.Id; 'aaca_campus@odata.bind' = Bind 'aaca_campus' $seg.Teacher.Campus.Id
        'aaca_teacher@odata.bind' = Bind 'aaca_staff' $seg.Teacher.Id; 'aaca_service@odata.bind' = Bind 'aaca_service' $serviceId
        'aaca_schoolyear@odata.bind' = Bind 'aaca_schoolyear' $seg.Year.Id
    }
    if ($seg.End) { $t.aaca_enddate = D $seg.End }
    if ($seg.EndReason -and $status -ne $C.EnrActive) { $t.aaca_endreason = $seg.EndReason }
    if ($seg.EndReason -eq $C.EndTransfer -and $status -eq $C.EnrActive) { $t.aaca_endreason = $seg.EndReason }  # future-dated transfer already scheduled
    if ($seg.Prev) { $t['aaca_previousenrollment@odata.bind'] = Bind 'aaca_enrollment' $seg.Prev.Id }
    $batch.Add($t); $script:pending += $seg
    if ($batch.Count -ge 200) { Flush-Enrollments }
}
Flush-Enrollments
foreach ($s in $students | Where-Object { $_.PSObject.Properties['Discharged'] }) {
    if (-not ($segments | Where-Object { $_.Student -eq $s -and $_.Year -eq $y2 })) {
        Invoke-Dv -Method Patch -Path "$stuSet($($s.Id))" -Body @{ aaca_status = $C.StuInactive } | Out-Null
    }
}
Write-Host "  $($segments.Count) enrollment rows ($($events.Count) transfers)"
#endregion

#region Attendance ---------------------------------------------------------------------
Write-Host 'Attendance (this is the slow part)...' -ForegroundColor Cyan
$attSet = Set-Of 'aaca_attendance'
$reasonWeights = @('Illness', 'Illness', 'Illness', 'Medical/Therapy Appointment', 'Medical/Therapy Appointment', 'Family Emergency', 'Religious Observance', 'Other')
$rows = [System.Collections.Generic.List[object]]::new()
$total = 0; $absences = 0; $unclassified = 0
function Flush-Attendance {
    if (-not $rows.Count) { return }
    Invoke-Dv -Method Post -Path "$attSet/Microsoft.Dynamics.CRM.CreateMultiple" -Body @{ Targets = $rows } | Out-Null
    $script:total += $rows.Count; $rows.Clear()
    Write-Host "  ... $script:total rows"
}
$lastDay = $AsOf.AddDays(-1)
foreach ($seg in $segments) {
    $end = if ($seg.End -and $seg.End -lt $lastDay) { $seg.End } else { $lastDay }
    $sickStreak = 0
    $propensity = 0.03 + $rng.NextDouble() * 0.08   # per-student absence rate 3-11%
    for ($d = $seg.Start; $d -le $end; $d = $d.AddDays(1)) {
        if (-not (Test-SchoolDay $seg.Year $seg.Teacher.Campus.Code $d)) { continue }
        $term = Get-Term $seg.Year $d
        if (($seg.Program -eq $C.ProgramSummer) -ne ($term.Kind -eq $C.TermSummer)) { continue }
        if ($sickStreak -eq 0 -and (Chance ($propensity / 2))) { $sickStreak = 1 + $rng.Next(3) }
        $absent = $sickStreak -gt 0 -or (Chance ($propensity / 3))
        if ($sickStreak -gt 0) { $sickStreak-- }
        $r = @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.aaca_attendance'
            aaca_recordkey = "$($d.ToString('yyyyMMdd'))|$($seg.Student.Number)|SPED"
            aaca_date = (D $d); aaca_present = -not $absent; aaca_iepratio = $seg.Ratio; aaca_isdeleted = $false
            'aaca_student@odata.bind' = Bind 'aaca_student' $seg.Student.Id; 'aaca_service@odata.bind' = Bind 'aaca_service' $serviceId
            'aaca_enrollment@odata.bind' = Bind 'aaca_enrollment' $seg.Id; 'aaca_teacher@odata.bind' = Bind 'aaca_staff' $seg.Teacher.Id
            'aaca_campus@odata.bind' = Bind 'aaca_campus' $seg.Teacher.Campus.Id; 'aaca_schoolyear@odata.bind' = Bind 'aaca_schoolyear' $seg.Year.Id
            'aaca_term@odata.bind' = Bind 'aaca_term' $term.Id
        }
        if ($absent) {
            $absences++
            # Older absences are mostly classified; the last two weeks stay unclassified for the queue.
            if (($AsOf - $d).TotalDays -gt 14 -and -not (Chance 0.08)) {
                if (Chance 0.75) {
                    $r.aaca_classification = $C.Excused
                    $r['aaca_absencereason@odata.bind'] = Bind 'aaca_absencereason' $reasonIds[(Pick $reasonWeights)]
                } else { $r.aaca_classification = $C.Unexcused }
                $r.aaca_classifiedon = $d.AddDays(1 + $rng.Next(4)).AddHours(10).ToUniversalTime().ToString('o')
                $r['aaca_classifiedby@odata.bind'] = "/systemusers($me)"
            } else { $unclassified++ }
        }
        $rows.Add($r)
        if ($rows.Count -ge 500) { Flush-Attendance }
    }
}
Flush-Attendance

# A few soft-deleted records (a teacher cleared a cell) with matching audit events
$recent = (Invoke-Dv -Path "${attSet}?`$select=aaca_attendanceid,aaca_recordkey&`$filter=aaca_date ge $(D $AsOf.AddDays(-10))&`$top=3").value
$auditSet = Set-Of 'aaca_auditevent'
foreach ($a in $recent) {
    Invoke-Dv -Method Patch -Path "$attSet($($a.aaca_attendanceid))" -Body @{ aaca_isdeleted = $true } | Out-Null
    New-DvRow $auditSet @{ aaca_name = "Soft delete $($a.aaca_recordkey)"; aaca_action = $C.AuditSoftDelete; aaca_entity = 'aaca_attendance'
                           aaca_entityid = $a.aaca_attendanceid; aaca_before = '{"aaca_isdeleted":false}'; aaca_after = '{"aaca_isdeleted":true}'
                           aaca_reason = '[seed] Entered on wrong day' } | Out-Null
}
foreach ($e in $events) {
    New-DvRow $auditSet @{ aaca_name = "Transfer $($e.Student.Number): $($e.From.Name) -> $($e.To.Name)"; aaca_action = $C.AuditTransfer
                           aaca_entity = 'aaca_student'; aaca_entityid = $e.Student.Id; aaca_after = "{`"effective`":`"$(D $e.Date)`"}"
                           aaca_reason = '[seed] Classroom change' } | Out-Null
}
#endregion

#region Month locks --------------------------------------------------------------------
# Lock every month of 2025-2026 through June 2026 for every campus; July 2026 onward stays open.
foreach ($camp in $campuses) {
    for ($m = [datetime]'2025-08-01'; $m -le [datetime]'2026-06-01'; $m = $m.AddMonths(1)) {
        Find-Or-Create 'aaca_monthlock' "_aaca_campus_value eq $($camp.Id) and aaca_month eq $(D $m)" @{
            aaca_name = "$($camp.Code) $($m.ToString('yyyy-MM'))"; aaca_month = (D $m); aaca_status = $C.Locked
            'aaca_campus@odata.bind' = Bind 'aaca_campus' $camp.Id
            aaca_lockedon = $m.AddMonths(1).AddDays(6).ToUniversalTime().ToString('o'); aaca_reason = '[seed] Month-end close'
            'aaca_lockedby@odata.bind' = "/systemusers($me)" } | Out-Null
    }
}
#endregion

Write-Host "`nSeed complete: $($students.Count) students, $($segments.Count) enrollments, $total attendance rows, $absences absences ($unclassified unclassified)." -ForegroundColor Green
