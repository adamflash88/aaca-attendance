<#
.SYNOPSIS
    Creates or updates the "AACA - Ask NEXUS" flow (flows/generated/help/*.json, from build_help_flow.py) used by the
    app's Help panel, plus its Microsoft Copilot Studio connection reference (aaca_sharedmicrosoftcopilotstudio_nexus).
    Bind that reference to a Copilot Studio connection (Default Solution > Connection references) before -Activate.

.DESCRIPTION
    Solution-aware; uses the solution's Copilot Studio connection reference (run as the calling user), so they need no
    per-flow connections. An existing flow is turned off before its definition is replaced. Run in an environment
    whose solution is unmanaged (Dev); Test/Prod receive the flows through the solution export.

.EXAMPLE
    ./Deploy-HelpFlow.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com
    ./Deploy-HelpFlow.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Activate
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

# Copilot Studio connection reference (no connection yet: Adam binds it).
$connRef = 'aaca_sharedmicrosoftcopilotstudio_nexus'
if (-not (Invoke-Dv -Path "connectionreferences?`$select=connectionreferenceid&`$filter=connectionreferencelogicalname eq '$connRef'").value) {
    Invoke-Dv -Method Post -Path 'connectionreferences' -InSolution -Body ([ordered]@{
        connectionreferencelogicalname = $connRef; connectionreferencedisplayname = 'AACA Copilot Studio (NEXUS help)'
        connectorid = '/providers/Microsoft.PowerApps/apis/shared_microsoftcopilotstudio' }) | Out-Null
    Write-Host "Created connection reference $connRef - bind it to a Copilot Studio connection before turning the flow on" -ForegroundColor Yellow
}

$files = Get-ChildItem (Join-Path $PSScriptRoot 'generated/help') -Filter '*.json' | Sort-Object Name
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
            clientdata = $clientdata; description = 'Help panel: asks the Resource Center agent (NEXUS) a question and returns the answer (flows/build_help_flow.py).'
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
