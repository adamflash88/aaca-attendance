<#
.SYNOPSIS
    Creates or updates the three Teams reminder flows (flows/generated/reminders/*.json, from build_reminder_flows.py)
    in the AACA Attendance solution, plus the Microsoft Teams connection reference they use (aaca_sharedteams_reminders).
    Before -Activate, bind that connection reference to a Teams connection (Solutions > AACA Attendance > Connection
    references). Spec: flows/Reminders.md.

.DESCRIPTION
    Solution-aware; uses the solution's Dataverse, SharePoint and Teams connection references, so they need no
    per-flow connections. An existing flow is turned off before its definition is replaced. Run in an environment
    whose solution is unmanaged (Dev); Test/Prod receive the flows through the solution export.

.EXAMPLE
    ./Deploy-ReminderFlows.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com
    ./Deploy-ReminderFlows.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Activate
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

# Teams connection reference (no connection yet: Adam binds it in the solution).
$connRef = 'aaca_sharedteams_reminders'
if (-not (Invoke-Dv -Path "connectionreferences?`$select=connectionreferenceid&`$filter=connectionreferencelogicalname eq '$connRef'").value) {
    Invoke-Dv -Method Post -Path 'connectionreferences' -InSolution -Body ([ordered]@{
        connectionreferencelogicalname = $connRef; connectionreferencedisplayname = 'AACA Teams (reminders)'
        connectorid = '/providers/Microsoft.PowerApps/apis/shared_teams' }) | Out-Null
    Write-Host "Created connection reference $connRef - bind it to a Teams connection before turning the flows on" -ForegroundColor Yellow
}

$files = Get-ChildItem (Join-Path $PSScriptRoot 'generated/reminders') -Filter '*.json' | Sort-Object Name
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
            clientdata = $clientdata; description = 'Teams reminder (see flows/Reminders.md).'
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
