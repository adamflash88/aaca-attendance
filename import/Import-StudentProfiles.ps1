<#
.SYNOPSIS
    Student profile CSV for the family portal: export a pre-filled template, then import what staff filled in.

.DESCRIPTION
    -Export writes one row per student (Student Key, name and campus pre-filled, as reference) with every profile
    column empty except values already in Dataverse. Fill it in with Excel and save as CSV (UTF-8).

    Import rules (one row = one student, matched by Student Key):
    - A blank cell leaves the current value unchanged. To clear a value, type  -  (a single hyphen).
    - Choice cells take the label shown in the app (e.g. "Triennial"); Yes/No cells take Yes or No; dates M/D/YYYY.
    - Case Manager = a Staff name; Enrollment Year = a School Year name (e.g. 2026-2027).
    - Emergency contacts (EC1-EC3) and medications (Med1-Med3): if ANY cell of the group is filled, the student's
      existing emergency contacts (or medications) are replaced by the ones in the row.
    - Guardians (G1, G2) are matched by email: an existing contact is reused (names/phone updated when given), otherwise
      a contact is created; the guardian link is created or updated. Guardians never lose access through this import.
    New rows are owned by the student's owner (the campus team), so campus office staff see them.

    -WhatIf validates everything and writes the report without changing Dataverse. The report (.md) is written next to
    the CSV; keep both outside the repo (they name students).

.EXAMPLE
    ./Import-StudentProfiles.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Path 'C:\...\data\student-profiles.csv' -Export
    ./Import-StudentProfiles.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Path 'C:\...\data\student-profiles.csv' -WhatIf
    ./Import-StudentProfiles.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Path 'C:\...\data\student-profiles.csv'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $Path,
    [switch] $Export,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fullPath = [IO.Path]::GetFullPath($Path)
if ($fullPath -like "$repoRoot*") { throw 'Keep student profile CSVs outside the repo (they name students).' }
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode

$schema = Get-Content (Join-Path $repoRoot 'schema\tables.json') -Raw | ConvertFrom-Json
$studentDef = $schema.tables | Where-Object logicalName -eq 'aaca_student'
function Get-Options([string] $col) { ($studentDef.columns | Where-Object logicalName -eq $col).options }

# CSV column -> student column, with its type ('text', 'memo', 'bool', 'date', 'choice').
$profileMap = [ordered]@{
    'Middle Name'                  = @('aaca_middlename', 'text')
    'Gender'                       = @('aaca_gender', 'choice')
    'Ethnicity'                    = @('aaca_ethnicity', 'choice')
    'Preferred Contact'            = @('aaca_preferredcontact', 'choice')
    'Address Type'                 = @('aaca_addresstype', 'choice')
    'Street'                       = @('aaca_street', 'text')
    'Unit'                         = @('aaca_unit', 'text')
    'City'                         = @('aaca_city', 'text')
    'State'                        = @('aaca_state', 'text')
    'ZIP'                          = @('aaca_zip', 'text')
    'Allergies'                    = @('aaca_allergies', 'memo')
    'Dietary Restrictions'         = @('aaca_dietaryrestrictions', 'memo')
    'Medical Release on File'      = @('aaca_medicalreleaseonfile', 'bool')
    'Next Grade'                   = @('aaca_nextgrade', 'choice')
    'IEP Type'                     = @('aaca_ieptype', 'choice')
    'IEP Date'                     = @('aaca_iepdate', 'date')
    'Enrollment Forms on File'     = @('aaca_enrollmentformsonfile', 'bool')
    'SPED Qualifier'               = @('aaca_spedqualifier', 'choice')
    'District Rep'                 = @('aaca_districtrepname', 'text')
    'CBI Release'                  = @('aaca_cbirelease', 'choice')
    'Media Release'                = @('aaca_mediarelease', 'choice')
    'Transportation'               = @('aaca_transportation', 'bool')
    'Transport Company'            = @('aaca_transportcompany', 'text')
    'Transport Phone'              = @('aaca_transportphone', 'text')
}
$refCols = 'Student Key', 'First Name', 'Last Name', 'Campus'
$lookupCols = 'Case Manager', 'Enrollment Year'
$ecCols = foreach ($i in 1..3) { "EC$i Name", "EC$i Relationship", "EC$i Phone" }
$medCols = foreach ($i in 1..3) { "Med$i Name", "Med$i Dosage", "Med$i Frequency" }
$gCols = foreach ($i in 1..2) { "G$i First Name", "G$i Last Name", "G$i Email", "G$i Phone", "G$i Relationship", "G$i Can Report Absences" }
$allCols = @($refCols) + @($profileMap.Keys) + @($lookupCols) + @($ecCols) + @($medCols) + @($gCols)
$relOptions = (($schema.tables | Where-Object logicalName -eq 'aaca_guardianlink').columns | Where-Object logicalName -eq 'aaca_relationship').options

