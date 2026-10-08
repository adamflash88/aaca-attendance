<#
.SYNOPSIS
    Creates or updates the three Absence Notice flows (flows/generated/notices/*.json, from build_notice_flows.py):
    Website Absence Intake, Absence Notice Alert, Absence Notice Processing. With -Activate, turns them on.

.DESCRIPTION
    Solution-aware; uses the solution's Dataverse and Teams connection references, so they need no
    per-flow connections. An existing flow is turned off before its definition is replaced. Run in an environment
    whose solution is unmanaged (Dev); Test/Prod receive the flows through the solution export.

.EXAMPLE
    ./Deploy-NoticeFlows.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com
    ./Deploy-NoticeFlows.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Activate
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [switch] $Activate,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')
$schema = Get-Content (Join-Path $PSScriptRoot '..\schema\tables.json') -Raw | ConvertFrom-Json
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode -SolutionUniqueName $schema.solution.uniqueName

$files = Get-ChildItem (Join-Path $PSScriptRoot 'generated/notices') -Filter '*.json' | Sort-Object Name
foreach ($f in $files) {
    $def = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $id = $def.workflowid
    $clientdata = $def.clientdata | ConvertTo-Json -Depth 100 -Compress
    $existing = Invoke-Dv -Path "workflows($id)?`$select=statecode" -AllowNotFound
    if ($existing) {
        if ($existing.statecode -eq 1) { Invoke-Dv -Method Patch -Path "workflows($id)" -Body @{ statecode = 0; statuscode = 1 } | Out-Null }
        Invoke-Dv -Method Patch -Path "workflows($id)" -Body @{ name = $def.name; clientdata = $clientdata } | Out-Null
        Write-Host "Updated  $($def.name)"
    } else {
        Invoke-Dv -Method Post -Path 'workflows' -Body ([ordered]@{
            workflowid = $id; name = $def.name; category = 5; type = 1; primaryentity = 'none'
            clientdata = $clientdata; description = 'Phase 2 absence notices (see flows/build_notice_flows.py and docs/app-builds/build-12-billing-phase2/plan.md).'
        }) | Out-Null
        Add-DvSolutionComponent $id 29
        Write-Host "Created  $($def.name)" -ForegroundColor Green
    }
}
if ($Activate) {
    foreach ($f in $files) {
        $def = Get-Content $f.FullName -Raw | ConvertFrom-Json
        Invoke-Dv -Method Patch -Path "workflows($($def.workflowid))" -Body @{ statecode = 1; statuscode = 2 } | Out-Null
        Write-Host "Turned on $($def.name)" -ForegroundColor Green
    }
}
