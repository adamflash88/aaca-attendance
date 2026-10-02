<#
.SYNOPSIS
    Applies provisioning/billing-reference.json: services (with kind, billing unit, non-school-day and billable flags),
    CPT-code and service-name aliases, funders and their CodeMetro-name aliases. Re-runnable.

.DESCRIPTION
    Services are matched by Service Code and funders by Abbreviation. On an existing row only BLANK fields are filled,
    so changes finance makes in the Billing app (QuickBooks item, unit, flags) are never overwritten. Aliases are
    stored normalised (trimmed, single spaces, upper case) and re-pointed if they map elsewhere.

.EXAMPLE
    ./Seed-BillingReference.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode
$ref = Get-Content (Join-Path $PSScriptRoot 'billing-reference.json') -Raw | ConvertFrom-Json

function Normalize([string] $s) { ($s -replace '\s+', ' ').Trim().ToUpperInvariant() }
$kind = @{ 'School Day' = 582100000; 'Clinical' = 582100001 }
$unit = @{ 'Days' = 582100000; 'Hours' = 582100001 }
$fType = @{ 'District' = 582100000; 'Regional Center' = 582100001; 'Private Pay' = 582100002 }
$CPT, $NAME = 582100000, 582100001

# Upsert by a matching column; only blank fields are written on existing rows.
function Set-Row([string] $Set, [string] $IdCol, $Existing, [hashtable] $Body) {
    if (-not $Existing) { return (New-DvRow $Set $Body).$IdCol }
    $patch = @{}
    foreach ($k in $Body.Keys) {
        if ($k -like '*@odata.bind') { continue }
        $cur = $Existing.PSObject.Properties[$k]
        if (-not $cur -or $null -eq $cur.Value -or "$($cur.Value)" -eq '') { $patch[$k] = $Body[$k] }
    }
    if ($patch.Count) { Invoke-Dv -Method Patch -Path "$Set($($Existing.$IdCol))" -Body $patch | Out-Null }
    $Existing.$IdCol
}

#region Services + aliases --------------------------------------------------------------
$svcSet = Get-DvEntitySet 'aaca_service'
$existing = @{}
foreach ($r in (Get-DvAll "${svcSet}?`$select=aaca_serviceid,aaca_servicecode,aaca_name,aaca_servicekind,aaca_billingunit,aaca_billablenonschool,aaca_billable,aaca_sortorder,aaca_active")) { $existing[(Normalize $r.aaca_servicecode)] = $r }
$svcId = @{}
foreach ($s in $ref.services) {
    $body = @{ aaca_servicecode = $s.code; aaca_name = $s.name; aaca_servicekind = $kind[$s.kind]; aaca_billingunit = $unit[$s.unit]
               aaca_billablenonschool = [bool]$s.billableNonSchool; aaca_billable = [bool]$s.billable; aaca_sortorder = [int]$s.sortOrder; aaca_active = $true }
    $svcId[$s.code] = Set-Row $svcSet 'aaca_serviceid' $existing[(Normalize $s.code)] $body
}
# The existing SPED row predates the billing name: give it the SAI name once.
$sped = $existing['SPED']
if ($sped -and $sped.aaca_name -eq 'Special Education') { Invoke-Dv -Method Patch -Path "$svcSet($($sped.aaca_serviceid))" -Body @{ aaca_name = 'Special Education (SAI)' } | Out-Null }

$aliasSet = Get-DvEntitySet 'aaca_servicealias'
$aliases = @{}
foreach ($a in (Get-DvAll "${aliasSet}?`$select=aaca_servicealiasid,aaca_name,aaca_aliastype,_aaca_service_value")) { $aliases["$($a.aaca_aliastype)|$($a.aaca_name)"] = $a }
$made = 0
foreach ($s in $ref.services) {
    $pairs = @(foreach ($x in $s.cptAliases) { , @($CPT, $x) }) + @(foreach ($x in $s.nameAliases) { , @($NAME, $x) })
    foreach ($p in $pairs) {
        $n = Normalize $p[1]; $key = "$($p[0])|$n"; $sid = $svcId[$s.code]
        $cur = $aliases[$key]
        if (-not $cur) {
            New-DvRow $aliasSet @{ aaca_name = $n; aaca_aliastype = $p[0]; 'aaca_service@odata.bind' = "/$svcSet($sid)" } | Out-Null; $made++
        } elseif ($cur._aaca_service_value -ne $sid) {
            Invoke-Dv -Method Patch -Path "$aliasSet($($cur.aaca_servicealiasid))" -Body @{ 'aaca_service@odata.bind' = "/$svcSet($sid)" } | Out-Null
        }
    }
}
Write-Host "Services: $($ref.services.Count) ensured; service aliases created: $made" -ForegroundColor Green
#endregion

#region Funders + aliases ---------------------------------------------------------------
$fSet = Get-DvEntitySet 'aaca_funder'
$fExisting = @{}
foreach ($r in (Get-DvAll "${fSet}?`$select=aaca_funderid,aaca_name,aaca_fullname,aaca_fundertype,aaca_active")) { $fExisting[(Normalize $r.aaca_name)] = $r }
$faSet = Get-DvEntitySet 'aaca_funderalias'
$fAliases = @{}
foreach ($a in (Get-DvAll "${faSet}?`$select=aaca_funderaliasid,aaca_name,_aaca_funder_value")) { $fAliases[$a.aaca_name] = $a }
$made = 0
foreach ($f in $ref.funders) {
    $fid = Set-Row $fSet 'aaca_funderid' $fExisting[(Normalize $f.abbreviation)] @{ aaca_name = $f.abbreviation; aaca_fullname = $f.fullName; aaca_fundertype = $fType[$f.type]; aaca_active = $true }
    foreach ($x in $f.aliases) {
        $n = Normalize $x; $cur = $fAliases[$n]
        if (-not $cur) { New-DvRow $faSet @{ aaca_name = $n; 'aaca_funder@odata.bind' = "/$fSet($fid)" } | Out-Null; $made++ }
        elseif ($cur._aaca_funder_value -ne $fid) { Invoke-Dv -Method Patch -Path "$faSet($($cur.aaca_funderaliasid))" -Body @{ 'aaca_funder@odata.bind' = "/$fSet($fid)" } | Out-Null }
    }
}
Write-Host "Funders: $($ref.funders.Count) ensured; funder aliases created: $made" -ForegroundColor Green
#endregion