$set = @{ student = Get-DvEntitySet 'aaca_student'; ec = Get-DvEntitySet 'aaca_emergencycontact'; med = Get-DvEntitySet 'aaca_studentmedication'
          link = Get-DvEntitySet 'aaca_guardianlink'; staff = Get-DvEntitySet 'aaca_staff'; year = Get-DvEntitySet 'aaca_schoolyear' }

function Get-All([string] $path) {
    $rows = [System.Collections.Generic.List[object]]::new()
    $page = Invoke-Dv -Path $path -ExtraHeaders @{ Prefer = 'odata.maxpagesize=5000' }
    while ($true) {
        foreach ($r in $page.value) { $rows.Add($r) }
        $next = $page.PSObject.Properties['@odata.nextLink']
        if (-not $next) { break }
        $page = Invoke-Dv -Path $next.Value -ExtraHeaders @{ Prefer = 'odata.maxpagesize=5000' }
    }
    return $rows
}

$studentSelect = 'aaca_studentid,aaca_externalclientid,aaca_firstname,aaca_lastname,_ownerid_value,_owningteam_value,_owninguser_value,_aaca_casemanager_value,_aaca_enrollmentyear_value,' +
    (@($profileMap.Values | ForEach-Object { $_[0] }) -join ',')
$students = Get-All "$($set.student)?`$select=$studentSelect&`$filter=aaca_externalclientid ne null"
$byKey = @{}; foreach ($s in $students) { $byKey[$s.aaca_externalclientid.Trim().ToUpperInvariant()] = $s }
$staff = Get-All "$($set.staff)?`$select=aaca_staffid,aaca_name"
$years = Get-All "$($set.year)?`$select=aaca_schoolyearid,aaca_name"

#region Export -------------------------------------------------------------------------------
if ($Export) {
    if (Test-Path $fullPath) { throw "$fullPath already exists; choose a new file name." }
    $enr = Get-All "$(Get-DvEntitySet 'aaca_enrollment')?`$select=_aaca_student_value,aaca_status,aaca_startdate&`$expand=aaca_campus(`$select=aaca_name)&`$orderby=aaca_startdate desc"
    # Campus = the active enrollment's campus, else the most recent enrollment's (rows are newest first).
    $campusOf = @{}
    foreach ($e in $enr) {
        $sid = $e._aaca_student_value
        if (-not $campusOf.Contains($sid) -or ($e.aaca_status -eq 582100001 -and -not $campusOf["active:$sid"])) {
            $campusOf[$sid] = $e.aaca_campus.aaca_name
            if ($e.aaca_status -eq 582100001) { $campusOf["active:$sid"] = $true }
        }
    }
    $label = { param($col, $v) if ($null -eq $v) { '' } else { ((Get-Options $col) | Where-Object { $_[0] -eq $v } | Select-Object -First 1)[1] } }
    $out = foreach ($s in ($students | Sort-Object { $campusOf[$_.aaca_studentid] }, aaca_lastname, aaca_firstname)) {
        $row = [ordered]@{}
        foreach ($c in $allCols) { $row[$c] = '' }
        $row['Student Key'] = $s.aaca_externalclientid; $row['First Name'] = $s.aaca_firstname; $row['Last Name'] = $s.aaca_lastname
        $row['Campus'] = $campusOf[$s.aaca_studentid]
        foreach ($k in $profileMap.Keys) {
            $col, $type = $profileMap[$k]; $v = $s.$col
            $row[$k] = switch ($type) {
                'choice' { & $label $col $v }
                'bool' { if ($null -eq $v) { '' } elseif ($v) { 'Yes' } else { 'No' } }
                'date' { if ($v) { ([datetime]$v).ToString('M/d/yyyy') } else { '' } }
                default { "$v" }
            }
        }
        $row['Case Manager'] = @($staff | Where-Object aaca_staffid -eq $s._aaca_casemanager_value | ForEach-Object aaca_name) -join ''
        $row['Enrollment Year'] = @($years | Where-Object aaca_schoolyearid -eq $s._aaca_enrollmentyear_value | ForEach-Object aaca_name) -join ''
        [pscustomobject]$row
    }
    $out | Export-Csv -Path $fullPath -NoTypeInformation -Encoding utf8 -WhatIf:$false
    Write-Host "Wrote $(@($out).Count) students to $fullPath" -ForegroundColor Green
    Write-Host 'Choice values:' -ForegroundColor Cyan
    foreach ($k in $profileMap.Keys) { if ($profileMap[$k][1] -eq 'choice') { Write-Host ("  {0,-18} {1}" -f $k, ((Get-Options $profileMap[$k][0] | ForEach-Object { $_[1] }) -join ' | ')) } }
    Write-Host ("  {0,-18} {1}" -f 'G Relationship', (($relOptions | ForEach-Object { $_[1] }) -join ' | '))
    return
}
#endregion

