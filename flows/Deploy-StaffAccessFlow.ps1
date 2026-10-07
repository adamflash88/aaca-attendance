<#
.SYNOPSIS
    Creates or updates the Staff Access Sync cloud flow (flows/generated/staff/*.json, from build_staff_access_flow.py)
    in the AACA Attendance solution. With -Activate, turns it on.

.DESCRIPTION
    Solution-aware; uses the solution's Dataverse connection reference, so they need no
    per-flow connections. An existing flow is turned off before its definition is replaced. Run in an environment
    whose solution is unmanaged (Dev); Test/Prod receive the flows through the solution export.

.EXAMPLE
    ./Deploy-StaffAccessFlow.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com
    ./Deploy-StaffAccessFlow.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Activate
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

$files = Get-ChildItem (Join-Path $PSScriptRoot 'generated\staff') -Filter '*.json' | Sort-Object Name
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
            clientdata = $clientdata; description = 'Every 15 min: links new Staff rows to their user account by email; new teachers get campus + AACA Teacher (see flows/build_staff_access_flow.py).'
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
