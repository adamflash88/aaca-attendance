<#
.SYNOPSIS
    Test helper: runs the "AACA - Absence Report Intake" child flow for one report and prints the child's response.

.DESCRIPTION
    The Power Automate API cannot pass inputs to a manual (Button) trigger, so this deploys a temporary harness flow
    "AACA - Absence Intake Test" (no inputs) that calls the child with -ReportId, runs it, reads the child's response,
    and deletes the harness again. Dev only.

.EXAMPLE
    ./Test-AbsenceIntake.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -EnvironmentId a4c9f4ce-b971-edf2-beba-e3c29552a316 -TokenEnvironmentUrl https://orgb7b2c7e7.crm.dynamics.com -ReportId 515
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $EnvironmentId,
    [Parameter(Mandatory)] [string] $TokenEnvironmentUrl,   # cached sign-in with a refresh token (for the Flow API)
    [Parameter(Mandatory)] [int] $ReportId,
    [switch] $Keep
)
. (Join-Path $PSScriptRoot '..\provisioning\DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -SolutionUniqueName 'AACAAttendance' | Out-Null
$childId = '6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e51'; $harnessId = '6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e59'

$definition = [ordered]@{
    properties = [ordered]@{
        connectionReferences = @{}
        definition = [ordered]@{
            '$schema' = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
            contentVersion = '1.0.0.0'
            parameters = @{ '$connections' = @{ defaultValue = @{}; type = 'Object' }; '$authentication' = @{ defaultValue = @{}; type = 'SecureObject' } }
            triggers = @{ manual = @{ type = 'Request'; kind = 'Button'; inputs = @{ schema = @{ type = 'object'; properties = @{}; required = @() } } } }
            actions = @{ Run_intake = @{ runAfter = @{}; type = 'Workflow'; inputs = @{ host = @{ workflowReferenceName = $childId }; body = @{ text = "$ReportId" } } } }
            outputs = @{}
        }
    }
    schemaVersion = '1.0.0.0'
}
$clientdata = $definition | ConvertTo-Json -Depth 50 -Compress
$existing = Invoke-Dv -Path "workflows($harnessId)?`$select=statecode" -AllowNotFound
if ($existing) {
    if ($existing.statecode -eq 1) { Invoke-Dv -Method Patch -Path "workflows($harnessId)" -Body @{ statecode = 0; statuscode = 1 } | Out-Null }
    Invoke-Dv -Method Patch -Path "workflows($harnessId)" -Body @{ clientdata = $clientdata } | Out-Null
} else {
    Invoke-Dv -Method Post -Path 'workflows' -Body ([ordered]@{ workflowid = $harnessId; name = 'AACA - Absence Intake Test'; category = 5; type = 1; primaryentity = 'none'; clientdata = $clientdata }) | Out-Null
    Add-DvSolutionComponent $harnessId 29
}
Invoke-Dv -Method Patch -Path "workflows($harnessId)" -Body @{ statecode = 1; statuscode = 2 } | Out-Null

$ft = & (Join-Path $PSScriptRoot '..\provisioning\Get-AacaApiToken.ps1') -EnvironmentUrl $TokenEnvironmentUrl -Scope 'https://service.flow.microsoft.com//.default' | Select-Object -Last 1
$h = @{ Authorization = "Bearer $ft" }
$base = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$EnvironmentId/flows"
$all = (Invoke-RestMethod -Uri "$base`?api-version=2016-11-01" -Headers $h).value
$harness = $all | Where-Object { $_.properties.displayName -eq 'AACA - Absence Intake Test' }
$child = $all | Where-Object { $_.properties.displayName -eq 'AACA - Absence Report Intake' }
$started = (Get-Date).ToUniversalTime()
Invoke-RestMethod -Method Post -Uri "$base/$($harness.name)/triggers/manual/run?api-version=2016-11-01" -Headers $h -ContentType 'application/json' -Body '{}' | Out-Null

$run = $null
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep -Seconds 5
    $run = (Invoke-RestMethod -Uri "$base/$($child.name)/runs?api-version=2016-11-01&`$top=1" -Headers $h).value | Select-Object -First 1
    if ($run -and [datetime]$run.properties.startTime -ge $started.AddSeconds(-30) -and $run.properties.status -ne 'Running') { break }
}
"child run: $($run.properties.status)"
$acts = (Invoke-RestMethod -Uri "$base/$($child.name)/runs/$($run.name)/actions?api-version=2016-11-01" -Headers $h).value
$resp = $acts | Where-Object name -eq 'Respond'
if ($resp -and $resp.properties.PSObject.Properties['inputsLink']) { "response: " + ((Invoke-RestMethod -Uri $resp.properties.inputsLink.uri).body | ConvertTo-Json -Compress) }
foreach ($a in ($acts | Where-Object { $_.properties.status -eq 'Failed' })) { "FAILED $($a.name): $($a.properties.error.code) $($a.properties.error.message)" }

if (-not $Keep) {
    Invoke-Dv -Method Patch -Path "workflows($harnessId)" -Body @{ statecode = 0; statuscode = 1 } | Out-Null
    Invoke-Dv -Method Delete -Path "workflows($harnessId)" | Out-Null
}