#region Import -------------------------------------------------------------------------------
$rows = @(Import-Csv -Path $fullPath)
$missingCols = @($allCols | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name })
if ($missingCols) { throw "CSV is missing columns: $($missingCols -join ', '). Start from -Export." }

$report = [System.Collections.Generic.List[string]]::new()
$errors = 0
function Fail([string] $line) { $script:errors++; $report.Add("- ERROR $line") }
function Cell($row, [string] $name) { "$($row.$name)".Trim() }
function Parse-Choice([object[]] $options, [string] $text) {
    foreach ($o in $options) { if ([string]$o[1] -ieq $text) { return [int]$o[0] } }
    return $null
}
function Parse-Date([string] $text) {
    foreach ($f in 'M/d/yyyy', 'yyyy-MM-dd', 'M/d/yy') {
        $d = [datetime]::MinValue
        if ([datetime]::TryParseExact($text, $f, [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$d)) { return $d.ToString('yyyy-MM-dd') }
    }
    return $null
}
function Owner-Bind($s) {
    if ($s._owningteam_value) { "/teams($($s._owningteam_value))" } else { "/systemusers($($s._owninguser_value))" }
}
$stats = [ordered]@{ students = 0; ec = 0; med = 0; contactsCreated = 0; linksCreated = 0; linksUpdated = 0 }

foreach ($row in $rows) {
    $key = (Cell $row 'Student Key').ToUpperInvariant()
    if (-not $key) { continue }
    try {
    $s = $byKey[$key]
    $who = "$key ($(Cell $row 'First Name') $(Cell $row 'Last Name'))"
    if (-not $s) { Fail "${who}: no student with this Student Key."; continue }

    # Profile columns
    $patch = @{}
    foreach ($k in $profileMap.Keys) {
        $text = Cell $row $k
        if (-not $text) { continue }
        $col, $type = $profileMap[$k]
        if ($text -eq '-') { $patch[$col] = $null; continue }
        switch ($type) {
            'choice' { $v = Parse-Choice (Get-Options $col) $text; if ($null -eq $v) { Fail "${who}: $k '$text' is not a valid choice." } else { $patch[$col] = $v } }
            'bool' { if ($text -match '^(yes|y|true)$') { $patch[$col] = $true } elseif ($text -match '^(no|n|false)$') { $patch[$col] = $false } else { Fail "${who}: $k must be Yes or No." } }
            'date' { $v = Parse-Date $text; if (-not $v) { Fail "${who}: $k '$text' is not a date (M/D/YYYY)." } else { $patch[$col] = $v } }
            default { $patch[$col] = $text }
        }
    }
    $cm = Cell $row 'Case Manager'
    if ($cm -eq '-') { $patch['aaca_casemanager@odata.bind'] = $null }
    elseif ($cm) { $m = @($staff | Where-Object { $_.aaca_name -ieq $cm }); if ($m.Count -ne 1) { Fail "${who}: Case Manager '$cm' matches $($m.Count) staff." } else { $patch['aaca_casemanager@odata.bind'] = "/$($set.staff)($($m[0].aaca_staffid))" } }
    $ey = Cell $row 'Enrollment Year'
    if ($ey -eq '-') { $patch['aaca_enrollmentyear@odata.bind'] = $null }
    elseif ($ey) { $m = @($years | Where-Object { $_.aaca_name -ieq $ey }); if ($m.Count -ne 1) { Fail "${who}: Enrollment Year '$ey' not found." } else { $patch['aaca_enrollmentyear@odata.bind'] = "/$($set.year)($($m[0].aaca_schoolyearid))" } }

    # Clearing a lookup is a DELETE on its reference, not a PATCH to null.
    $clearLookups = @($patch.Keys | Where-Object { $_ -like '*@odata.bind' -and $null -eq $patch[$_] })
    foreach ($c in $clearLookups) { $patch.Remove($c) }
    if (($patch.Count -or $clearLookups) -and $PSCmdlet.ShouldProcess($who, 'Update student profile')) {
        if ($patch.Count) { Invoke-Dv -Method Patch -Path "$($set.student)($($s.aaca_studentid))" -Body $patch | Out-Null }
        foreach ($c in $clearLookups) { Invoke-Dv -Method Delete -Path "$($set.student)($($s.aaca_studentid))/$($c.Split('@')[0])/`$ref" | Out-Null }
    }
    if ($patch.Count -or $clearLookups) { $stats.students++ }

    # Emergency contacts / medications: replace the group when any cell of it is filled.
    foreach ($grp in @(
        @{ name = 'EC'; set = $set.ec; id = 'aaca_emergencycontactid'; cols = { param($i) @{ aaca_name = (Cell $row "EC$i Name"); aaca_relationship = (Cell $row "EC$i Relationship"); aaca_phone = (Cell $row "EC$i Phone"); aaca_priority = $i } }; stat = 'ec'; required = 'aaca_phone' },
        @{ name = 'Med'; set = $set.med; id = 'aaca_studentmedicationid'; cols = { param($i) @{ aaca_name = (Cell $row "Med$i Name"); aaca_dosage = (Cell $row "Med$i Dosage"); aaca_frequency = (Cell $row "Med$i Frequency"); aaca_sortorder = $i } }; stat = 'med'; required = $null })) {
        $items = foreach ($i in 1..3) { $b = & $grp.cols $i; if ($b.Values | Where-Object { $_ -is [string] -and $_ }) { $b } }
        if (-not $items) { continue }
        $ok = $true
        foreach ($b in $items) {
            if (-not $b.aaca_name) { Fail "${who}: $($grp.name) entry #$(if ($b.aaca_priority) { $b.aaca_priority } else { $b.aaca_sortorder }) has no name."; $ok = $false }
            if ($grp.required -and -not $b[$grp.required]) { Fail "${who}: emergency contact '$($b.aaca_name)' has no phone."; $ok = $false }
        }
        if (-not $ok) { continue }
        if ($PSCmdlet.ShouldProcess($who, "Replace $($grp.name) entries")) {
            $old = Get-All "$($grp.set)?`$select=$($grp.id)&`$filter=_aaca_student_value eq $($s.aaca_studentid)"
            foreach ($o in $old) { Invoke-Dv -Method Delete -Path "$($grp.set)($($o.$($grp.id)))" | Out-Null }
            foreach ($b in $items) {
                $b['aaca_student@odata.bind'] = "/$($set.student)($($s.aaca_studentid))"
                $b['ownerid@odata.bind'] = Owner-Bind $s
                Invoke-Dv -Method Post -Path $grp.set -Body $b | Out-Null
            }
        }
        $stats[$grp.stat] += @($items).Count
    }

    # Guardians
    foreach ($i in 1..2) {
        $email = Cell $row "G$i Email"; $first = Cell $row "G$i First Name"; $last = Cell $row "G$i Last Name"
        $phone = Cell $row "G$i Phone"; $relText = Cell $row "G$i Relationship"; $canText = Cell $row "G$i Can Report Absences"
        if (-not ($email -or $first -or $last -or $phone)) { continue }
        if ($email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { Fail "${who}: guardian $i needs a valid email."; continue }
        $rel = if ($relText) { Parse-Choice $relOptions $relText } else { 582100000 }
        if ($null -eq $rel) { Fail "${who}: guardian $i relationship '$relText' is not valid."; continue }
        $can = if (-not $canText) { $true } elseif ($canText -match '^(yes|y|true)$') { $true } elseif ($canText -match '^(no|n|false)$') { $false } else { Fail "${who}: guardian $i Can Report Absences must be Yes or No."; continue }
        if (-not $PSCmdlet.ShouldProcess("$who guardian $email", 'Create or update guardian')) { continue }

        $escaped = $email.Replace("'", "''")
        $contact = (Invoke-Dv -Path "contacts?`$select=contactid,firstname,lastname&`$filter=emailaddress1 eq '$escaped'&`$top=2").value
        if (@($contact).Count -gt 1) { Fail "${who}: more than one contact has email $email; fix in Dataverse first."; continue }
        $cBody = @{}
        if ($first) { $cBody.firstname = $first }; if ($last) { $cBody.lastname = $last }; if ($phone) { $cBody.mobilephone = $phone }
        if ($contact) {
            $cid = $contact[0].contactid
            if ($cBody.Count) { Invoke-Dv -Method Patch -Path "contacts($cid)" -Body $cBody | Out-Null }
            $display = "$(if ($first) { $first } else { $contact[0].firstname }) $(if ($last) { $last } else { $contact[0].lastname })".Trim()
        } else {
            if (-not ($first -and $last)) { Fail "${who}: new guardian $email needs a first and last name."; continue }
            $cBody.emailaddress1 = $email
            $created = Invoke-Dv -Method Post -Path 'contacts' -Body $cBody -ExtraHeaders @{ Prefer = 'return=representation' }
            $cid = $created.contactid; $stats.contactsCreated++
            $display = "$first $last"
        }
        $link = (Invoke-Dv -Path "$($set.link)?`$select=aaca_guardianlinkid&`$filter=_aaca_contact_value eq $cid and _aaca_student_value eq $($s.aaca_studentid)").value | Select-Object -First 1
        $lBody = @{ aaca_name = $display; aaca_relationship = $rel; aaca_canreportabsences = $can; aaca_active = $true }
        if ($link) {
            Invoke-Dv -Method Patch -Path "$($set.link)($($link.aaca_guardianlinkid))" -Body $lBody | Out-Null; $stats.linksUpdated++
        } else {
            $lBody['aaca_contact@odata.bind'] = "/contacts($cid)"
            $lBody['aaca_student@odata.bind'] = "/$($set.student)($($s.aaca_studentid))"
            $lBody['ownerid@odata.bind'] = Owner-Bind $s
            Invoke-Dv -Method Post -Path $set.link -Body $lBody | Out-Null; $stats.linksCreated++
        }
    }
    } catch { Fail "$(Cell $row 'Student Key'): Dataverse rejected a change, rest of the row skipped: $($_.Exception.Message -replace '\s+', ' ')" }
}
#endregion

$mode = if ($WhatIfPreference) { 'CHECK ONLY (no changes made)' } else { 'IMPORTED' }
$summary = @("# Student profile import - $mode", '', "File: $fullPath", "Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm')", '',
    "- Students with profile changes: $($stats.students)", "- Emergency contacts written: $($stats.ec)", "- Medications written: $($stats.med)",
    "- Guardian contacts created: $($stats.contactsCreated)", "- Guardian links created / updated: $($stats.linksCreated) / $($stats.linksUpdated)",
    "- Errors (rows or cells skipped): $errors", '')
$reportPath = [IO.Path]::ChangeExtension($fullPath, '.report.md')
($summary + $report) | Set-Content -Path $reportPath -Encoding utf8 -WhatIf:$false
$summary | ForEach-Object { Write-Host $_ }
if ($errors) { Write-Host "See $reportPath for the $errors error(s)." -ForegroundColor Yellow }
